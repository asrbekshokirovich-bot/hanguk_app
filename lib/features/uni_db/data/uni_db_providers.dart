import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/feature_flags/uni_db_flag.dart';
import '../domain/institution_summary.dart';
import '../domain/recruitment_target.dart';
import '../domain/upcoming_deadline.dart';

/// Read-only Riverpod providers backed by the new uni_db views (plan §H).
///
/// Every provider short-circuits to an empty result when [kUniDbEnabled]
/// is false, so the production app behaves exactly as before until the
/// flag flips.
///
/// All reads target views, never raw tables, per plan §H.1 stable contract.

/// Institution detail — `/institutions/:id` route.
final institutionDetailProvider =
    FutureProvider.family<InstitutionSummary?, String>((ref, id) async {
  if (!kUniDbEnabled) return null;
  final client = Supabase.instance.client;
  final row = await client
      .from('v_institutions_for_map')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (row == null) return null;
  return InstitutionSummary.fromMap(row);
});

/// Institution comparison — `/institutions/compare?ids=a,b,c`.
final compareInstitutionsProvider =
    FutureProvider.family<List<InstitutionSummary>, List<String>>((ref, ids) async {
  if (!kUniDbEnabled || ids.isEmpty) return const [];
  final client = Supabase.instance.client;
  final rows = await client
      .from('v_institutions_for_map')
      .select()
      .inFilter('id', ids);
  return (rows as List)
      .map((r) => InstitutionSummary.fromMap(r as Map<String, dynamic>))
      .toList(growable: false);
});

/// User-tracked summary — `/applications/tracker`.
final userTrackedProvider = FutureProvider<List<UpcomingDeadline>>((ref) async {
  if (!kUniDbEnabled) return const [];
  final client = Supabase.instance.client;
  final rows = await client
      .from('v_user_upcoming_deadlines')
      .select()
      .order('starts_at');
  return (rows as List)
      .map((r) => UpcomingDeadline.fromMap(r as Map<String, dynamic>))
      .toList(growable: false);
});

/// Notification settings — `/notifications/settings`. Backed by
/// `user_tracked_universities` rows scoped by RLS to the current user.
final notificationSettingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  if (!kUniDbEnabled) return const [];
  final client = Supabase.instance.client;
  final rows = await client.from('user_tracked_universities').select();
  return List<Map<String, dynamic>>.from(rows as List);
});

/// Powers the `university_specific` interview path (plan §H.4) — fetches
/// the recruitment unit + cycle + requirements bundle the Edge Function
/// will eventually consume. Returns null until the flag is on so existing
/// behaviour is preserved.
final recruitmentForInterviewProvider =
    FutureProvider.family<RecruitmentTarget?, String>((ref, institutionId) async {
  if (!kUniDbEnabled) return null;
  final client = Supabase.instance.client;
  final rows = await client
      .from('v_recruitment_for_interview')
      .select()
      .eq('institution_id', institutionId)
      .limit(1);
  final list = rows as List;
  if (list.isEmpty) return null;
  return RecruitmentTarget.fromMap(list.first as Map<String, dynamic>);
});

/// Upcoming deadlines for one institution. Joins cycle_dates against
/// admission_cycles to give the institution-scoped slice that
/// v_user_upcoming_deadlines doesn't expose (the user-view filters by
/// what the user is currently tracking; this returns everything for
/// the institution regardless).
final institutionDeadlinesProvider =
    FutureProvider.family<List<UpcomingDeadline>, String>((ref, institutionId) async {
  if (!kUniDbEnabled) return const [];
  final client = Supabase.instance.client;
  final rows = await client
      .from('cycle_dates')
      .select(
        'event_type, starts_at, ends_at, is_tentative, '
        'admission_cycles!inner(institution_id, applicant_category, cycle_year, '
        'institutions!inner(id, name_ko, name_ko_short))',
      )
      .eq('admission_cycles.institution_id', institutionId)
      .gte('starts_at', DateTime.now().toIso8601String())
      .order('starts_at')
      .limit(20);
  return (rows as List).map((r) {
    final m = r as Map<String, dynamic>;
    final cycle = m['admission_cycles'] as Map<String, dynamic>? ?? const {};
    final inst = cycle['institutions'] as Map<String, dynamic>? ?? const {};
    return UpcomingDeadline(
      institutionId: (inst['id'] as String?) ?? institutionId,
      nameKo: (inst['name_ko'] as String?) ?? '',
      nameKoShort: inst['name_ko_short'] as String?,
      eventType: (m['event_type'] as String?) ?? '',
      startsAt: DateTime.tryParse(m['starts_at']?.toString() ?? '') ?? DateTime.now(),
      endsAt: m['ends_at'] != null ? DateTime.tryParse(m['ends_at'].toString()) : null,
      isTentative: (m['is_tentative'] as bool?) ?? false,
      cycleTrack: cycle['applicant_category'] as String?,
    );
  }).toList(growable: false);
});

/// Whether the current user tracks the given institution.
/// Returns null if the row doesn't exist (not tracked).
final institutionTrackingProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, institutionId) async {
  if (!kUniDbEnabled) return null;
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;
  return await client
      .from('user_tracked_universities')
      .select()
      .eq('user_id', user.id)
      .eq('institution_id', institutionId)
      .maybeSingle();
});

/// Toggle tracking. Inserts a row with default notification prefs
/// (correction + calendar on; scholarship off) when track=true.
/// Deletes the row when track=false.
///
/// Caller is responsible for invalidating the relevant providers
/// (institutionTrackingProvider(id), notificationSettingsProvider,
/// userTrackedProvider) after this returns.
Future<void> setInstitutionTracking({
  required String institutionId,
  required bool track,
}) async {
  if (!kUniDbEnabled) return;
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    throw StateError('Cannot toggle tracking without an authenticated user');
  }
  if (track) {
    await client.from('user_tracked_universities').upsert({
      'user_id': user.id,
      'institution_id': institutionId,
      'notify_on_calendar_change': true,
      'notify_on_correction': true,
      'notify_on_requirement_change': true,
      'notify_on_scholarship_change': false,
    }, onConflict: 'user_id,institution_id');
  } else {
    await client
        .from('user_tracked_universities')
        .delete()
        .eq('user_id', user.id)
        .eq('institution_id', institutionId);
  }
}

/// Update notification prefs for one tracked institution.
///
/// Caller is responsible for invalidating notificationSettingsProvider
/// (and optionally institutionTrackingProvider) after this returns.
Future<void> updateNotificationPrefs({
  required String institutionId,
  bool? notifyOnCalendarChange,
  bool? notifyOnCorrection,
  bool? notifyOnRequirementChange,
  bool? notifyOnScholarshipChange,
}) async {
  if (!kUniDbEnabled) return;
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    throw StateError('Cannot update prefs without an authenticated user');
  }
  await client
      .from('user_tracked_universities')
      .update({
        'notify_on_calendar_change': ?notifyOnCalendarChange,
        'notify_on_correction': ?notifyOnCorrection,
        'notify_on_requirement_change': ?notifyOnRequirementChange,
        'notify_on_scholarship_change': ?notifyOnScholarshipChange,
      })
      .eq('user_id', user.id)
      .eq('institution_id', institutionId);
}
