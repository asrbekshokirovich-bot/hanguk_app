import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/adaptive/hanguk_scaffold.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../applications/presentation/applications_tab.dart';
import '../../map/presentation/map_tab.dart';
import '../../documents/presentation/documents_tab.dart';
import '../../chat/presentation/chat_tab.dart';
import '../../training/presentation/training_tab.dart';
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
    if (versionInfo != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: !versionInfo.forceUpdate,
        builder: (context) => UpdateDialog(updateInfo: versionInfo),
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

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(homeTabProvider);
    return HangukScaffold(
      body: _tabs[currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAIChat(context),
        backgroundColor: AppColors.vibrantLime,
        elevation: 6,
        child: const Icon(Icons.smart_toy, color: Colors.black, size: 28),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(homeTabProvider.notifier).state = index;
        },
        items: const [
          BottomNavigationBarItem(label: 'Home', icon: Icon(Icons.school)),
          BottomNavigationBarItem(label: 'Map', icon: Icon(Icons.map)),
          BottomNavigationBarItem(label: 'Docs', icon: Icon(Icons.description)),
          BottomNavigationBarItem(label: 'Training', icon: Icon(Icons.model_training_outlined)),
        ],
      ),
    );
  }
}
