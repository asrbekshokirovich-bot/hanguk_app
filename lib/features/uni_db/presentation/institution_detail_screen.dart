import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/uni_db_providers.dart';
import 'widgets/coming_soon_card.dart';

class InstitutionDetailScreen extends ConsumerWidget {
  const InstitutionDetailScreen({super.key, required this.institutionId});

  final String institutionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(institutionDetailProvider(institutionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Institution')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (summary) {
          if (summary == null) {
            return const ComingSoonCard(
              title: 'Coming soon',
              subtitle:
                  'Per-institution detail wires up in Phase 2. The route '
                  'is registered behind UNI_DB_ENABLED=true.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                summary.nameKo,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (summary.nameEn != null) Text(summary.nameEn!),
              const SizedBox(height: 12),
              if (summary.nextEventAt != null)
                Text('Next event: ${summary.nextEventAt}'),
            ],
          );
        },
      ),
    );
  }
}
