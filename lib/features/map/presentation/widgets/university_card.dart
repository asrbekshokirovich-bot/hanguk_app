import 'package:flutter/material.dart';
import '../../../../design_system/theme/hanguk_ink.dart';
import '../../domain/university.dart';

class UniversityCard extends StatelessWidget {
  final University university;
  final VoidCallback? onTap;

  const UniversityCard({super.key, required this.university, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: HangukInk.paper.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HangukInk.ink.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: HangukInk.ink.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        university.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: HangukInk.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        university.location,
                        style: const TextStyle(
                          color: HangukInk.ink2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildTierBadge(),
                if (university.isPartner) ...[
                  const SizedBox(width: 6),
                  _buildPartnerChip(),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: HangukInk.ink.withValues(alpha: 0.25),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    if (university.logoUrl != null && university.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        // Decorative — the university name sits next to this logo.
        child: Image.network(
          university.logoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _loadingBox();
          },
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: HangukInk.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HangukInk.gold.withValues(alpha: 0.20)),
      ),
      child: const Icon(
        Icons.school_outlined,
        color: HangukInk.goldDeep,
        size: 24,
      ),
    );
  }

  // Low-contrast placeholder shown during slow logo loads (audit P1).
  Widget _loadingBox() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: HangukInk.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: HangukInk.ink.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }

  /// Audit M3 (2026-05-11): the legacy `_buildRankBadge` rendered
  /// `#${ranking}` from a column that no longer exists. Replaced with
  /// a tier-based "Top" pill: tier 0 (flagship) and tier 1 (top-ranked)
  /// get highlighted treatment; tier 2–4 show a dimmer "Tier N" label.
  /// Unclassified institutions (tier == null) render no badge.
  Widget _buildTierBadge() {
    final tier = university.tier;
    if (tier == null) return const SizedBox.shrink();

    final isTop = tier <= 1;
    final label = isTop ? 'Top' : 'Tier $tier';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isTop
            ? HangukInk.gold.withValues(alpha: 0.15)
            : HangukInk.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTop
              ? HangukInk.gold.withValues(alpha: 0.4)
              : HangukInk.ink.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isTop ? HangukInk.goldDeep : HangukInk.ink2,
        ),
      ),
    );
  }

  Widget _buildPartnerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: HangukInk.jade.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Partner',
        style: TextStyle(
          fontSize: 10,
          color: HangukInk.jadeDeep,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
