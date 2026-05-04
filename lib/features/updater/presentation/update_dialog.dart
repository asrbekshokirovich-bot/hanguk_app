import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/updater_repository.dart';
import '../../../design_system/theme/app_colors.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  final AppVersionInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _error = '';

  Future<void> _handleUpdate() async {
    if (widget.updateInfo.downloadUrl.isEmpty) {
      setState(() => _error = 'Update link is currently unavailable.');
      return;
    }
    
    final repo = ref.read(updaterRepositoryProvider);
    final success = await repo.triggerUpdate(widget.updateInfo);

    if (mounted && !success) {
      setState(() {
        _error = 'Failed to open the browser for download. Check URL format.';
      });
    } else {
       // On success, the OS browser intercepts. If mandatory, we keep the screen locked.
       if (!widget.updateInfo.forceUpdate && mounted) {
          Navigator.of(context).pop();
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.updateInfo.forceUpdate && !_isDownloading,
      child: AlertDialog(
        backgroundColor: AppColors.darkSlate,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AppColors.vibrantLime),
            const SizedBox(width: 12),
            const Text(
              'Update Available',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${widget.updateInfo.latestVersion} is ready to install.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _error,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ]
          ],
        ),
        actions: [
          if (!widget.updateInfo.forceUpdate && !_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later', style: TextStyle(color: Colors.white54)),
            ),
          ElevatedButton(
            onPressed: _handleUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantLime,
              foregroundColor: Colors.black,
            ),
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
