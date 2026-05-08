import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/feature_flags/uni_db_flag.dart';
import '../domain/review_queue_item.dart';

/// Reviewer's role from `public.profiles.role` for the current auth.uid().
///
/// The /admin/review route only renders if this returns
/// `uni_db_reviewer` or `uni_db_admin`. Other roles see a redirect.
final reviewerRoleProvider = FutureProvider<String?>((ref) async {
  if (!kUniDbEnabled) return null;
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return null;
  final row = await client
      .from('profiles')
      .select('role')
      .eq('user_id', user.id)
      .maybeSingle();
  return row?['role'] as String?;
});

/// Pending HITL queue, sorted by priority then queued_at (oldest first
/// inside priority).
final reviewQueueProvider = FutureProvider<List<ReviewQueueItem>>((ref) async {
  if (!kUniDbEnabled) return const [];
  final client = Supabase.instance.client;
  final rows = await client
      .from('v_review_queue_dashboard')
      .select()
      .order('priority')
      .order('queued_at')
      .limit(50);
  return (rows as List)
      .map((r) => ReviewQueueItem.fromMap(r as Map<String, dynamic>))
      .toList(growable: false);
});

/// Service wrapping the three SQL helper RPCs.
class ReviewActionsService {
  ReviewActionsService(this._client);

  final SupabaseClient _client;

  Future<void> accept(String queueItemId) async {
    await _client.rpc(
      'fn_review_accept',
      params: {'queue_item_id': queueItemId},
    );
  }

  Future<void> editAccept(
    String queueItemId,
    Map<String, dynamic> correctedPayload,
  ) async {
    await _client.rpc(
      'fn_review_edit_accept',
      params: {
        'queue_item_id': queueItemId,
        'corrected_payload': correctedPayload,
      },
    );
  }

  Future<void> reject(
    String queueItemId, {
    required String reason,
    String? reasonDetail,
  }) async {
    await _client.rpc(
      'fn_review_reject',
      params: {
        'queue_item_id': queueItemId,
        'reason': reason,
        'reason_detail': reasonDetail,
      },
    );
  }
}

final reviewActionsProvider = Provider<ReviewActionsService>(
  (ref) => ReviewActionsService(Supabase.instance.client),
);
