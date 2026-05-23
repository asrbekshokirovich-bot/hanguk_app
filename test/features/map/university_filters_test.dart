import 'package:flutter_test/flutter_test.dart';
import 'package:hanguk_app/features/map/domain/university.dart';
import 'package:hanguk_app/features/map/presentation/university_filters_provider.dart';

University _u({
  required String id,
  required String name,
  required String location,
  int? tier,
  bool isPartner = false,
  String? ieqasStatus,
  DateTime? nextEventAt,
}) =>
    University(
      id: id,
      name: name,
      location: location,
      tier: tier,
      isPartner: isPartner,
      ieqasStatus: ieqasStatus,
      nextEventAt: nextEventAt,
    );

void main() {
  final fixtures = [
    _u(id: '1', name: 'Seoul National', location: 'Seoul', tier: 0, ieqasStatus: 'outstanding'),
    _u(id: '2', name: 'Yonsei', location: 'Seoul', tier: 1, isPartner: true),
    _u(id: '3', name: 'Pusan National', location: 'Busan', tier: 2),
    _u(id: '4', name: 'KAIST', location: 'Daejeon', tier: 0),
    _u(id: '5', name: 'Inha', location: 'Incheon', tier: 3, isPartner: true),
  ];

  group('applyUniversityFilters', () {
    test('no filters returns input unchanged in order', () {
      final result = applyUniversityFilters(fixtures, const UniversityFilters());
      expect(result.map((u) => u.id).toList(), ['1', '2', '3', '4', '5']);
    });

    test('text query matches name and location case-insensitively', () {
      final result = applyUniversityFilters(
        fixtures,
        const UniversityFilters(query: 'seoul'),
      );
      expect(result.map((u) => u.id).toSet(), {'1', '2'});
    });

    test('region filter buckets Seoul vs Busan vs Gyeonggi/Incheon vs other', () {
      final seoul = applyUniversityFilters(
        fixtures,
        const UniversityFilters(regions: {UniversityRegion.seoul}),
      );
      expect(seoul.map((u) => u.id).toSet(), {'1', '2'});

      final gyeonggi = applyUniversityFilters(
        fixtures,
        const UniversityFilters(regions: {UniversityRegion.gyeonggi}),
      );
      expect(gyeonggi.map((u) => u.id).toSet(), {'5'});

      final other = applyUniversityFilters(
        fixtures,
        const UniversityFilters(regions: {UniversityRegion.other}),
      );
      // Daejeon doesn't match any specific region
      expect(other.map((u) => u.id).toSet(), {'4'});
    });

    test('topTierOnly keeps only tier 0 and 1', () {
      final result = applyUniversityFilters(
        fixtures,
        const UniversityFilters(topTierOnly: true),
      );
      expect(result.map((u) => u.id).toSet(), {'1', '2', '4'});
    });

    test('partnerOnly keeps only partners', () {
      final result = applyUniversityFilters(
        fixtures,
        const UniversityFilters(partnerOnly: true),
      );
      expect(result.map((u) => u.id).toSet(), {'2', '5'});
    });

    test('verifiedOnly keeps only IEQAS-accredited', () {
      final result = applyUniversityFilters(
        fixtures,
        const UniversityFilters(verifiedOnly: true),
      );
      expect(result.map((u) => u.id).toSet(), {'1'});
    });

    test('multiple filters AND together', () {
      final result = applyUniversityFilters(
        fixtures,
        const UniversityFilters(
          regions: {UniversityRegion.seoul},
          partnerOnly: true,
        ),
      );
      expect(result.map((u) => u.id).toSet(), {'2'});
    });

    test('sort by name alphabetizes', () {
      final result = applyUniversityFilters(
        fixtures,
        const UniversityFilters(sort: UniversitySort.name),
      );
      expect(result.map((u) => u.name).toList(), [
        'Inha',
        'KAIST',
        'Pusan National',
        'Seoul National',
        'Yonsei',
      ]);
    });

    test('sort by tier puts top tiers first, nulls last', () {
      final withNull = [
        ...fixtures,
        _u(id: '6', name: 'Unclassified', location: 'Daegu', tier: null),
      ];
      final result = applyUniversityFilters(
        withNull,
        const UniversityFilters(sort: UniversitySort.tier),
      );
      expect(result.last.id, '6'); // unclassified at end
      expect(result.first.tier, 0);
    });

    test('sort by nearest deadline puts soonest first, nulls last', () {
      final dated = [
        _u(id: 'a', name: 'A', location: 'Seoul', nextEventAt: DateTime(2027, 1, 1)),
        _u(id: 'b', name: 'B', location: 'Seoul', nextEventAt: null),
        _u(id: 'c', name: 'C', location: 'Seoul', nextEventAt: DateTime(2026, 6, 1)),
      ];
      final result = applyUniversityFilters(
        dated,
        const UniversityFilters(sort: UniversitySort.nearestDeadline),
      );
      expect(result.map((u) => u.id).toList(), ['c', 'a', 'b']);
    });
  });

  group('UniversityFilters.activeCount + hasAnyActive', () {
    test('counts each active filter once', () {
      const filters = UniversityFilters(
        regions: {UniversityRegion.seoul, UniversityRegion.busan},
        topTierOnly: true,
        partnerOnly: true,
      );
      // regions counted as 1 group (matching the badge UX)
      expect(filters.activeCount, 3);
      expect(filters.hasAnyActive, isTrue);
    });

    test('query alone is "active" but does not count toward badge', () {
      const filters = UniversityFilters(query: 'seoul');
      expect(filters.hasAnyActive, isTrue);
      expect(filters.activeCount, 0);
    });

    test('cleared filter preserves sort but drops everything else', () {
      const filters = UniversityFilters(
        topTierOnly: true,
        sort: UniversitySort.name,
      );
      final cleared = filters.cleared();
      expect(cleared.topTierOnly, isFalse);
      expect(cleared.sort, UniversitySort.name);
    });
  });
}
