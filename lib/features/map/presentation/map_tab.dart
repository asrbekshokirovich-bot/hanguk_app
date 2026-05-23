import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../applications/presentation/widgets/selection_bar.dart';
import '../data/map_analytics.dart';
import '../data/map_repository.dart';
import '../domain/university.dart';
import 'map_deeplink_provider.dart';
import 'university_filters_provider.dart';
import 'widgets/university_card.dart';
import 'widgets/university_detail_sheet.dart';
import 'widgets/university_filters_sheet.dart';
import 'widgets/university_map_view.dart';

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isMapMode = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(universityFiltersProvider.notifier).setQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDetail(BuildContext ctx, University u) {
    // Audit M20 (2026-05-12): record the marker / row click. Sink is
    // overridable via the mapAnalyticsProvider.
    ref.read(mapAnalyticsProvider).mapMarkerClick(u.id);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UniversityDetailSheet(university: u),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uniAsync = ref.watch(universitiesProvider);
    final filters = ref.watch(universityFiltersProvider);

    // Audit M11 (2026-05-11): deep-link handler. When the router or a
    // push notification writes an institution id into
    // `pendingMapDetailProvider`, raise the detail sheet for that
    // institution and clear the provider so the sheet doesn't reopen
    // on rebuild.
    ref.listen<String?>(pendingMapDetailProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      final unis = uniAsync.valueOrNull;
      if (unis == null) return;
      final match = unis.where((u) => u.id == next).firstOrNull;
      ref.read(pendingMapDetailProvider.notifier).state = null;
      if (match == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showDetail(context, match);
      });
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // Search field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search universities or cities',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.07),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: filters.query.isNotEmpty
                            ? GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: const Icon(Icons.close, color: Colors.white38, size: 18),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FiltersButton(
                    activeCount: filters.activeCount,
                    onTap: () => UniversityFiltersSheet.show(context),
                  ),
                  const SizedBox(width: 8),
                  _ToggleButton(
                    isMapMode: _isMapMode,
                    onTap: () => setState(() => _isMapMode = !_isMapMode),
                  ),
                ],
              ),
            ),

            // ── Active filter pills ─────────────────────
            _ActiveFiltersBar(filters: filters),

            // ── Content ──────────────────────────────────
            Expanded(
              child: uniAsync.when(
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => _buildErrorState(),
                data: (unis) {
                  final filtered = applyUniversityFilters(unis, filters);
                  // Audit M25 (2026-05-12): when map mode is active and
                  // current filter/search produces 0 results, overlay an
                  // explanatory badge so the user knows the map looks
                  // empty because of their filter, not the data.
                  final showEmptyBadge = _isMapMode && filtered.isEmpty && unis.isNotEmpty;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _isMapMode
                        ? Stack(
                            key: const ValueKey('map'),
                            children: [
                              UniversityMapView(universities: filtered),
                              if (showEmptyBadge)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  right: 16,
                                  child: _FilterEmptyBadge(
                                    onClear: () {
                                      _searchController.clear();
                                      ref.read(universityFiltersProvider.notifier).clearAll();
                                    },
                                  ),
                                ),
                            ],
                          )
                        : _buildList(filtered, filters),
                  );
                },
              ),
            ),
            // Phase 1: persistent selection bar — picks made from the
            // detail sheet show up here instantly.
            const SelectionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<University> unis, UniversityFilters filters) {
    if (unis.isEmpty) {
      return _EmptyState(
        filters: filters,
        onClearQuery: () => _searchController.clear(),
        onClearAll: () {
          _searchController.clear();
          ref.read(universityFiltersProvider.notifier).clearAll();
        },
      );
    }

    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: unis.length,
      itemBuilder: (ctx, i) => UniversityCard(
        university: unis[i],
        onTap: () => _showDetail(ctx, unis[i]),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Could not load universities',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => ref.refresh(universitiesProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.vibrantLime),
            label: const Text('Retry', style: TextStyle(color: AppColors.vibrantLime)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.vibrantLime.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  final bool isMapMode;
  final VoidCallback onTap;

  const _ToggleButton({required this.isMapMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Audit M21 (2026-05-12): screen-reader label for the list/map
      // toggle. The icon is purely visual; without this Semantics
      // node the toggle is announced as an empty button.
      button: true,
      label: isMapMode ? 'Switch to list view' : 'Switch to map view',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMapMode
                ? AppColors.vibrantLime.withOpacity(0.15)
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMapMode
                  ? AppColors.vibrantLime.withOpacity(0.4)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Icon(
            isMapMode ? Icons.list_rounded : Icons.map_outlined,
            color: isMapMode ? AppColors.vibrantLime : Colors.white60,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FiltersButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasActive = activeCount > 0;
    return Semantics(
      button: true,
      label: hasActive ? 'Filters, $activeCount active' : 'Filters',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: hasActive
                ? AppColors.vibrantLime.withOpacity(0.15)
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActive
                  ? AppColors.vibrantLime.withOpacity(0.4)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune,
                size: 18,
                color: hasActive ? AppColors.vibrantLime : Colors.white60,
              ),
              if (hasActive) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.vibrantLime,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFiltersBar extends ConsumerWidget {
  final UniversityFilters filters;
  const _ActiveFiltersBar({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(universityFiltersProvider.notifier);
    final chips = <Widget>[];

    for (final r in filters.regions) {
      chips.add(_ActivePill(
        label: r.label,
        onClear: () => notifier.clearRegion(r),
      ));
    }
    if (filters.topTierOnly) {
      chips.add(_ActivePill(label: 'Top tier', onClear: () => notifier.setTopTier(false)));
    }
    if (filters.partnerOnly) {
      chips.add(_ActivePill(label: 'Partner', onClear: () => notifier.setPartner(false)));
    }
    if (filters.verifiedOnly) {
      chips.add(_ActivePill(label: 'Verified', onClear: () => notifier.setVerified(false)));
    }

    if (chips.isEmpty) return const SizedBox(height: 8);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _ActivePill({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppColors.vibrantLime.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.vibrantLime.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.vibrantLime,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            iconSize: 14,
            icon: const Icon(Icons.close, color: AppColors.vibrantLime),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final UniversityFilters filters;
  final VoidCallback onClearQuery;
  final VoidCallback onClearAll;

  const _EmptyState({
    required this.filters,
    required this.onClearQuery,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('empty'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              filters.query.isNotEmpty
                  ? 'No results for "${filters.query}"'
                  : 'No universities match these filters',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try loosening one of your filters:',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (filters.query.isNotEmpty)
              TextButton.icon(
                onPressed: onClearQuery,
                icon: const Icon(Icons.close, color: AppColors.vibrantLime, size: 16),
                label: const Text('Clear search', style: TextStyle(color: AppColors.vibrantLime)),
              ),
            if (filters.activeCount > 0)
              TextButton.icon(
                onPressed: onClearAll,
                icon: const Icon(Icons.refresh, color: AppColors.vibrantLime, size: 16),
                label: const Text('Reset all filters', style: TextStyle(color: AppColors.vibrantLime)),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterEmptyBadge extends StatelessWidget {
  final VoidCallback onClear;
  const _FilterEmptyBadge({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Audit M21 (2026-05-12): screen readers announce this badge
      // so non-sighted users know the map is empty because of an
      // active filter.
      liveRegion: true,
      label: 'No universities match the current filter',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list_off, color: AppColors.vibrantLime, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'No universities match — adjust your filters.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.vibrantLime,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
