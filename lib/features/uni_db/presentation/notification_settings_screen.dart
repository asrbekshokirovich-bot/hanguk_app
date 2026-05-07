import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/uni_db_providers.dart';
import 'widgets/coming_soon_card.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRows = ref.watch(notificationSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: asyncRows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const ComingSoonCard(
              title: 'Notification settings',
              subtitle:
                  'Phase 3 wires push (FCM/APNs/web-push). For now the '
                  'preferences are stored in user_tracked_universities.',
              icon: Icons.notifications_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final r = rows[i];
              return SwitchListTile(
                value: (r['notify_on_correction'] as bool?) ?? true,
                onChanged: null,
                title: Text(
                  r['institution_id']?.toString() ?? '<unknown>',
                ),
                subtitle: const Text(
                  'Editable in Phase 3 — see plan §H.6.',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
