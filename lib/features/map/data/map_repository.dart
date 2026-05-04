import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/university.dart';

final universitiesProvider = FutureProvider<List<University>>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('universities')
        .select(
          'id, name_en, city_en, latitude, longitude, logo_url, '
          'ranking, local_rank, acceptance_rate, tuition_min, tuition_max, '
          'is_partner, is_visible_on_map, website_url, description_en',
        )
        .eq('is_visible_on_map', true)
        .order('ranking', ascending: true, nullsFirst: false);

    return (data as List)
        .map(
          (row) => University(
            id: row['id'] as String,
            name: row['name_en'] as String? ?? 'Unknown University',
            location: row['city_en'] as String? ?? 'South Korea',
            latitude: (row['latitude'] as num?)?.toDouble(),
            longitude: (row['longitude'] as num?)?.toDouble(),
            logoUrl: row['logo_url'] as String?,
            ranking: row['ranking'] as int?,
            localRank: row['local_rank'] as int?,
            acceptanceRate: (row['acceptance_rate'] as num?)?.toDouble(),
            tuitionMin: row['tuition_min'] as int?,
            tuitionMax: row['tuition_max'] as int?,
            isPartner: row['is_partner'] as bool? ?? false,
            isVisibleOnMap: row['is_visible_on_map'] as bool? ?? true,
            website: row['website_url'] as String?,
            descriptionEn: row['description_en'] as String?,
          ),
        )
        .toList();
  } catch (e) {
    debugPrint('[MapRepository] Failed to load universities: $e');
    return [];
  }
});
