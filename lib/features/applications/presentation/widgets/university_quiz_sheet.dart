import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../university_quiz_provider.dart';

/// Three-question preference quiz. Opens as a modal sheet from the
/// suggestions banner. Each answer updates state immediately so the
/// list re-ranks live; closing the sheet marks the prefs as answered
/// so we stop nagging the student.
class UniversityQuizSheet extends ConsumerStatefulWidget {
  const UniversityQuizSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UniversityQuizSheet(),
    );
  }

  @override
  ConsumerState<UniversityQuizSheet> createState() => _UniversityQuizSheetState();
}

class _UniversityQuizSheetState extends ConsumerState<UniversityQuizSheet> {
  int _step = 0;

  static const _regionOptions = [
    _Option('seoul', 'Seoul', Icons.location_city),
    _Option('busan', 'Busan', Icons.beach_access_outlined),
    _Option('gyeonggi', 'Gyeonggi / Incheon', Icons.directions_subway_outlined),
    _Option('other', 'Anywhere else', Icons.explore_outlined),
  ];

  static const _priorityOptions = [
    _Option('top', 'Top-tier universities', Icons.workspace_premium_outlined),
    _Option('partner', 'Partner universities', Icons.handshake_outlined),
    _Option('verified', 'Verified (IEQAS)', Icons.verified_outlined),
    _Option('', 'Show me everything', Icons.public),
  ];

  void _finishAndClose() {
    ref.read(universityQuizProvider.notifier).finish();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(universityQuizProvider);

    final isLast = _step == 2;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Step ${_step + 1} of 3',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finishAndClose,
                    child: const Text('Skip', style: TextStyle(color: Colors.white60)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: switch (_step) {
                  0 => _QuestionPanel(
                      title: 'Where would you like to study?',
                      subtitle: 'We\'ll surface universities in the region first.',
                      options: _regionOptions,
                      selected: prefs.region,
                      onSelect: (v) => ref.read(universityQuizProvider.notifier).setRegion(v),
                    ),
                  1 => _QuestionPanel(
                      title: 'What matters most to you?',
                      subtitle: 'We\'ll highlight matching universities.',
                      options: _priorityOptions,
                      selected: prefs.priority,
                      onSelect: (v) => ref.read(universityQuizProvider.notifier).setPriority(v),
                    ),
                  _ => const _ReviewPanel(),
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isLast ? _finishAndClose : () => setState(() => _step++),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.vibrantLime,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isLast ? 'See my picks' : 'Next',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option {
  final String value;
  final String label;
  final IconData icon;
  const _Option(this.value, this.label, this.icon);
}

class _QuestionPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_Option> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _QuestionPanel({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 18),
        ...options.map((opt) {
          final isSelected = selected == opt.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelect(opt.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.vibrantLime.withOpacity(0.12)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.vibrantLime
                        : Colors.white.withOpacity(0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(opt.icon, color: isSelected ? AppColors.vibrantLime : Colors.white60),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: AppColors.vibrantLime, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ReviewPanel extends ConsumerWidget {
  const _ReviewPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(universityQuizProvider);
    String regionLabel(String r) => switch (r) {
          'seoul' => 'Seoul',
          'busan' => 'Busan',
          'gyeonggi' => 'Gyeonggi / Incheon',
          'other' => 'Anywhere else',
          _ => 'No preference',
        };
    String priorityLabel(String p) => switch (p) {
          'top' => 'Top-tier universities',
          'partner' => 'Partner universities',
          'verified' => 'Verified (IEQAS)',
          _ => 'Show me everything',
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ready to see your matches?',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'We\'ll re-rank the list using these preferences. You can update them anytime.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 20),
        _SummaryRow(label: 'Region', value: regionLabel(prefs.region)),
        const SizedBox(height: 10),
        _SummaryRow(label: 'Priority', value: priorityLabel(prefs.priority)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
