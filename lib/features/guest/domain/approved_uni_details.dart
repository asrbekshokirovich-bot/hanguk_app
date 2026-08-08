/// Approved admission details per institution, sourced ONLY from Hanguk's
/// approved review data (Supabase: admission_cycles / tuition /
/// university_admission_periods / requirements, non-superseded 2026–2027).
///
/// Snapshot copied verbatim from the DB; keyed by institution id (matches
/// `University.id`). Null fields mean the approved review did not provide that
/// value. Shown read-only in the Guest Explorer cards.
library;

class ApprovedUniDetail {
  final int? tuitionMinKrw;
  final int? tuitionMaxKrw;
  final int? admissionFeeKrw;
  final String? appStart; // application opens (YYYY-MM-DD)
  final String? appEnd; // application closes
  final String? docDeadline; // documents deadline
  final int? topikMin; // minimum TOPIK level
  final bool? interviewRequired;
  final bool? englishAccepted; // English test accepted in lieu of / with TOPIK

  const ApprovedUniDetail({
    this.tuitionMinKrw,
    this.tuitionMaxKrw,
    this.admissionFeeKrw,
    this.appStart,
    this.appEnd,
    this.docDeadline,
    this.topikMin,
    this.interviewRequired,
    this.englishAccepted,
  });

  bool get hasAny =>
      tuitionMinKrw != null ||
      appStart != null ||
      appEnd != null ||
      docDeadline != null ||
      topikMin != null ||
      interviewRequired != null ||
      englishAccepted != null;
}

/// Institution-id → intake years the university is approved for (2026/2027).
/// 2026: 7 universities · 2027: 41 · 42 distinct.
const Map<String, List<int>> approvedYears = {
  // both 2026 & 2027
  'aa85fe0e-82b0-4abb-80c3-e80e429193ce': [2026, 2027], // Baekseok
  '6d00a5a8-8ea2-4e67-ac72-01823a313d0a': [2026, 2027], // Hallym
  '4c24796c-5078-435c-8b1b-774c0f88394f': [2026, 2027], // Yeungnam
  '4a8d2576-6aa1-41bb-bc4b-d4f1377bdbbc': [2026, 2027], // Catholic Univ of Korea
  'c5ca77ce-7f06-4e2a-8057-96bf441582c0': [2026, 2027], // Sookmyung Women's
  '6cf8889a-91ee-4385-a5cd-be761792ad08': [2026, 2027], // Sungshin Women's
  // 2026 only
  '16038490-c33c-4177-9d82-e29edfeffb01': [2026], // Seoul Nat Univ of S&T
  // 2027 only
  'efdacd89-8eb0-4798-86dc-746dce7f2f05': [2027], // Kkottongnae
  'b0f8d5eb-344f-4bf2-87df-6510e7dba8c5': [2027], // Korea Aerospace
  'a909788e-5ab0-4fbc-b70f-fb01a385e17e': [2027], // Seoul Women's
  '36319c54-8219-4595-b064-a4a69a57738c': [2027], // Sangmyung
  '969eadd3-7c3c-45cb-b861-f21c3a5d30f1': [2027], // Hanseo
  'e7dc9c20-1a85-475d-bc00-983d7ef299c1': [2027], // Kongju National
  '173c6b2f-a890-43ea-8797-745e00330bcb': [2027], // Eulji
  '44444444-4444-4444-4444-444444444444': [2027], // Korea University
  '22222222-2222-2222-2222-222222222222': [2027], // Yonsei
  'a38e0ca9-856b-4a8b-9a86-4ee1b00a38e4': [2027], // Korea National Sport
  '2ed00bc7-9b24-4c8c-b305-be38f7486364': [2027], // Kumoh
  '0b88b3f0-c854-4b2b-b8a2-262e2ae11ddf': [2027], // Chung-Ang
  'a79aab64-8ad7-4b96-8d60-dd7664822446': [2027], // Kyungdong
  '9f633866-b1f2-424a-b2a3-a03b748c12b5': [2027], // Soongsil
  '33333333-3333-3333-3333-333333333333': [2027], // KAIST
  '981124c6-2aa2-4ccb-aea9-8072820f8182': [2027], // Pusan National
  '133b236f-fa24-4295-afd7-5de2463793f1': [2027], // ACTS
  '4ef85fa9-4810-4587-a1f6-05193417fbef': [2027], // Kwangwoon
  '11a05167-afa3-4e6b-bc63-034d2672f4fa': [2027], // Halla
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa': [2027], // Jeju National
  'c8ab7972-f64d-4e4c-aca4-cc65ccd9681e': [2027], // Ajou
  '5cb91654-78c9-4eda-8ed2-25db16ad319e': [2027], // Korea Nat Univ of Education
  '849dd52c-7590-4c20-82c8-7d103cdb9a8c': [2027], // Myongji College
  'f8614cb9-8c88-4abc-b0d4-de16dd0ee135': [2027], // Dongguk
  'fba5736b-7a16-47ea-8620-057cd54ddcfc': [2027], // Changwon National
  '1c21a12a-3fc5-455b-858c-78a4b9ecf591': [2027], // Konyang
  '556d0c9f-70b7-48ff-9e95-a0dde979daf9': [2027], // Ulsan College
  '32a5a6cb-9389-496a-96ea-5d6c57a3b0d0': [2027], // Gimcheon
  '7631a149-4f3d-4a1e-a379-e6499596bb8f': [2027], // Duksung Women's
  'e427db9e-c4ec-40d4-8287-5a4592418026': [2027], // Mokpo National Maritime
  'd5b21df7-240d-465c-8a4c-51b0d5c9c933': [2027], // Busan Presbyterian
  '6fe9ef94-3a54-47b3-b9fd-5752880638f5': [2027], // Methodist Theological
  '88888888-8888-8888-8888-888888888888': [2027], // Inha
  '694d7fa4-a402-4122-81eb-1906d320bb66': [2027], // Sejong
  '7df46afe-292c-4620-a031-6372b62146f6': [2027], // Hanyang Cyber
};

/// Institution-id → approved details. Only institutions with at least one
/// approved value are listed.
const Map<String, ApprovedUniDetail> approvedUniDetails = {
  'c8ab7972-f64d-4e4c-aca4-cc65ccd9681e': ApprovedUniDetail(appStart: '2026-07-06', appEnd: '2026-07-10', docDeadline: '2026-07-14', interviewRequired: true, englishAccepted: false), // Ajou
  'aa85fe0e-82b0-4abb-80c3-e80e429193ce': ApprovedUniDetail(docDeadline: '2026-07-17', topikMin: 3, interviewRequired: true, englishAccepted: false), // Baekseok
  'd5b21df7-240d-465c-8a4c-51b0d5c9c933': ApprovedUniDetail(appStart: '2026-09-07', appEnd: '2026-09-11', docDeadline: '2026-09-18', topikMin: 3, interviewRequired: true, englishAccepted: false), // Busan Presbyterian
  '4a8d2576-6aa1-41bb-bc4b-d4f1377bdbbc': ApprovedUniDetail(appStart: '2026-07-07', appEnd: '2026-07-10', docDeadline: '2026-07-14', topikMin: 3, interviewRequired: true, englishAccepted: true), // Catholic Univ of Korea
  'fba5736b-7a16-47ea-8620-057cd54ddcfc': ApprovedUniDetail(appStart: '2026-09-07', appEnd: '2026-09-11', docDeadline: '2026-09-16', interviewRequired: true, englishAccepted: false), // Changwon National
  '0b88b3f0-c854-4b2b-b8a2-262e2ae11ddf': ApprovedUniDetail(tuitionMinKrw: 5124000, tuitionMaxKrw: 8468000, topikMin: 4, interviewRequired: true, englishAccepted: true), // Chung-Ang
  'f8614cb9-8c88-4abc-b0d4-de16dd0ee135': ApprovedUniDetail(appStart: '2026-09-07', appEnd: '2026-09-11', docDeadline: '2026-09-14', topikMin: 3, interviewRequired: false, englishAccepted: false), // Dongguk
  '173c6b2f-a890-43ea-8797-745e00330bcb': ApprovedUniDetail(appStart: '2026-09-07', appEnd: '2026-09-11', docDeadline: '2026-09-18'), // Eulji
  '32a5a6cb-9389-496a-96ea-5d6c57a3b0d0': ApprovedUniDetail(topikMin: 2, interviewRequired: true, englishAccepted: false), // Gimcheon
  '11a05167-afa3-4e6b-bc63-034d2672f4fa': ApprovedUniDetail(topikMin: 3, interviewRequired: true, englishAccepted: false), // Halla
  '6d00a5a8-8ea2-4e67-ac72-01823a313d0a': ApprovedUniDetail(appStart: '2026-07-06', appEnd: '2026-07-10', docDeadline: '2026-07-10', interviewRequired: true, englishAccepted: false), // Hallym
  '969eadd3-7c3c-45cb-b861-f21c3a5d30f1': ApprovedUniDetail(appStart: '2026-06-22', appEnd: '2026-06-26', docDeadline: '2026-06-26', topikMin: 3, interviewRequired: false, englishAccepted: true), // Hanseo
  '7df46afe-292c-4620-a031-6372b62146f6': ApprovedUniDetail(appStart: '2026-06-01', appEnd: '2026-07-16', docDeadline: '2026-07-16', interviewRequired: false, englishAccepted: false), // Hanyang Cyber
  '88888888-8888-8888-8888-888888888888': ApprovedUniDetail(appStart: '2026-07-06', appEnd: '2027-07-09', interviewRequired: true, englishAccepted: false), // Inha
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa': ApprovedUniDetail(appStart: '2026-07-06', appEnd: '2026-07-09', docDeadline: '2026-07-15', topikMin: 4, interviewRequired: true, englishAccepted: true), // Jeju National
  '33333333-3333-3333-3333-333333333333': ApprovedUniDetail(appStart: '2026-11-10', appEnd: '2027-01-14', docDeadline: '2027-01-21', interviewRequired: true, englishAccepted: true), // KAIST
  'efdacd89-8eb0-4798-86dc-746dce7f2f05': ApprovedUniDetail(appStart: '2026-09-07', appEnd: '2026-09-11', docDeadline: '2026-09-18'), // Kkottongnae
  'e7dc9c20-1a85-475d-bc00-983d7ef299c1': ApprovedUniDetail(appStart: '2026-07-06', appEnd: '2026-07-10', docDeadline: '2026-07-24'), // Kongju National
  '1c21a12a-3fc5-455b-858c-78a4b9ecf591': ApprovedUniDetail(topikMin: 3, interviewRequired: true, englishAccepted: false), // Konyang
  'b0f8d5eb-344f-4bf2-87df-6510e7dba8c5': ApprovedUniDetail(appStart: '2025-07-07', appEnd: '2025-07-11', docDeadline: '2025-08-06', interviewRequired: false, englishAccepted: false), // Korea Aerospace
  'a38e0ca9-856b-4a8b-9a86-4ee1b00a38e4': ApprovedUniDetail(appStart: '2025-12-29', appEnd: '2025-12-31', docDeadline: '2025-12-31'), // Korea National Sport
  '5cb91654-78c9-4eda-8ed2-25db16ad319e': ApprovedUniDetail(topikMin: 4, interviewRequired: false, englishAccepted: false), // Korea Nat Univ of Education
  '44444444-4444-4444-4444-444444444444': ApprovedUniDetail(appStart: '2026-03-09', appEnd: '2026-03-11', docDeadline: '2026-03-12', topikMin: 3, interviewRequired: false, englishAccepted: true), // Korea University
  '2ed00bc7-9b24-4c8c-b305-be38f7486364': ApprovedUniDetail(topikMin: 3, interviewRequired: false, englishAccepted: false), // Kumoh
  '4ef85fa9-4810-4587-a1f6-05193417fbef': ApprovedUniDetail(interviewRequired: true, englishAccepted: false), // Kwangwoon
  'a79aab64-8ad7-4b96-8d60-dd7664822446': ApprovedUniDetail(appStart: '2026-03-01', appEnd: '2026-08-31', docDeadline: '2026-08-31'), // Kyungdong
  '6fe9ef94-3a54-47b3-b9fd-5752880638f5': ApprovedUniDetail(appStart: '2026-09-07', appEnd: '2027-01-04', docDeadline: '2027-01-08', topikMin: 4, interviewRequired: true, englishAccepted: false), // Methodist Theological
  'e427db9e-c4ec-40d4-8287-5a4592418026': ApprovedUniDetail(topikMin: 3, interviewRequired: true, englishAccepted: false), // Mokpo National Maritime
  '849dd52c-7590-4c20-82c8-7d103cdb9a8c': ApprovedUniDetail(appStart: '2026-11-09', appEnd: '2026-11-20', docDeadline: '2026-11-27', topikMin: 2, interviewRequired: true, englishAccepted: false), // Myongji College
  '981124c6-2aa2-4ccb-aea9-8072820f8182': ApprovedUniDetail(topikMin: 3, interviewRequired: false, englishAccepted: true), // Pusan National
  '36319c54-8219-4595-b064-a4a69a57738c': ApprovedUniDetail(appStart: '2026-07-06', appEnd: '2026-07-10', docDeadline: '2026-07-14', interviewRequired: true, englishAccepted: false), // Sangmyung
  '694d7fa4-a402-4122-81eb-1906d320bb66': ApprovedUniDetail(appStart: '2026-07-06', appEnd: '2026-07-09', docDeadline: '2026-07-10', interviewRequired: false, englishAccepted: false), // Sejong
  '16038490-c33c-4177-9d82-e29edfeffb01': ApprovedUniDetail(appStart: '2026-07-06', appEnd: '2026-07-10', docDeadline: '2026-07-10'), // Seoul Nat Univ of S&T
  'a909788e-5ab0-4fbc-b70f-fb01a385e17e': ApprovedUniDetail(appStart: '2026-07-07', appEnd: '2026-07-10', docDeadline: '2026-07-13', interviewRequired: false, englishAccepted: false), // Seoul Women's
  'c5ca77ce-7f06-4e2a-8057-96bf441582c0': ApprovedUniDetail(appStart: '2026-07-07', appEnd: '2026-07-09', docDeadline: '2026-07-10', interviewRequired: true, englishAccepted: true), // Sookmyung Women's
  '9f633866-b1f2-424a-b2a3-a03b748c12b5': ApprovedUniDetail(appStart: '2026-07-07', appEnd: '2026-07-10', docDeadline: '2026-07-10', interviewRequired: false, englishAccepted: false), // Soongsil
  '6cf8889a-91ee-4385-a5cd-be761792ad08': ApprovedUniDetail(appStart: '2026-07-08', appEnd: '2026-07-10', docDeadline: '2026-07-11', interviewRequired: true, englishAccepted: false), // Sungshin Women's
  '556d0c9f-70b7-48ff-9e95-a0dde979daf9': ApprovedUniDetail(tuitionMinKrw: 2870000, tuitionMaxKrw: 3667000, appStart: '2026-09-07', appEnd: '2027-07-16', docDeadline: '2027-07-16', topikMin: 2, interviewRequired: true, englishAccepted: true), // Ulsan College
  '4c24796c-5078-435c-8b1b-774c0f88394f': ApprovedUniDetail(appStart: '2026-09-07', appEnd: '2026-09-09', docDeadline: '2026-09-17', topikMin: 3, interviewRequired: false, englishAccepted: false), // Yeungnam
};
