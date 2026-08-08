import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../map/data/map_repository.dart';
import '../../map/domain/university.dart';
import '../domain/approved_uni_details.dart';

/// Guest Explorer ("Kashf etish") — browse Korean universities without a Magic
/// Code. Seoul Night theme: dark navy→black gradient, glass cards, lime accents.
/// Reachable at `/guest` (allowed for unauthenticated users).
class GuestExploreScreen extends ConsumerStatefulWidget {
  const GuestExploreScreen({super.key});

  @override
  ConsumerState<GuestExploreScreen> createState() => _GuestExploreScreenState();
}

class _GuestExploreScreenState extends ConsumerState<GuestExploreScreen> {
  static const _lime = Color(0xFFD4E94C);
  static const _ink = Color(0xFF0A1A34);

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _city = 'Hammasi';
  final Set<String> _compare = {}; // university ids, max 2
  final Set<String> _expanded = {}; // ids showing approved details

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleCompare(String id) {
    setState(() {
      if (_compare.contains(id)) {
        _compare.remove(id);
      } else {
        if (_compare.length >= 2) _compare.remove(_compare.first);
        _compare.add(id);
      }
    });
  }

  List<University> _filter(List<University> all) {
    return all.where((u) {
      if (_city != 'Hammasi' && u.location != _city) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.location.toLowerCase().contains(q) ||
          (u.nameKo?.contains(_query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uniAsync = ref.watch(universitiesProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -1),
            end: Alignment(0.8, 1),
            colors: [
              Color(0xFF1A3A6C),
              Color(0xFF132A4D),
              Color(0xFF0F213D),
              Color(0xFF0A0A1A),
            ],
            stops: [0.0, 0.38, 0.66, 1.0],
          ),
        ),
        child: SafeArea(
          child: uniAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: _lime),
            ),
            error: (e, _) => _error(),
            data: (unis) => _content(unis),
          ),
        ),
      ),
    );
  }

  Widget _error() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 44),
            const SizedBox(height: 14),
            Text(
              'Universitetlarni yuklab bo‘lmadi',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => ref.refresh(universitiesProvider),
              child: const Text('Qayta urinish',
                  style: TextStyle(color: _lime)),
            ),
          ],
        ),
      );

  Widget _content(List<University> unis) {
    final cities = <String>['Hammasi'];
    for (final u in unis) {
      if (u.location.isNotEmpty && !cities.contains(u.location)) {
        cities.add(u.location);
      }
    }
    final filtered = _filter(unis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
            children: [
              const Text(
                'Kashf etish',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    '나의 대학 찾기',
                    style: TextStyle(
                      color: _lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    '${unis.length} ta universitet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _searchField(),
              const SizedBox(height: 12),
              _cityChips(cities),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} ta natija',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_compare.length}/2 · Solishtirish',
                    style: const TextStyle(
                      color: _lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...filtered.map(_card),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Natija topilmadi',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/welcome'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A4E8C), Color(0xFF16305A)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              alignment: Alignment.center,
              child: const Text(
                '한',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mehmon rejimi · 탐색 모드',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Kashf etish',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/login', extra: {'magic_code': true}),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE2F26A), Color(0xFFC7E04A)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: const Row(
                children: [
                  Text(
                    "Bog'lanish",
                    style: TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('문의',
                      style: TextStyle(
                          color: _ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: _lime,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Qidirish...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityChips(List<String> cities) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cities.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Center(
              child: Text('도시',
                  style: TextStyle(
                      color: Color(0xB3D4E94C),
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            );
          }
          final city = cities[i - 1];
          final sel = _city == city;
          return GestureDetector(
            onTap: () => setState(() => _city = city),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? _lime : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: sel
                      ? _lime
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                city,
                style: TextStyle(
                  color: sel ? _ink : Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card(University u) {
    final selected = _compare.contains(u.id);
    final glyph = (u.nameKoShort ?? u.nameKo ?? u.name).characters.first;
    final detail = approvedUniDetails[u.id];
    final hasDetail = detail != null && detail.hasAny;
    final expanded = _expanded.contains(u.id);
    final metaParts = <String>[
      if (u.location.isNotEmpty) u.location,
      if (u.ranking != null) '#${u.ranking}',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hasDetail
            ? () => setState(() =>
                expanded ? _expanded.remove(u.id) : _expanded.add(u.id))
            : null,
        child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.14),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            alignment: Alignment.center,
            child: Text(
              glyph,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metaParts.join(' · '),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (u.isTopTier) _tag('outstanding'),
          const SizedBox(width: 8),
          _compareToggle(u.id, selected),
        ],
      ),
      ),
      if (hasDetail && !expanded)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.expand_more_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                "Kontrakt, muddat, talablar",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      if (hasDetail && expanded) _details(detail),
        ],
      ),
    );
  }

  Widget _details(ApprovedUniDetail d) {
    final rows = <Widget>[];
    if (d.tuitionMinKrw != null) {
      final v = d.tuitionMaxKrw != null && d.tuitionMaxKrw != d.tuitionMinKrw
          ? '${_krw(d.tuitionMinKrw!)}–${_krw(d.tuitionMaxKrw!)} ₩'
          : '${_krw(d.tuitionMinKrw!)} ₩';
      rows.add(_detailRow('Kontrakt narxi', '$v / semestr'));
    }
    if (d.appStart != null || d.appEnd != null) {
      rows.add(_detailRow(
        'Ariza topshirish',
        '${d.appStart ?? '—'} → ${d.appEnd ?? '—'}',
      ));
    }
    if (d.docDeadline != null) {
      rows.add(_detailRow('Hujjat muddati', d.docDeadline!));
    }
    final req = <String>[];
    if (d.topikMin != null) req.add('TOPIK ≥ ${d.topikMin}');
    if (d.englishAccepted == true) req.add('Ingliz tili qabul qilinadi');
    if (d.interviewRequired == true) req.add('Suhbat bor');
    if (d.interviewRequired == false) req.add('Suhbatsiz');
    if (req.isNotEmpty) {
      rows.add(_detailRow('Qabul talablari', req.join(' · ')));
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: rows),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFFD4E94C).withValues(alpha: 0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _krw(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF7CA3D9).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9FC0EA),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _compareToggle(String id, bool selected) {
    return GestureDetector(
      onTap: () => _toggleCompare(id),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected ? _lime : Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? _lime : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          selected ? Icons.check_rounded : Icons.add_rounded,
          size: 18,
          color: selected ? _ink : Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
