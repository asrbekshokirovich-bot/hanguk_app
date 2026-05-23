import 'package:flutter_test/flutter_test.dart';
import 'package:hanguk_app/features/applications/presentation/university_draft_provider.dart';
import 'package:hanguk_app/features/map/domain/university.dart';

University _u(String id) => University(id: id, name: 'U$id', location: 'Seoul');

void main() {
  group('UniversityDraftNotifier', () {
    test('starts empty', () {
      final n = UniversityDraftNotifier();
      expect(n.state, isEmpty);
    });

    test('add appends and contains reports membership', () {
      final n = UniversityDraftNotifier();
      n.add(_u('1'));
      expect(n.state, hasLength(1));
      expect(n.contains('1'), isTrue);
      expect(n.contains('2'), isFalse);
    });

    test('add is idempotent — same id added twice still one entry', () {
      final n = UniversityDraftNotifier();
      n.add(_u('1'));
      n.add(_u('1'));
      expect(n.state, hasLength(1));
    });

    test('add rejects when remainingSlots reached', () {
      final n = UniversityDraftNotifier();
      n.add(_u('1'), remainingSlots: 2);
      n.add(_u('2'), remainingSlots: 2);
      final accepted = n.add(_u('3'), remainingSlots: 2);
      expect(accepted, isFalse);
      expect(n.state, hasLength(2));
    });

    test('remove deletes by id', () {
      final n = UniversityDraftNotifier();
      n.add(_u('1'));
      n.add(_u('2'));
      n.remove('1');
      expect(n.state.map((u) => u.id).toList(), ['2']);
    });

    test('toggle adds then removes', () {
      final n = UniversityDraftNotifier();
      n.toggle(_u('1'));
      expect(n.contains('1'), isTrue);
      n.toggle(_u('1'));
      expect(n.contains('1'), isFalse);
    });

    test('clear empties state', () {
      final n = UniversityDraftNotifier();
      n.add(_u('1'));
      n.add(_u('2'));
      n.clear();
      expect(n.state, isEmpty);
    });
  });
}
