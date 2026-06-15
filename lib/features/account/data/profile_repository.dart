import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';

/// The current user's profile fields shown on the account screen. Students
/// authenticate with a magic code, so their Supabase Auth `email` is a
/// synthetic `student-<uuid>@hanguk.local` value — useless to display.
/// These come from the `profiles` table instead (RLS: a user can read
/// their own row).
class StudentProfile {
  final String? fullName;
  final String? phone;
  final String? username;

  const StudentProfile({this.fullName, this.phone, this.username});

  bool get hasName => (fullName ?? '').trim().isNotEmpty;
  bool get hasPhone => (phone ?? '').trim().isNotEmpty;
  bool get hasUsername => (username ?? '').trim().isNotEmpty;
}

final studentProfileProvider = FutureProvider<StudentProfile?>((ref) async {
  // Watch auth state so the profile refetches on login/logout.
  final authState = ref.watch(authStateProvider);
  final user =
      authState.value?.session?.user ??
      Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final data = await Supabase.instance.client
      .from('profiles')
      .select('full_name, phone, username')
      .eq('user_id', user.id)
      .maybeSingle();

  if (data == null) return null;
  return StudentProfile(
    fullName: data['full_name'] as String?,
    phone: data['phone'] as String?,
    username: data['username'] as String?,
  );
});
