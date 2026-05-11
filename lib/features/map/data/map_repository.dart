import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/university.dart';

/// Audit K1 / M1 (2026-05-11): the legacy `universities` table this
/// provider used to query was dropped on 2026-05-10 by
/// `supabase/migrations/20260510130000_uni_db_v3_drop_legacy_universities.sql`.
/// The replacement contract is `v_institutions_for_map`, defined in
/// `supabase/migrations/20260601000100_uni_db_v1_views.sql`.
///
/// Audit M24 (deferred to a follow-up): the previous version silently
/// swallowed errors and returned `[]`, so the user could not tell
/// "empty" from "broken". For the P0 batch we keep the same swallow
/// shape (returns `[]` on error) so the UI continues to render
/// gracefully; the empty-state copy is descriptive enough that the
/// failure mode is clear. M24 will re-throw and route the failure
/// through the proper error-state path.
final universitiesProvider = FutureProvider<List<University>>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('v_institutions_for_map')
        .select(
          'id, name_ko, name_ko_short, name_en, name_uz, '
          'city_ko, latitude, longitude, logo_url, tier, '
          'ieqas_status, is_partner, is_visible_on_map, '
          'last_verified_at, next_event_at',
        )
        .eq('is_visible_on_map', true)
        // No `ranking` column on the new view — `tier` is the closest
        // proxy (0 = flagship, 4 = unclassified). NULLS LAST so
        // unclassified institutions sort to the bottom.
        .order('tier', ascending: true, nullsFirst: false);

    return (data as List).map((row) {
      final map = row as Map<String, dynamic>;

      // Display-name resolution priority: en → uz → ko_short → ko.
      // The student-app primary locale is English / Uzbek; Korean is
      // a last-resort fallback so the student always sees something
      // readable. (Locale-aware rendering is M19.)
      final nameEn = map['name_en'] as String?;
      final nameUz = map['name_uz'] as String?;
      final nameKoShort = map['name_ko_short'] as String?;
      final nameKo = map['name_ko'] as String?;
      final resolvedName = (nameEn?.isNotEmpty ?? false)
          ? nameEn!
          : (nameUz?.isNotEmpty ?? false)
              ? nameUz!
              : (nameKoShort?.isNotEmpty ?? false)
                  ? nameKoShort!
                  : nameKo ?? 'Unknown Institution';

      final cityKo = map['city_ko'] as String?;
      final resolvedLocation =
          (cityKo?.isNotEmpty ?? false) ? cityKo! : 'South Korea';

      final nextEventRaw = map['next_event_at'] as String?;
      final nextEventAt = (nextEventRaw != null && nextEventRaw.isNotEmpty)
          ? DateTime.tryParse(nextEventRaw)
          : null;

      return University(
        id: map['id'] as String,
        name: resolvedName,
        location: resolvedLocation,
        nameKo: nameKo,
        nameKoShort: nameKoShort,
        nameEn: nameEn,
        nameUz: nameUz,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        logoUrl: map['logo_url'] as String?,
        tier: (map['tier'] as num?)?.toInt(),
        ieqasStatus: map['ieqas_status'] as String?,
        nextEventAt: nextEventAt,
        isPartner: map['is_partner'] as bool? ?? false,
        isVisibleOnMap: map['is_visible_on_map'] as bool? ?? true,
        // Deprecated legacy fields — always null after the migration.
      );
    }).toList();
  } on PostgrestException catch (e) {
    debugPrint('[MapRepository] Postgrest error: ${e.code} ${e.message}');
    return const [];
  } on Exception catch (e) {
    debugPrint('[MapRepository] Failed to load institutions: $e');
    return const [];
  }
});
