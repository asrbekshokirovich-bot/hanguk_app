// Guest Explore's approved-admission data is read from
// `v_guest_approved_admissions` instead of the hand-copied
// approved_uni_details.dart snapshot.
//
// These cover the parts that carry logic rather than plumbing: reading a view
// row, deciding whether a card has anything to expand onto, and flagging a fee
// that belongs to a different year than the intake it is shown under.
import 'package:flutter_test/flutter_test.dart';

import 'package:hanguk_app/features/guest/data/approved_admissions_provider.dart';

Map<String, dynamic> _row({
  int? tuitionMin,
  int? tuitionMax,
  int? tuitionYear,
  String? appStart,
  String? docDeadline,
  int? topik,
  bool? interview,
  bool? english,
}) {
  return <String, dynamic>{
    'institution_id': 'inst-1',
    'intake_year': 2027,
    'tuition_academic_year': tuitionYear,
    'tuition_min_krw': tuitionMin,
    'tuition_max_krw': tuitionMax,
    'admission_fee_krw': null,
    'application_start': appStart,
    'application_end': null,
    'document_deadline': docDeadline,
    'topik_min_level': topik,
    'interview_required': interview,
    'english_accepted': english,
  };
}

void main() {
  group('ApprovedUniDetail.fromRow', () {
    test('reads the fields the card renders', () {
      final d = ApprovedUniDetail.fromRow(
        _row(
          tuitionMin: 3169000,
          tuitionMax: 3295000,
          tuitionYear: 2026,
          appStart: '2026-11-10',
          docDeadline: '2027-01-21',
          topik: 3,
          interview: true,
          english: false,
        ),
      );

      expect(d.tuitionMinKrw, 3169000);
      expect(d.tuitionMaxKrw, 3295000);
      expect(d.tuitionAcademicYear, 2026);
      expect(d.appStart, '2026-11-10');
      expect(d.docDeadline, '2027-01-21');
      expect(d.topikMin, 3);
      expect(d.interviewRequired, isTrue);
      expect(d.englishAccepted, isFalse);
    });

    test('a timestamp is trimmed to a plain date', () {
      // The view returns `date`, but a column widened to timestamptz later
      // must not put a clock time on a deadline card.
      final d = ApprovedUniDetail.fromRow(
        _row(appStart: '2026-11-10T00:00:00+00:00'),
      );
      expect(d.appStart, '2026-11-10');
    });

    test('empty strings read as absent, not as a value', () {
      final d = ApprovedUniDetail.fromRow(_row(appStart: '', docDeadline: ''));
      expect(d.appStart, isNull);
      expect(d.docDeadline, isNull);
    });
  });

  group('hasAny', () {
    test('a row with nothing extracted offers no details block', () {
      // Every approved (institution, year) pair gets a row, but extraction
      // covers the fields unevenly — a card with nothing must not offer an
      // expander that opens onto dashes.
      expect(ApprovedUniDetail.fromRow(_row()).hasAny, isFalse);
    });

    test('the tuition year alone is not content', () {
      // It labels a fee; with no fee to label there is nothing to show.
      expect(
        ApprovedUniDetail.fromRow(_row(tuitionYear: 2026)).hasAny,
        isFalse,
      );
    });

    test('any single real field is enough', () {
      expect(ApprovedUniDetail.fromRow(_row(topik: 3)).hasAny, isTrue);
      expect(ApprovedUniDetail.fromRow(_row(interview: false)).hasAny, isTrue);
      expect(
        ApprovedUniDetail.fromRow(_row(docDeadline: '2027-01-21')).hasAny,
        isTrue,
      );
    });
  });

  group('tuitionIsFromAnotherYear', () {
    test('a 2026 fee under a 2027 intake is flagged', () {
      // The common case: Korean guidelines quote the current year's fees, so
      // every fee in the catalogue today is 2026 while most intakes are 2027.
      final d = ApprovedUniDetail.fromRow(
        _row(tuitionMin: 5124000, tuitionYear: 2026),
      );
      expect(d.tuitionIsFromAnotherYear(2027), isTrue);
    });

    test('a matching year is not flagged', () {
      final d = ApprovedUniDetail.fromRow(
        _row(tuitionMin: 5124000, tuitionYear: 2027),
      );
      expect(d.tuitionIsFromAnotherYear(2027), isFalse);
    });

    test('no fee year means nothing to disclaim', () {
      expect(
        ApprovedUniDetail.fromRow(_row()).tuitionIsFromAnotherYear(2027),
        isFalse,
      );
    });
  });

  group('ApprovedAdmissions', () {
    test('a null year filter matches every institution', () {
      expect(ApprovedAdmissions.empty.isApprovedFor('anything', null), isTrue);
    });

    test('an unknown institution matches no specific year', () {
      const a = ApprovedAdmissions(
        years: {'inst-1': [2027]},
        details: {},
        detailYear: {},
      );
      expect(a.isApprovedFor('inst-1', 2027), isTrue);
      expect(a.isApprovedFor('inst-1', 2026), isFalse);
      expect(a.isApprovedFor('inst-2', 2027), isFalse);
    });

    test('empty is safe to render before the first fetch lands', () {
      expect(ApprovedAdmissions.empty.years, isEmpty);
      expect(ApprovedAdmissions.empty.details, isEmpty);
      expect(ApprovedAdmissions.empty.detailYear, isEmpty);
    });
  });
}
