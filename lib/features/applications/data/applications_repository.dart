import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/application.dart';
import '../../map/domain/university.dart';
import '../../auth/data/auth_repository.dart';

/// Phase 3R-B (2026-05-10): the legacy `universities` table was dropped
/// and replaced by `institutions`. The FK column on `applications` and
/// `student_suggestions` was renamed `university_id` → `institution_id`.
/// All reads below embed `institution:institutions(...)` and resolve the
/// display name in priority order: English → Korean (short) → Korean.
/// The `institutions` table has no `name_uz`/`city_en` columns — the only
/// location column is `city_ko`.
University _universityFromInstitutionRow(Map<String, dynamic> u) {
  final nameEn = u['name_en'] as String?;
  final nameKoShort = u['name_ko_short'] as String?;
  final nameKo = u['name_ko'] as String?;
  final resolvedName = (nameEn?.isNotEmpty ?? false)
      ? nameEn!
      : (nameKoShort?.isNotEmpty ?? false)
      ? nameKoShort!
      : (nameKo?.isNotEmpty ?? false)
      ? nameKo!
      : 'Unknown University';

  final cityKo = u['city_ko'] as String?;

  return University(
    id: u['id'] as String,
    name: resolvedName,
    location: (cityKo?.isNotEmpty ?? false) ? cityKo! : 'South Korea',
    nameEn: nameEn,
    nameKo: nameKo,
    nameKoShort: nameKoShort,
    isPartner: u['is_partner'] as bool? ?? false,
    latitude: u['latitude'] != null ? (u['latitude'] as num).toDouble() : null,
    longitude: u['longitude'] != null
        ? (u['longitude'] as num).toDouble()
        : null,
    logoUrl: u['logo_url'] as String?,
  );
}

// Columns selected from `institutions` for the lightweight cards/lists in
// this feature. Kept in one place so the embedded and direct queries match.
const String _institutionCols =
    'id, name_en, name_ko, name_ko_short, city_ko, '
    'is_partner, latitude, longitude, logo_url';

// Provider to fetch suggested universities for the student
final suggestedUniversitiesProvider = FutureProvider<List<University>>((
  ref,
) async {
  // Watch the provider directly (sync) to avoid async stream .future caching bugs
  final authState = ref.watch(authStateProvider);
  final user =
      authState.value?.session?.user ??
      Supabase.instance.client.auth.currentUser;
  if (user == null) {
    debugPrint('[Suggestions] user is null, returning empty list');
    return [];
  }

  final client = Supabase.instance.client;

  try {
    // Attempt to fetch from CRM suggestions table, embedding the institution.
    final data = await client
        .from('student_suggestions')
        .select('institution_id, institution:institutions($_institutionCols)')
        .eq('student_id', user.id);

    debugPrint(
      '[Suggestions] student_suggestions query for ${user.id} returned ${(data as List).length} rows',
    );
    final List<University> suggestions = [];
    for (var row in data as List) {
      final u = row['institution'] as Map<String, dynamic>?;
      if (u != null) {
        suggestions.add(_universityFromInstitutionRow(u));
      }
    }

    // If we have explicit CRM suggestions, return those
    if (suggestions.isNotEmpty) {
      debugPrint(
        '[Suggestions] returning ${suggestions.length} CRM suggestions',
      );
      return suggestions;
    }
  } catch (e) {
    if (e is PostgrestException && e.code == 'PGRST205') {
      debugPrint(
        '[Suggestions] student_suggestions table missing, falling back.',
      );
    } else {
      debugPrint('[Suggestions] Error fetching explicit suggestions: $e');
    }
  }

  try {
    // Fallback: If no explicit CRM suggestions exist yet, fetch partner
    // institutions directly. RLS already restricts reads to
    // map-visible institutions for app users; the explicit
    // `is_visible_on_map` filter keeps the intent obvious.
    final fallbackData = await client
        .from('institutions')
        .select(_institutionCols)
        .eq('is_partner', true)
        .eq('is_visible_on_map', true)
        .limit(5);
    debugPrint(
      '[Suggestions] Fallback partner institutions returned ${(fallbackData as List).length} rows',
    );
    if ((fallbackData as List).isEmpty) {
      debugPrint(
        '[Suggestions] WARNING: Fallback returned 0 institutions. Ensure is_partner=true is set for some institutions.',
      );
    }

    return fallbackData
        .map<University>((u) => _universityFromInstitutionRow(u))
        .toList();
  } catch (e, st) {
    debugPrint('[Suggestions] Failed to fetch fallback suggestions: $e\n$st');
    rethrow;
  }
});

// Method to submit selected universities for CRM approval
Future<void> submitSelectedUniversities(List<String> universityIds) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) throw Exception('User not logged in');

  final inserts = universityIds
      .map(
        (uId) => {
          'student_id': user.id,
          'institution_id': uId,
          'status': 'pending_approval',
        },
      )
      .toList();

  // 1. Insert into applications
  await client.from('applications').insert(inserts);

  // 2. Delete ALL university suggestions for this student
  // since they submitted their chosen batch of universities.
  try {
    await client.from('student_suggestions').delete().eq('student_id', user.id);
  } catch (e) {
    debugPrint(
      '[ApplicationsRepository] Failed to clear remaining suggestions: $e',
    );
    // We swallow this error because the application was successfully submitted
  }
}

final applicationsProvider = FutureProvider<List<StudentApplication>>((
  ref,
) async {
  // Watch the provider directly (sync) to avoid async stream .future caching bugs
  final authState = ref.watch(authStateProvider);
  final user =
      authState.value?.session?.user ??
      Supabase.instance.client.auth.currentUser;
  if (user == null) {
    debugPrint('[Applications] user is null, returning empty list');
    return [];
  }

  final client = Supabase.instance.client;
  try {
    // Embed the institution to get its name/location in one call.
    final data = await client
        .from('applications')
        .select('*, institution:institutions($_institutionCols)')
        .eq('student_id', user.id)
        .order('created_at', ascending: false);

    debugPrint(
      '[Applications] Query for student ${user.id} returned ${(data as List).length} applications',
    );

    return (data as List).map((row) {
      // Parse the embedded institution row (may be null if RLS hides it
      // or the FK is unset).
      University? university;
      final uniRow = row['institution'] as Map<String, dynamic>?;
      if (uniRow != null) {
        university = _universityFromInstitutionRow(uniRow);
      }

      return StudentApplication(
        id: row['id'] as String,
        studentId: row['student_id'] as String,
        universityId: row['institution_id'] as String? ?? '',
        program: row['program'] as String? ?? '',
        status: row['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(row['created_at'] as String),
        university: university,
      );
    }).toList();
  } catch (e, st) {
    debugPrint(
      '[ApplicationsRepository] Failed to fetch applications: $e\n$st',
    );
    rethrow;
  }
});
