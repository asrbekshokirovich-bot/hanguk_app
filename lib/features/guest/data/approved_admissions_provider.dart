import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../map/domain/university.dart';

/// Approved admission details for one institution, read from
/// `v_guest_approved_admissions`.
///
/// This replaces `domain/approved_uni_details.dart`, a 93-entry map whose own
/// docstring called it a "snapshot copied verbatim from the DB", taken
/// 2026-08-08. A snapshot goes stale the moment a guideline is approved, and
/// that one already had: between it and today the catalogue moved from 48
/// approved institutions to 57 (2026: 7 → 13, 2027: 41 → 55). Twenty
/// (institution, year) pairs a student could not see, with nothing to signal
/// it but someone re-running the export by hand.
///
/// A null field means the approved review did not provide that value — the
/// card shows a dash. It does not mean the fetch failed.
class ApprovedUniDetail {
  final int? tuitionMinKrw;
  final int? tuitionMaxKrw;
  final int? admissionFeeKrw;

  /// The year the fee actually belongs to. Korean guidelines quote the current
  /// year's fees as a reference, so a 2027 모집요강 carries a table stamped
  /// 2026 — every tuition row in the catalogue today is 2026 while most cycles
  /// are 2027. The card shows this alongside the amount rather than letting a
  /// last-year figure pass as the intake's.
  final int? tuitionAcademicYear;

  final String? appStart; // application opens (YYYY-MM-DD)
  final String? appEnd; // application closes
  final String? docDeadline; // documents deadline
  final int? topikMin; // lowest TOPIK level across this year's tracks
  final bool? interviewRequired;
  final bool? englishAccepted; // an English test is named in the requirements

  const ApprovedUniDetail({
    this.tuitionMinKrw,
    this.tuitionMaxKrw,
    this.admissionFeeKrw,
    this.tuitionAcademicYear,
    this.appStart,
    this.appEnd,
    this.docDeadline,
    this.topikMin,
    this.interviewRequired,
    this.englishAccepted,
  });

  /// True when the fee on show is not the intake year's own.
  bool tuitionIsFromAnotherYear(int intakeYear) =>
      tuitionAcademicYear != null && tuitionAcademicYear != intakeYear;

  /// Whether there is anything worth expanding on the card. A row exists for
  /// every approved (institution, year) pair, but extraction covers the fields
  /// unevenly — most rows carry a couple at most — so a card with nothing to
  /// show must not offer a "details" affordance that opens onto dashes.
  /// `tuitionAcademicYear` is deliberately not counted: it labels a fee rather
  /// than being one.
  bool get hasAny =>
      tuitionMinKrw != null ||
      appStart != null ||
      appEnd != null ||
      docDeadline != null ||
      topikMin != null ||
      interviewRequired != null ||
      englishAccepted != null;

  static String? _date(Object? v) {
    final s = v as String?;
    if (s == null || s.isEmpty) return null;
    // The view returns `date`, which PostgREST renders as YYYY-MM-DD; keep
    // only that much if a timestamp ever arrives instead.
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  factory ApprovedUniDetail.fromRow(Map<String, dynamic> r) {
    return ApprovedUniDetail(
      tuitionMinKrw: r['tuition_min_krw'] as int?,
      tuitionMaxKrw: r['tuition_max_krw'] as int?,
      admissionFeeKrw: r['admission_fee_krw'] as int?,
      tuitionAcademicYear: r['tuition_academic_year'] as int?,
      appStart: _date(r['application_start']),
      appEnd: _date(r['application_end']),
      docDeadline: _date(r['document_deadline']),
      topikMin: r['topik_min_level'] as int?,
      interviewRequired: r['interview_required'] as bool?,
      englishAccepted: r['english_accepted'] as bool?,
    );
  }
}

/// What Guest Explore needs about approved admissions: the universities to
/// list, which intake years each is approved for, and the detail block for its
/// card.
class ApprovedAdmissions {
  /// The universities to list, built from this view rather than from
  /// `v_institutions_for_map`.
  ///
  /// That view is gated on `is_visible_on_map`, which is false for 10
  /// institutions that do have published admission data — Dong Seoul alone has
  /// 14 cycles. On a screen whose whole promise is "the universities we have
  /// researched", a map-visibility flag is the wrong gate, and it silently
  /// withheld schools a student could apply to.
  final List<University> universities;

  /// institution id → approved intake years, ascending.
  final Map<String, List<int>> years;

  /// institution id → the detail for its most recent approved year.
  ///
  /// The card shows one block per university, so where an institution is
  /// approved for both 2026 and 2027 the newer year wins: a student reading a
  /// card today wants the intake still open to them.
  final Map<String, ApprovedUniDetail> details;

  /// The intake year each `details` entry was taken from, so the card can say
  /// which year a fee belongs to.
  final Map<String, int> detailYear;

  const ApprovedAdmissions({
    required this.universities,
    required this.years,
    required this.details,
    required this.detailYear,
  });

  static const empty = ApprovedAdmissions(
    universities: [],
    years: {},
    details: {},
    detailYear: {},
  );

  /// Whether this institution belongs in the list at the given year setting.
  ///
  /// A null `year` is the "Hammasi" chip and means **any approved year**, not
  /// "no filter": an institution with no approved year is never listed. The
  /// old reading — skip the check entirely when no year was chosen — is what
  /// put all 204 map-visible institutions on a screen that promises researched
  /// ones.
  bool isApprovedFor(String id, int? year) {
    final ys = years[id];
    if (ys == null || ys.isEmpty) return false;
    return year == null || ys.contains(year);
  }
}

/// Live read of `v_guest_approved_admissions`.
///
/// Anon-readable: Guest Explore runs before login. Sorted by year so the fold
/// below can take the last row per institution as the newest.
final approvedAdmissionsProvider = FutureProvider<ApprovedAdmissions>((
  ref,
) async {
  final rows = await Supabase.instance.client
      .from('v_guest_approved_admissions')
      .select(
        'institution_id, intake_year, '
        'name_ko, name_ko_short, name_en, name_uz, city_ko, tier, '
        'ieqas_status, is_partner, logo_url, '
        'tuition_academic_year, '
        'tuition_min_krw, tuition_max_krw, admission_fee_krw, '
        'application_start, application_end, document_deadline, '
        'topik_min_level, interview_required, english_accepted',
      )
      .order('intake_year', ascending: true);

  final years = <String, List<int>>{};
  final details = <String, ApprovedUniDetail>{};
  final detailYear = <String, int>{};
  final unis = <String, University>{};

  for (final row in rows as List) {
    final r = row as Map<String, dynamic>;
    final id = r['institution_id'] as String?;
    final year = r['intake_year'] as int?;
    if (id == null || year == null) continue;

    (years[id] ??= <int>[]).add(year);
    // Ascending order means each later row for the same institution overwrites
    // the earlier one, leaving the newest year's detail.
    details[id] = ApprovedUniDetail.fromRow(r);
    detailYear[id] = year;
    unis[id] ??= _university(id, r);
  }

  // Top tier first, then by name, so the list opens on the schools a student
  // is most likely to be weighing.
  final list = unis.values.toList()
    ..sort((a, b) {
      final at = a.tier ?? 99;
      final bt = b.tier ?? 99;
      return at != bt ? at.compareTo(bt) : a.name.compareTo(b.name);
    });

  return ApprovedAdmissions(
    universities: list,
    years: years,
    details: details,
    detailYear: detailYear,
  );
});

/// Build the catalogue entry from a view row.
///
/// Name resolution mirrors `map_repository`: English, then Uzbek, then the
/// short Korean, then Korean, with its 'South Korea' placeholder when the
/// catalogue has no `city_ko` — so a card reads the same whichever view built
/// it.
University _university(String id, Map<String, dynamic> r) {
  final nameEn = r['name_en'] as String?;
  final nameUz = r['name_uz'] as String?;
  final nameKo = r['name_ko'] as String?;
  final nameKoShort = r['name_ko_short'] as String?;
  final cityKo = r['city_ko'] as String?;

  return University(
    id: id,
    name: (nameEn?.isNotEmpty ?? false)
        ? nameEn!
        : (nameUz?.isNotEmpty ?? false)
            ? nameUz!
            : (nameKoShort?.isNotEmpty ?? false)
                ? nameKoShort!
                : nameKo ?? 'Unknown Institution',
    // 'South Korea' is the literal map_repository substitutes when `city_ko`
    // is null; matched here so a card built from this view reads the same as
    // one built from the map view.
    location: (cityKo?.isNotEmpty ?? false) ? cityKo! : 'South Korea',
    nameKo: nameKo,
    nameKoShort: nameKoShort,
    nameEn: nameEn,
    nameUz: nameUz,
    logoUrl: r['logo_url'] as String?,
    tier: r['tier'] as int?,
    ieqasStatus: r['ieqas_status'] as String?,
    isPartner: (r['is_partner'] as bool?) ?? false,
  );
}
