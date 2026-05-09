import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/uni_db_providers.dart';
import '../domain/institution_summary.dart';
import '../domain/upcoming_deadline.dart';
import 'widgets/coming_soon_card.dart';

/// `/institutions/:id` — per-institution detail page.
///
/// Sections:
///   * Header (name_ko + name_en + name_uz + chips for city/tier/IEQAS/partner)
///   * Track / un-track switch (writes to user_tracked_universities)
///   * Upcoming deadlines (cycle_dates joined with admission_cycles)
///
/// Tuition / requirements / scholarships / document checklist sections
/// are scaffolded with TODO markers; the data is in Supabase but the
/// rendering layer for each is its own piece of work.
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
              title: 'Institution not found',
              subtitle:
                  'The id you opened does not match a row in '
                  'v_institutions_for_map. If the discovery worker just '
                  'crawled it, give it a few minutes.',
            );
          }
          return _DetailContent(
            institutionId: institutionId,
            summary: summary,
          );
        },
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.institutionId,
    required this.summary,
  });

  final String institutionId;
  final InstitutionSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(institutionTrackingProvider(institutionId));
    final deadlines = ref.watch(institutionDeadlinesProvider(institutionId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(summary: summary),
        const SizedBox(height: 16),
        _TrackToggle(
          institutionId: institutionId,
          tracking: tracking,
        ),
        const SizedBox(height: 24),
        Text(
          'Upcoming deadlines',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        deadlines.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Could not load deadlines: $e'),
          data: (rows) {
            if (rows.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No upcoming deadlines on file. The discovery worker '
                    'fills these in once the cycle is announced.',
                  ),
                ),
              );
            }
            return Column(
              children: rows.map((d) => _DeadlineTile(deadline: d)).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        const _SectionPlaceholder(
          title: 'Tuition',
          message:
              'Per-faculty tuition rows live in public.tuition. The data is '
              'extracted but rendering it as a table is on the next pass.',
        ),
        const SizedBox(height: 16),
        const _SectionPlaceholder(
          title: 'Requirements',
          message:
              'TOPIK levels, English-test requirements, GPA floors — '
              'fetched from public.requirements per applicant_category.',
        ),
        const SizedBox(height: 16),
        const _SectionPlaceholder(
          title: 'Scholarships',
          message:
              'TOPIK-tier scholarships and country-of-origin matrices. '
              'Stored in public.scholarships (uni_db shape, not the legacy '
              'one we renamed to legacy_scholarships).',
        ),
        const SizedBox(height: 16),
        const _SectionPlaceholder(
          title: 'Document checklist',
          message:
              'Country-of-origin routing for HS diploma / transcripts / '
              'apostille flow. Stored in public.documents_required.',
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.summary});
  final InstitutionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.nameKo, style: theme.textTheme.headlineSmall),
            if (summary.nameKoShort != null && summary.nameKoShort != summary.nameKo)
              Text(summary.nameKoShort!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            if (summary.nameEn != null) Text(summary.nameEn!),
            if (summary.nameUz != null)
              Text(summary.nameUz!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (summary.cityKo != null) Chip(label: Text(summary.cityKo!)),
                if (summary.tier != null) Chip(label: Text('Tier ${summary.tier}')),
                if (summary.ieqasStatus != null)
                  Chip(label: Text('IEQAS · ${summary.ieqasStatus}')),
                if (summary.isPartner)
                  Chip(
                    avatar: const Icon(Icons.handshake_outlined, size: 16),
                    label: const Text('Hanguk partner'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
              ],
            ),
            if (summary.lastVerifiedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Last verified: ${summary.lastVerifiedAt!.toIso8601String().split("T").first}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackToggle extends ConsumerStatefulWidget {
  const _TrackToggle({
    required this.institutionId,
    required this.tracking,
  });

  final String institutionId;
  final AsyncValue<Map<String, dynamic>?> tracking;

  @override
  ConsumerState<_TrackToggle> createState() => _TrackToggleState();
}

class _TrackToggleState extends ConsumerState<_TrackToggle> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return widget.tracking.when(
      loading: () => const ListTile(
        leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text('Track this institution'),
      ),
      error: (e, _) => ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text('Track this institution'),
        subtitle: Text('$e', style: const TextStyle(color: Colors.red)),
      ),
      data: (row) {
        final tracking = row != null;
        return Card(
          child: SwitchListTile(
            value: tracking,
            onChanged: _busy ? null : (v) => _toggle(v),
            title: const Text('Track this institution'),
            subtitle: Text(
              tracking
                  ? 'You will see deadlines on the home banner and get push '
                    'notifications when something changes.'
                  : 'Turn on to follow deadlines, correction notices, and '
                    'requirement changes.',
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggle(bool track) async {
    setState(() => _busy = true);
    try {
      await setInstitutionTracking(
        institutionId: widget.institutionId,
        track: track,
      );
      ref.invalidate(institutionTrackingProvider(widget.institutionId));
      ref.invalidate(notificationSettingsProvider);
      ref.invalidate(userTrackedProvider);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update tracking: $err')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({required this.deadline});
  final UpcomingDeadline deadline;

  @override
  Widget build(BuildContext context) {
    final days = deadline.daysUntil;
    final urgency = days <= 0
        ? 'TODAY'
        : days == 1
            ? 'in 1 day'
            : days <= 7
                ? 'in $days days'
                : 'in $days days';
    final urgencyColor = days <= 1
        ? Colors.red
        : days <= 7
            ? Colors.orange
            : Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: ListTile(
        leading: Icon(
          _iconFor(deadline.eventType),
          color: urgencyColor,
        ),
        title: Text(_labelFor(deadline.eventType)),
        subtitle: Text(
          deadline.startsAt.toIso8601String().replaceFirst('T', ' ').substring(0, 16) +
              (deadline.cycleTrack != null ? ' · ${deadline.cycleTrack}' : ''),
        ),
        trailing: Text(
          urgency,
          style: TextStyle(color: urgencyColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  IconData _iconFor(String eventType) => switch (eventType) {
        'apply_open' => Icons.lock_open,
        'apply_close' => Icons.lock_outline,
        'document_submission_deadline' => Icons.upload_file,
        'first_stage_results' => Icons.assignment_turned_in,
        'interview' => Icons.record_voice_over,
        'practical_exam' => Icons.science,
        'final_results' => Icons.emoji_events,
        'additional_admit' => Icons.add_circle_outline,
        'registration_open' => Icons.app_registration,
        'registration_close' => Icons.lock_clock,
        'orientation' => Icons.school,
        'semester_start' => Icons.calendar_today,
        _ => Icons.event,
      };

  String _labelFor(String eventType) => switch (eventType) {
        'apply_open' => 'Application opens',
        'apply_close' => 'Application closes',
        'document_submission_deadline' => 'Documents due',
        'first_stage_results' => 'First-stage results',
        'interview' => 'Interview',
        'practical_exam' => 'Practical exam',
        'final_results' => 'Final results',
        'additional_admit' => 'Additional admission',
        'registration_open' => 'Registration opens',
        'registration_close' => 'Registration closes',
        'orientation' => 'Orientation',
        'semester_start' => 'Semester starts',
        _ => eventType.replaceAll('_', ' '),
      };
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(message),
        ),
      ),
    );
  }
}
