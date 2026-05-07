import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/uni_db_providers.dart';
import 'widgets/coming_soon_card.dart';

class InstitutionCompareScreen extends ConsumerWidget {
  const InstitutionCompareScreen({super.key, required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRows = ref.watch(compareInstitutionsProvider(ids));
    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: asyncRows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const ComingSoonCard(
              title: 'Compare universities',
              subtitle: 'Phase 2 wires the side-by-side compare grid.',
              icon: Icons.compare_arrows,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (_, i) => ListTile(
              title: Text(rows[i].nameKo),
              subtitle: Text(rows[i].nameEn ?? ''),
            ),
          );
        },
      ),
    );
  }
}
