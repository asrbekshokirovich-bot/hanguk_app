import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../domain/university.dart';
import 'university_roadview_screen.dart';

class UniversityDetailSheet extends StatelessWidget {
  final University university;

  const UniversityDetailSheet({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F213D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
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
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Logo + Name
                      Row(
                        children: [
                          _buildLogo(80),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  university.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Colors.white38,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      university.location,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (university.isPartner)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.vibrantLime.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.vibrantLime.withOpacity(0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        'Partner University',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.vibrantLime,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stats Row
                      _buildStatsRow(),

                      const SizedBox(height: 20),
                      const Divider(color: AppColors.borderGlass),
                      const SizedBox(height: 16),

                      // Tuition
                      if (university.tuitionMin != null ||
                          university.tuitionMax != null)
                        _buildInfoRow(
                          Icons.payments_outlined,
                          'Annual Tuition',
                          _formatTuition(),
                        ),

                      // Acceptance Rate
                      if (university.acceptanceRate != null)
                        _buildInfoRow(
                          Icons.how_to_reg_outlined,
                          'Acceptance Rate',
                          '${(university.acceptanceRate! * 100).toStringAsFixed(1)}%',
                        ),

                      // Description
                      if (university.descriptionEn != null &&
                          university.descriptionEn!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'About',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          university.descriptionEn!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Walkaround Campus Button
                      if (university.latitude != null && university.longitude != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UniversityRoadviewScreen(university: university),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.threesixty, size: 18, color: AppColors.pureBlack),
                              label: const Text(
                                'Virtual Walkaround',
                                style: TextStyle(color: AppColors.pureBlack, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.vibrantLime,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Visit Website Button
                      if (university.website != null &&
                          university.website!.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _launchWebsite(university.website!),
                            icon: const Icon(
                              Icons.open_in_browser_rounded,
                              size: 18,
                              color: AppColors.vibrantLime,
                            ),
                            label: const Text(
                              'Visit University Website',
                              style: TextStyle(color: AppColors.vibrantLime),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: AppColors.vibrantLime.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo(double size) {
    if (university.logoUrl != null && university.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          university.logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _fallbackIconBox(size),
        ),
      );
    }
    return _fallbackIconBox(size);
  }

  Widget _fallbackIconBox(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.vibrantLime.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.vibrantLime.withOpacity(0.2)),
      ),
      child: Icon(Icons.school_outlined, color: AppColors.vibrantLime, size: size * 0.45),
    );
  }

  Widget _buildStatsRow() {
    final items = <_StatItem>[];

    if (university.ranking != null) {
      items.add(_StatItem(
        label: 'Global Rank',
        value: '#${university.ranking}',
        highlight: university.ranking! <= 100,
      ));
    }
    if (university.localRank != null) {
      items.add(_StatItem(
        label: 'Korea Rank',
        value: '#${university.localRank}',
        highlight: university.localRank! <= 50,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: item.highlight
                      ? AppColors.vibrantLime.withOpacity(0.08)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.highlight
                        ? AppColors.vibrantLime.withOpacity(0.25)
                        : Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      item.value,
                      style: TextStyle(
                        color: item.highlight ? AppColors.vibrantLime : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTuition() {
    final min = university.tuitionMin;
    final max = university.tuitionMax;
    if (min != null && max != null) {
      return '\$${_fmt(min)} – \$${_fmt(max)} / yr';
    } else if (min != null) {
      return 'From \$${_fmt(min)} / yr';
    } else if (max != null) {
      return 'Up to \$${_fmt(max!)} / yr';
    }
    return 'Contact university';
  }

  String _fmt(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatItem {
  final String label;
  final String value;
  final bool highlight;

  _StatItem({required this.label, required this.value, this.highlight = false});
}
