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
