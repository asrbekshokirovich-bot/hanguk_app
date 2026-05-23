import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../map/domain/university.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/adaptive/hanguk_card.dart';
import '../applications_view_model.dart';
import '../university_draft_provider.dart';
import '../university_quiz_provider.dart';
import 'university_quiz_sheet.dart';

class UniversitySelectionView extends ConsumerWidget {
  final List<University> suggestions;
  final VoidCallback onSubmitted;

  const UniversitySelectionView({
    super.key,
    required this.suggestions,
    required this.onSubmitted,
  });

  void _toggleSelection(
    BuildContext context,
    WidgetRef ref,
    University uni,
    int remainingSlots,
  ) {
    final notifier = ref.read(universityDraftProvider.notifier);
    final draft = ref.read(universityDraftProvider);
    if (notifier.contains(uni.id)) {
      notifier.remove(uni.id);
      return;
    }
    if (draft.length >= remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remainingSlots == 0
                ? 'You\'ve reached the application limit. Remove an existing application first.'
                : 'You can pick up to $remainingSlots ${remainingSlots == 1 ? "university" : "universities"}.',
          ),
        ),
      );
      return;
    }
    notifier.add(uni, remainingSlots: remainingSlots);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(universityDraftProvider);
    final tabState = ref.watch(applicationsTabProvider);
    final remainingSlots = tabState.maybeWhen(
      data: (s) => s.remainingSlots,
      orElse: () => kMaxUniversityPicks,
    );
    final prefs = ref.watch(universityQuizProvider);

    final sortedSuggestions = _sortByQuizFit(suggestions, prefs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suggested for you',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                prefs.hasAnswered
                    ? 'Ranked using your preferences. Tap a card to add it to your list.'
                    : 'Tap a card to add it to your list. Pick up to 3.',
                style: const TextStyle(fontSize: 13, color: Colors.white60),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _QuizBanner(
            answered: prefs.hasAnswered,
            onTap: () => UniversityQuizSheet.show(context),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: sortedSuggestions.length,
          itemBuilder: (context, index) {
            final uni = sortedSuggestions[index];
            final isSelected = draft.any((u) => u.id == uni.id);
            final reasons = prefs.matchReasonsFor(uni);

            return GestureDetector(
              onTap: () => _toggleSelection(context, ref, uni, remainingSlots),
              child: HangukCard(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppColors.vibrantLime : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (uni.logoUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                uni.logoUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallbackLogo(),
                              ),
                            )
                          else
                            _fallbackLogo(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  uni.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  uni.location,
                                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(context, ref, uni, remainingSlots),
                            activeColor: AppColors.vibrantLime,
                            checkColor: Colors.black,
                            side: const BorderSide(color: Colors.white54),
                          ),
                        ],
                      ),
                      if (reasons.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: reasons
                              .map((r) => _WhyMatchChip(label: r))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static Widget _fallbackLogo() => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.vibrantLime.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.school_outlined, color: AppColors.vibrantLime),
      );

  /// Stable sort by number of quiz-match reasons (descending). Cards
  /// with no match-context preserve their server-provided order.
  List<University> _sortByQuizFit(List<University> input, QuizPreferences prefs) {
    if (!prefs.hasAnswered) return input;
    final indexed = input.asMap().entries.toList();
    indexed.sort((a, b) {
      final ra = prefs.matchReasonsFor(a.value).length;
      final rb = prefs.matchReasonsFor(b.value).length;
      if (ra != rb) return rb.compareTo(ra);
      return a.key.compareTo(b.key);
    });
    return indexed.map((e) => e.value).toList();
  }
}

class _WhyMatchChip extends StatelessWidget {
  final String label;
  const _WhyMatchChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.vibrantLime.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.vibrantLime.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 12, color: AppColors.vibrantLime),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.vibrantLime,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizBanner extends StatelessWidget {
  final bool answered;
  final VoidCallback onTap;

  const _QuizBanner({required this.answered, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.vibrantLime.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.vibrantLime.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.vibrantLime, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    answered ? 'Update your preferences' : 'Find your best fit in 30 seconds',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    answered ? 'We use them to rank suggestions.' : 'Answer 3 quick questions to personalize suggestions.',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
