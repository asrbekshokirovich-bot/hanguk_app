import 'package:flutter/material.dart';
import '../../../design_system/adaptive/hanguk_scaffold.dart';
import '../../../design_system/theme/app_colors.dart';
import '../../../design_system/theme/theme_x.dart';
import '../domain/confirmed_universities.dart';

/// Read-only list of universities with approved admission data for the 2026
/// and 2027 intakes. Names mirror the `institutions` table exactly.
class ConfirmedUniversitiesScreen extends StatelessWidget {
  const ConfirmedUniversitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HangukScaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('Confirmed Universities'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: context.ink,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _YearSection(
            year: '2027',
            subtitle: '${ConfirmedUniversities.y2027.length} universities',
            items: ConfirmedUniversities.y2027,
          ),
          const SizedBox(height: 24),
          _YearSection(
            year: '2026',
            subtitle: '${ConfirmedUniversities.y2026.length} universities',
            items: ConfirmedUniversities.y2026,
          ),
        ],
      ),
    );
  }
}

class _YearSection extends StatelessWidget {
  final String year;
  final String subtitle;
  final List<ConfirmedUniversity> items;

  const _YearSection({
    required this.year,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.vibrantLime.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.vibrantLime.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                year,
                style: TextStyle(
                  color: context.accentText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              subtitle,
              style: TextStyle(color: context.onS(0.6), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.glassFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.hairline),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: context.hairline, indent: 54),
                _UniRow(index: i + 1, uni: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _UniRow extends StatelessWidget {
  final int index;
  final ConfirmedUniversity uni;

  const _UniRow({required this.index, required this.uni});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: TextStyle(
                color: context.onS(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uni.nameEn,
                  style: TextStyle(
                    color: context.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  uni.nameKo,
                  style: TextStyle(color: context.onS(0.55), fontSize: 12.5),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_rounded, size: 18, color: context.accentText),
        ],
      ),
    );
  }
}
