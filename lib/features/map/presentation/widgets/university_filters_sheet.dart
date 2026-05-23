import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../data/map_repository.dart';
import '../../domain/university.dart';
import '../university_filters_provider.dart';

/// Bottom sheet that replaces the legacy 3-chip filter row. Lets the
/// student pick region(s) + quality signals + sort, and shows a live
/// count of matching universities so they understand what each toggle
/// does before applying it.
class UniversityFiltersSheet extends ConsumerWidget {
  const UniversityFiltersSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UniversityFiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(universityFiltersProvider);
    final notifier = ref.read(universityFiltersProvider.notifier);
    final unisAsync = ref.watch(universitiesProvider);

    // Live preview count — what would the user see if they applied this
    // filter set right now?
    final matchCount = unisAsync.maybeWhen(
      data: (unis) => applyUniversityFilters(unis, filters).length,
      orElse: () => null,
    );
    final totalCount = unisAsync.maybeWhen(
      data: (unis) => unis.length,
      orElse: () => null,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F213D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (filters.hasAnyActive)
                    TextButton.icon(
                      onPressed: notifier.clearAll,
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.white60),
                      label: const Text('Reset', style: TextStyle(color: Colors.white60)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  const _SectionLabel('Region'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: UniversityRegion.values.map((r) {
                      final selected = filters.regions.contains(r);
                      return _PillChip(
                        label: r.label,
                        selected: selected,
                        onTap: () => notifier.toggleRegion(r),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Quality'),
                  _ToggleRow(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Top tier only',
                    value: filters.topTierOnly,
                    onChanged: notifier.setTopTier,
                  ),
                  _ToggleRow(
                    icon: Icons.handshake_outlined,
                    label: 'Partner universities',
                    value: filters.partnerOnly,
                    onChanged: notifier.setPartner,
                  ),
                  _ToggleRow(
                    icon: Icons.verified_outlined,
                    label: 'Verified (IEQAS)',
                    value: filters.verifiedOnly,
                    onChanged: notifier.setVerified,
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Sort by'),
                  ...UniversitySort.values.map((s) {
                    final selected = filters.sort == s;
                    return RadioListTile<UniversitySort>(
                      value: s,
                      groupValue: filters.sort,
                      onChanged: (v) {
                        if (v != null) notifier.setSort(v);
                      },
                      activeColor: AppColors.vibrantLime,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        s.label,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vibrantLime,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      matchCount == null
                          ? 'Apply'
                          : matchCount == 0
                              ? 'No matches — adjust filters'
                              : (totalCount != null && matchCount == totalCount)
                                  ? 'Show all $matchCount universities'
                                  : 'Show $matchCount ${matchCount == 1 ? "university" : "universities"}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.vibrantLime.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.vibrantLime.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: AppColors.vibrantLime),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.vibrantLime : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: value ? AppColors.vibrantLime : Colors.white60, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: value ? Colors.white : Colors.white70,
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.vibrantLime,
            ),
          ],
        ),
      ),
    );
  }
}
