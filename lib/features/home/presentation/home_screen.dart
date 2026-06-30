import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/adaptive/ink_dock.dart';
import '../../../../design_system/adaptive/hanguk_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../applications/presentation/applications_tab.dart';
import '../../map/presentation/map_tab.dart';
import '../../documents/presentation/documents_tab.dart';
import '../../chat/presentation/chat_tab.dart';
import '../../training/presentation/training_tab.dart';
import '../../uni_db/data/admin_review_providers.dart';
import '../../updater/data/updater_repository.dart';
import '../../updater/presentation/update_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final repo = ref.read(updaterRepositoryProvider);
    final versionInfo = await repo.checkForUpdate();
    if (!mounted) return;
    if (versionInfo is UpdateAvailable) {
      showDialog(
        context: context,
        barrierDismissible: !versionInfo.effectivelyForced,
        builder: (context) => const UpdateDialog(),
      );
    }
  }

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

  /// The AI entry point now lives in the [InkDock]'s centre pill, so the only
  /// remaining floating action is the staff-only review queue. Hidden for
  /// students; gated server-side by fn_can_review_uni_db so the button only
  /// ever appears for non-student staff.
  Widget? _buildFloatingActions(BuildContext context) {
    final canReview = ref.watch(canReviewUniDbProvider).value ?? false;
    if (!canReview) return null;

    final pending = ref.watch(reviewQueueCountProvider).value ?? 0;
    return FloatingActionButton.extended(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeTabProvider);
    final l = AppLocalizations.of(context)!;
    return HangukScaffold(
      body: _tabs[currentIndex],
      floatingActionButton: _buildFloatingActions(context),
      bottomNavigationBar: InkDock(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeTabProvider.notifier).setTab(index);
        },
        onAskAi: () => _openAIChat(context),
        askAiLabel: l.a11yTooltipAskAi,
        items: [
          InkDockItem(label: l.navApplications, icon: Icons.school_rounded),
          InkDockItem(label: l.navMap, icon: Icons.location_on_rounded),
          InkDockItem(label: l.navDocs, icon: Icons.description_rounded),
          InkDockItem(
            label: l.navTraining,
            icon: Icons.self_improvement_rounded,
          ),
        ],
      ),
    );
  }
}
