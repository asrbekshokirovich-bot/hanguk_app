import 'package:flutter/material.dart';
import '../../../design_system/adaptive/hanguk_scaffold.dart';
import '../../../design_system/theme/app_colors.dart';
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
                style: const TextStyle(
                  color: AppColors.vibrantLime,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderGlass),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    color: AppColors.borderGlass,
                    indent: 54,
                  ),
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
              style: const TextStyle(
                color: Colors.white38,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  uni.nameKo,
                  style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            size: 18,
            color: AppColors.vibrantLime,
          ),
        ],
      ),
    );
  }
}
