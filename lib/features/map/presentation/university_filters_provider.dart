import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/university.dart';

/// Sort order for the Map / list view. The default ordering from the
/// repository is by `tier` ascending; "Recommended" re-uses that plus
/// the student's quiz preferences (in `university_quiz_provider`) so
/// the most personally-relevant rows float up.
enum UniversitySort {
  recommended,
  tier,
  nearestDeadline,
  name,
}

extension UniversitySortLabel on UniversitySort {
  String get label => switch (this) {
        UniversitySort.recommended => 'Recommended',
        UniversitySort.tier => 'Tier',
        UniversitySort.nearestDeadline => 'Nearest deadline',
        UniversitySort.name => 'Name (A-Z)',
      };
}

/// Region buckets the user can pick. Matching is fuzzy against the
/// `location` free-text field — see `_regionMatches`.
enum UniversityRegion { seoul, busan, gyeonggi, other }

extension UniversityRegionLabel on UniversityRegion {
  String get label => switch (this) {
        UniversityRegion.seoul => 'Seoul',
        UniversityRegion.busan => 'Busan',
        UniversityRegion.gyeonggi => 'Gyeonggi / Incheon',
        UniversityRegion.other => 'Other regions',
      };
}

@immutable
class UniversityFilters {
  /// Lowercased, trimmed query — applied to name + location.
  final String query;

  /// Empty set means "all regions".
  final Set<UniversityRegion> regions;

  /// Empty set means "all tiers". Maps to `University.tier`. We expose
  /// "Top tier" (0-1) and "Other tiers" (2-4) at the UI layer so users
  /// don't have to think in tier numbers.
  final bool topTierOnly;

  final bool partnerOnly;
  final bool verifiedOnly;

  final UniversitySort sort;

  const UniversityFilters({
    this.query = '',
    this.regions = const {},
    this.topTierOnly = false,
    this.partnerOnly = false,
    this.verifiedOnly = false,
    this.sort = UniversitySort.recommended,
  });

  bool get hasAnyActive =>
      query.isNotEmpty ||
      regions.isNotEmpty ||
      topTierOnly ||
      partnerOnly ||
      verifiedOnly;

  /// Count of active filters (used by the "Filters" button badge).
  int get activeCount {
    var n = 0;
    if (regions.isNotEmpty) n++;
    if (topTierOnly) n++;
    if (partnerOnly) n++;
    if (verifiedOnly) n++;
    return n;
  }

  UniversityFilters copyWith({
    String? query,
    Set<UniversityRegion>? regions,
    bool? topTierOnly,
    bool? partnerOnly,
    bool? verifiedOnly,
    UniversitySort? sort,
  }) {
    return UniversityFilters(
      query: query ?? this.query,
      regions: regions ?? this.regions,
      topTierOnly: topTierOnly ?? this.topTierOnly,
      partnerOnly: partnerOnly ?? this.partnerOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      sort: sort ?? this.sort,
    );
  }

  /// Returns a new filter with everything cleared except sort (sort
  /// is a UI preference, not a "filter"; we keep it across resets).
  UniversityFilters cleared() => UniversityFilters(sort: sort);
}

class UniversityFiltersNotifier extends StateNotifier<UniversityFilters> {
  UniversityFiltersNotifier() : super(const UniversityFilters());

  void setQuery(String q) => state = state.copyWith(query: q.toLowerCase().trim());

  void toggleRegion(UniversityRegion r) {
    final next = Set<UniversityRegion>.from(state.regions);
    if (!next.add(r)) next.remove(r);
    state = state.copyWith(regions: next);
  }

  void setTopTier(bool v) => state = state.copyWith(topTierOnly: v);
  void setPartner(bool v) => state = state.copyWith(partnerOnly: v);
  void setVerified(bool v) => state = state.copyWith(verifiedOnly: v);
  void setSort(UniversitySort s) => state = state.copyWith(sort: s);

  /// Removes a specific filter without touching the others — used by
  /// the "active filter" pills above the search bar.
  void clearRegion(UniversityRegion r) {
    final next = Set<UniversityRegion>.from(state.regions)..remove(r);
    state = state.copyWith(regions: next);
  }

  void clearAll() => state = state.cleared();
}

final universityFiltersProvider =
    StateNotifierProvider<UniversityFiltersNotifier, UniversityFilters>(
  (ref) => UniversityFiltersNotifier(),
);

/// Pure helper so the same matching logic is used by the Map tab,
/// the filter-sheet's live counter and any tests.
List<University> applyUniversityFilters(
  List<University> all,
  UniversityFilters filters,
) {
  Iterable<University> out = all;

  if (filters.query.isNotEmpty) {
    out = out.where((u) =>
        u.name.toLowerCase().contains(filters.query) ||
        u.location.toLowerCase().contains(filters.query));
  }

  if (filters.regions.isNotEmpty) {
    out = out.where((u) => filters.regions.any((r) => _regionMatches(u.location, r)));
  }

  if (filters.topTierOnly) {
    out = out.where((u) => u.isTopTier);
  }
  if (filters.partnerOnly) {
    out = out.where((u) => u.isPartner);
  }
  if (filters.verifiedOnly) {
    out = out.where((u) => u.isAccredited);
  }

  final result = out.toList();

  switch (filters.sort) {
    case UniversitySort.recommended:
      // Repository already orders by tier ascending; for "recommended"
      // we let the caller layer student-quiz boosting on top. Default
      // here is a stable noop.
      break;
    case UniversitySort.tier:
      result.sort((a, b) {
        final at = a.tier ?? 99;
        final bt = b.tier ?? 99;
        return at.compareTo(bt);
      });
      break;
    case UniversitySort.nearestDeadline:
      result.sort((a, b) {
        final ad = a.nextEventAt;
        final bd = b.nextEventAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
      break;
    case UniversitySort.name:
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
  }

  return result;
}

bool _regionMatches(String location, UniversityRegion region) {
  final loc = location.toLowerCase();
  switch (region) {
    case UniversityRegion.seoul:
      return loc.contains('seoul') || loc.contains('서울');
    case UniversityRegion.busan:
      return loc.contains('busan') || loc.contains('부산');
    case UniversityRegion.gyeonggi:
      return loc.contains('gyeonggi') ||
          loc.contains('suwon') ||
          loc.contains('incheon') ||
          loc.contains('경기') ||
          loc.contains('인천') ||
          loc.contains('수원');
    case UniversityRegion.other:
      return !loc.contains('seoul') &&
          !loc.contains('busan') &&
          !loc.contains('gyeonggi') &&
          !loc.contains('incheon') &&
          !loc.contains('suwon') &&
          !loc.contains('서울') &&
          !loc.contains('부산');
  }
}
