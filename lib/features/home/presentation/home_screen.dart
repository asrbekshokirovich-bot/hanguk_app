import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/adaptive/adaptive_bottom_navigation.dart';
import '../../../../design_system/adaptive/hanguk_scaffold.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../applications/presentation/applications_tab.dart';
import '../../map/presentation/map_tab.dart';
import '../../documents/presentation/documents_tab.dart';
import '../../chat/presentation/chat_tab.dart';
import '../../training/presentation/training_tab.dart';
import '../../uni_db/data/admin_review_providers.dart';
import 'home_tab_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Widget> _tabs = [
    const ApplicationsTab(),
    const MapTab(),
    const DocumentsTab(),
    const TrainingTab(),
  ];

  // No _checkForUpdates here — see welcome_screen. It read `app_versions` and
  // opened UpdateDialog to download a build from Supabase Storage, an install
  // path the manifest can no longer perform, so it could only ever end in the
  // failure dialog. Updates come from Play.

  void _openAIChat(BuildContext context) {
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
          child: const ChatTab(),
        ),
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final aiChatFab = FloatingActionButton(
      heroTag: 'ai_chat_fab',
      onPressed: () => _openAIChat(context),
      backgroundColor: AppColors.vibrantLime,
      elevation: 6,
      tooltip: l.a11yTooltipAskAi,
      child: const Icon(Icons.smart_toy, color: Colors.black, size: 28),
    );

    // Staff-only entry to the university-data review queue. Hidden for
    // students; gated server-side by fn_can_review_uni_db so the button
    // only ever appears for non-student staff.
    final canReview = ref.watch(canReviewUniDbProvider).value ?? false;
    if (!canReview) return aiChatFab;

    final pending = ref.watch(reviewQueueCountProvider).value ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'staff_review_fab',
          onPressed: () => context.push('/admin/review'),
          backgroundColor: Colors.white,
          icon: const Icon(Icons.fact_check_outlined, color: Colors.black),
          label: Text(
            pending > 0 ? 'Review ($pending)' : 'Review',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        aiChatFab,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeTabProvider);
    final l = AppLocalizations.of(context)!;
    return HangukScaffold(
      body: _tabs[currentIndex],
      floatingActionButton: _buildFloatingActions(context),
      bottomNavigationBar: AdaptiveBottomNavigation(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeTabProvider.notifier).setTab(index);
        },
        items: [
          AdaptiveNavigationItem(label: l.navApplications, icon: Icons.school),
          AdaptiveNavigationItem(label: l.navMap, icon: Icons.map),
          AdaptiveNavigationItem(label: l.navDocs, icon: Icons.description),
          AdaptiveNavigationItem(
            label: l.navTraining,
            icon: Icons.model_training_outlined,
          ),
        ],
      ),
    );
  }
}
