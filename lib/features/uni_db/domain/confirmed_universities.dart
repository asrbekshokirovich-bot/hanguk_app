/// Universities with **approved** admission data in the Hanguk review system,
/// grouped by intake year. Names are copied verbatim from the `institutions`
/// table (name_en / name_ko) so they match the rest of the app exactly.
///
/// Source: Supabase `admission_cycles` ⋈ `institutions` where the cycle is not
/// superseded, for intake years 2026 and 2027 (snapshot).
library;

class ConfirmedUniversity {
  final String nameEn;
  final String nameKo;
  const ConfirmedUniversity(this.nameEn, this.nameKo);
}

class ConfirmedUniversities {
  ConfirmedUniversities._();

  /// 2026 intake — 7 universities.
  static const List<ConfirmedUniversity> y2026 = [
    ConfirmedUniversity('Baekseok University', '백석대학교'),
    ConfirmedUniversity('Catholic University of Korea', '가톨릭대학교'),
    ConfirmedUniversity('Hallym University', '한림대학교'),
    ConfirmedUniversity(
      'Seoul National University of Science and Technology',
      '서울과학기술대학교',
    ),
    ConfirmedUniversity("Sookmyung Women's University", '숙명여자대학교'),
    ConfirmedUniversity("Sungshin Women's University", '성신여자대학교'),
    ConfirmedUniversity('Yeungnam University', '영남대학교'),
  ];

  /// 2027 intake — 41 universities.
  static const List<ConfirmedUniversity> y2027 = [
    ConfirmedUniversity('ACTS University', '아신대학교'),
    ConfirmedUniversity('Ajou University', '아주대학교'),
    ConfirmedUniversity('Baekseok University', '백석대학교'),
    ConfirmedUniversity('Busan Presbyterian University', '부산장신대학교'),
    ConfirmedUniversity('Catholic University of Korea', '가톨릭대학교'),
    ConfirmedUniversity('Changwon National University', '창원대학교'),
    ConfirmedUniversity('Chung-Ang University', '중앙대학교'),
    ConfirmedUniversity('Dongguk University', '동국대학교'),
    ConfirmedUniversity("Duksung Women's University", '덕성여자대학교'),
    ConfirmedUniversity('Eulji University', '을지대학교'),
    ConfirmedUniversity('Gimcheon University', '김천대학교'),
    ConfirmedUniversity('Halla University', '한라대학교'),
    ConfirmedUniversity('Hallym University', '한림대학교'),
    ConfirmedUniversity('Hanseo University', '한서대학교'),
    ConfirmedUniversity('Hanyang Cyber University', '한양사이버대학교'),
    ConfirmedUniversity('Inha University', '인하대학교'),
    ConfirmedUniversity('Jeju National University', '제주대학교'),
    ConfirmedUniversity('KAIST', '한국과학기술원'),
    ConfirmedUniversity('Kkottongnae University', '가톨릭꽃동네대학교'),
    ConfirmedUniversity('Kongju National University', '공주대학교'),
    ConfirmedUniversity('Konyang University', '건양대학교'),
    ConfirmedUniversity('Korea Aerospace University', '한국항공대학교'),
    ConfirmedUniversity('Korea National Sport University', '한국체육대학교'),
    ConfirmedUniversity('Korea National University of Education', '한국교원대학교'),
    ConfirmedUniversity('Korea University', '고려대학교'),
    ConfirmedUniversity('Kumoh National Institute of Technology', '국립금오공과대학교'),
    ConfirmedUniversity('Kwangwoon University', '광운대학교'),
    ConfirmedUniversity('Kyungdong University', '경동대학교'),
    ConfirmedUniversity('Methodist Theological University', '감리교신학대학교'),
    ConfirmedUniversity('Mokpo National Maritime University', '목포해양대학교'),
    ConfirmedUniversity('Myongji College', '명지전문대학'),
    ConfirmedUniversity('Pusan National University', '부산대학교'),
    ConfirmedUniversity('Sangmyung University', '상명대학교'),
    ConfirmedUniversity('Sejong University', '세종대학교'),
    ConfirmedUniversity("Seoul Women's University", '서울여자대학교'),
    ConfirmedUniversity("Sookmyung Women's University", '숙명여자대학교'),
    ConfirmedUniversity('Soongsil University', '숭실대학교'),
    ConfirmedUniversity("Sungshin Women's University", '성신여자대학교'),
    ConfirmedUniversity('Ulsan College', '울산과학대학교'),
    ConfirmedUniversity('Yeungnam University', '영남대학교'),
    ConfirmedUniversity('Yonsei University', '연세대학교'),
  ];
}
