/// Row shape from `v_user_upcoming_deadlines` (plan §H.5).
class UpcomingDeadline {
  const UpcomingDeadline({
    required this.institutionId,
    required this.nameKo,
    this.nameEn,
    required this.eventType,
    required this.startsAt,
    this.applicantCategory,
    this.cycleTrack,
    this.notesKo,
  });

  factory UpcomingDeadline.fromMap(Map<String, dynamic> map) =>
      UpcomingDeadline(
        institutionId: map['institution_id'] as String,
        nameKo: map['name_ko'] as String? ?? '',
        nameEn: map['name_en'] as String?,
        eventType: map['event_type'] as String? ?? '',
        startsAt: DateTime.parse(map['starts_at'].toString()),
        applicantCategory: map['applicant_category'] as String?,
        cycleTrack: map['cycle_track'] as String?,
        notesKo: map['notes_ko'] as String?,
      );

  final String institutionId;
  final String nameKo;
  final String? nameEn;
  final String eventType;
  final DateTime startsAt;
  final String? applicantCategory;
  final String? cycleTrack;
  final String? notesKo;
}
