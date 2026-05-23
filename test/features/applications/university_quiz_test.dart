import 'package:flutter_test/flutter_test.dart';
import 'package:hanguk_app/features/applications/presentation/university_quiz_provider.dart';
import 'package:hanguk_app/features/map/domain/university.dart';

University _u({
  required String name,
  required String location,
  int? tier,
  bool isPartner = false,
  String? ieqasStatus,
}) =>
    University(
      id: name,
      name: name,
      location: location,
      tier: tier,
      isPartner: isPartner,
      ieqasStatus: ieqasStatus,
    );

void main() {
  group('QuizPreferences.matchReasonsFor', () {
    test('returns no reasons before quiz is answered', () {
      const prefs = QuizPreferences(region: 'seoul', priority: 'top');
      final u = _u(name: 'Seoul Nat', location: 'Seoul', tier: 0);
      expect(prefs.matchReasonsFor(u), isEmpty);
    });

    test('region match adds a reason chip', () {
      const prefs = QuizPreferences(region: 'seoul', hasAnswered: true);
      final u = _u(name: 'Yonsei', location: 'Seoul');
      expect(prefs.matchReasonsFor(u), contains('Matches your region'));
    });

    test('priority=top matches top-tier universities', () {
      const prefs = QuizPreferences(priority: 'top', hasAnswered: true);
      final topU = _u(name: 'Yonsei', location: 'Seoul', tier: 1);
      final midU = _u(name: 'Inha', location: 'Incheon', tier: 3);
      expect(prefs.matchReasonsFor(topU), contains('Top tier'));
      expect(prefs.matchReasonsFor(midU), isNot(contains('Top tier')));
    });

    test('priority=partner matches partner universities only', () {
      const prefs = QuizPreferences(priority: 'partner', hasAnswered: true);
      final partner = _u(name: 'A', location: 'Seoul', isPartner: true);
      final notPartner = _u(name: 'B', location: 'Seoul');
      expect(prefs.matchReasonsFor(partner), contains('Partner university'));
      expect(prefs.matchReasonsFor(notPartner), isEmpty);
    });

    test('priority=verified matches IEQAS accredited only', () {
      const prefs = QuizPreferences(priority: 'verified', hasAnswered: true);
      final accredited = _u(name: 'A', location: 'Seoul', ieqasStatus: 'outstanding');
      final unaccredited = _u(name: 'B', location: 'Seoul');
      expect(prefs.matchReasonsFor(accredited), contains('Verified (IEQAS)'));
      expect(prefs.matchReasonsFor(unaccredited), isEmpty);
    });

    test('region "other" excludes the three big metros', () {
      const prefs = QuizPreferences(region: 'other', hasAnswered: true);
      final daejeon = _u(name: 'KAIST', location: 'Daejeon');
      final seoul = _u(name: 'Yonsei', location: 'Seoul');
      expect(prefs.matchReasonsFor(daejeon), contains('Matches your region'));
      expect(prefs.matchReasonsFor(seoul), isNot(contains('Matches your region')));
    });
  });
}
