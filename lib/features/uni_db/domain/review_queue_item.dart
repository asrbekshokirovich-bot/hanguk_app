/// One pending review-queue row from `v_review_queue_dashboard`.
///
/// Pure data class — no Flutter imports.
class ReviewQueueItem {
  const ReviewQueueItem({
    required this.id,
    required this.targetTable,
    required this.targetId,
    required this.priority,
    required this.queuedAt,
    required this.payload,
    this.institutionNameKo,
    this.institutionNameKoShort,
    this.archetype,
    this.fieldGroup,
    this.documentId,
    this.pdfSignedUrl,
    this.slaDeadline,
    this.assignedReviewerId,
  });

  factory ReviewQueueItem.fromMap(Map<String, dynamic> map) => ReviewQueueItem(
        id: map['id'] as String,
        targetTable: map['target_table'] as String? ?? '',
        targetId: map['target_id'] as String? ?? '',
        priority: (map['priority'] as num?)?.toInt() ?? 5,
        queuedAt: DateTime.tryParse(map['queued_at']?.toString() ?? '') ?? DateTime.now(),
        payload: (map['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        institutionNameKo: map['institution_name_ko'] as String?,
        institutionNameKoShort: map['institution_name_ko_short'] as String?,
        archetype: map['archetype'] as String?,
        fieldGroup: map['field_group'] as String?,
        documentId: map['document_id'] as String?,
        pdfSignedUrl: map['pdf_signed_url'] as String?,
        slaDeadline: map['sla_deadline'] != null
            ? DateTime.tryParse(map['sla_deadline'].toString())
            : null,
        assignedReviewerId: map['assigned_reviewer_id'] as String?,
      );

  final String id;
  final String targetTable;
  final String targetId;
  final int priority; // 1..5; 1 highest
  final DateTime queuedAt;
  final Map<String, dynamic> payload;
  final String? institutionNameKo;
  final String? institutionNameKoShort;
  final String? archetype;
  final String? fieldGroup;
  final String? documentId;
  final String? pdfSignedUrl;
  final DateTime? slaDeadline;
  final String? assignedReviewerId;

  /// Convenience: priority label per ADR-005 SLA grid.
  String get priorityLabel => switch (priority) {
        1 => 'P1 — correction notice (4h)',
        2 => 'P2 — attachment change (12h)',
        3 => 'P3 — D3 field with diff (24h)',
        4 => 'P4 — D2 routine (48h)',
        _ => 'P5 — D1 trivial (96h)',
      };

  bool get isOverdue =>
      slaDeadline != null && slaDeadline!.isBefore(DateTime.now());
}
