import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../chat/presentation/chat_tab.dart';
import '../../data/applications_repository.dart';
import '../applications_view_model.dart';
import '../university_draft_provider.dart';

/// Persistent bar shown at the bottom of any screen where the user
/// might pick universities (Map, Applications). Renders nothing when
/// the draft is empty so it doesn't take up space.
///
/// Phase 1 of the university-selection simplification: unifies the
/// Map tab's discovery flow with the Applications tab's selection
/// flow so the user always sees their current picks and a one-tap
/// path to submit.
class SelectionBar extends ConsumerStatefulWidget {
  const SelectionBar({super.key});

  @override
  ConsumerState<SelectionBar> createState() => _SelectionBarState();
}

class _SelectionBarState extends ConsumerState<SelectionBar> {
  bool _submitting = false;

  Future<void> _submit() async {
    final draft = ref.read(universityDraftProvider);
    if (draft.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await submitSelectedUniversities(draft.map((u) => u.id).toList());
      ref.read(universityDraftProvider.notifier).clear();
      ref.invalidate(applicationsTabProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted for approval — we\'ll review and confirm shortly.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openCompare() {
    final draft = ref.read(universityDraftProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF071221),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ChatTab(
            initialPrompt: draft.length >= 2
                ? 'Compare these universities for me and help me pick: '
                    '${draft.map((u) => u.name).join(", ")}.'
                : null,
          ),
        ),
      ),
    );
  }

  void _showReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DraftReviewSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(universityDraftProvider);
    final tabState = ref.watch(applicationsTabProvider);
    final maxPicks = tabState.maybeWhen(
      data: (s) => s.remainingSlots,
      orElse: () => kMaxUniversityPicks,
    );

    if (draft.isEmpty) return const SizedBox.shrink();

    final canCompare = draft.length >= 2;
    final atLimit = draft.length >= maxPicks;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F213D),
          border: Border(top: BorderSide(color: AppColors.vibrantLime.withOpacity(0.25))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _showReviewSheet,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          _ProgressDots(selected: draft.length, total: maxPicks),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${draft.length} of $maxPicks selected',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  atLimit ? 'Tap to review your picks' : 'Tap to review or add more',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (canCompare) ...[
                  IconButton(
                    tooltip: 'Compare with AI',
                    onPressed: _openCompare,
                    icon: const Icon(Icons.compare_arrows_rounded, color: AppColors.vibrantLime),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.vibrantLime.withOpacity(0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantLime,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int selected;
  final int total;
  const _ProgressDots({required this.selected, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final filled = i < selected;
        return Padding(
          padding: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: filled ? AppColors.vibrantLime : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: filled ? AppColors.vibrantLime : Colors.white24,
                width: 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Modal showing the current draft with per-row remove buttons.
class _DraftReviewSheet extends ConsumerWidget {
  const _DraftReviewSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(universityDraftProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.vibrantLime, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Your picks',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: draft.isEmpty
                  ? const Center(
                      child: Text('No picks yet.', style: TextStyle(color: Colors.white54)),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: draft.length,
                      itemBuilder: (context, i) {
                        final u = draft[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.vibrantLime.withOpacity(0.12),
                            foregroundImage: (u.logoUrl != null && u.logoUrl!.isNotEmpty)
                                ? NetworkImage(u.logoUrl!)
                                : null,
                            child: const Icon(Icons.school_outlined, color: AppColors.vibrantLime),
                          ),
                          title: Text(u.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(u.location, style: const TextStyle(color: Colors.white54)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white54),
                            onPressed: () => ref.read(universityDraftProvider.notifier).remove(u.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
