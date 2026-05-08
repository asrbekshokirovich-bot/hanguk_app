import 'package:flutter_test/flutter_test.dart';
import 'package:hanguk_app/features/uni_db/domain/review_queue_item.dart';

void main() {
  group('ReviewQueueItem.fromMap', () {
    test('parses every field from a fully-populated row', () {
      final map = {
        'id': 'q1',
        'target_table': 'recruitment_units',
        'target_id': 't1',
        'priority': 1,
        'queued_at': '2026-05-08T10:00:00Z',
        'payload': {'foo': 'bar'},
        'institution_name_ko': '서울대학교',
        'institution_name_ko_short': 'SNU',
        'archetype': 'A',
        'field_group': 'calendar',
        'document_id': 'd1',
        'pdf_signed_url': 'https://example/pdf',
        'sla_deadline': '2026-05-08T14:00:00Z',
        'assigned_reviewer_id': 'u1',
      };

      final item = ReviewQueueItem.fromMap(map);

      expect(item.id, 'q1');
      expect(item.targetTable, 'recruitment_units');
      expect(item.priority, 1);
      expect(item.queuedAt, DateTime.utc(2026, 5, 8, 10));
      expect(item.payload, {'foo': 'bar'});
      expect(item.institutionNameKoShort, 'SNU');
      expect(item.archetype, 'A');
      expect(item.fieldGroup, 'calendar');
      expect(item.pdfSignedUrl, 'https://example/pdf');
      expect(item.slaDeadline, DateTime.utc(2026, 5, 8, 14));
    });

    test('defaults priority to 5 when missing', () {
      final item = ReviewQueueItem.fromMap({
        'id': 'q2',
        'target_table': 'recruitment_units',
        'target_id': 't2',
        'queued_at': '2026-05-08T10:00:00Z',
      });
      expect(item.priority, 5);
    });

    test('defaults payload to empty map when missing', () {
      final item = ReviewQueueItem.fromMap({
        'id': 'q3',
        'target_table': 'recruitment_units',
        'target_id': 't3',
        'queued_at': '2026-05-08T10:00:00Z',
      });
      expect(item.payload, isEmpty);
    });

    test('queuedAt fallback to now() when malformed', () {
      final before = DateTime.now();
      final item = ReviewQueueItem.fromMap({
        'id': 'q4',
        'target_table': 'recruitment_units',
        'target_id': 't4',
        'queued_at': 'not-a-date',
      });
      // Fallback is DateTime.now(); just confirm it's recent.
      expect(item.queuedAt.isAfter(before.subtract(const Duration(seconds: 5))), isTrue);
    });
  });

  group('ReviewQueueItem.priorityLabel', () {
    test('P1 carries the 4-hour SLA copy', () {
      final item = _itemWithPriority(1);
      expect(item.priorityLabel, contains('P1'));
      expect(item.priorityLabel, contains('4h'));
    });

    test('P2 carries the 12-hour SLA copy', () {
      final item = _itemWithPriority(2);
      expect(item.priorityLabel, contains('P2'));
      expect(item.priorityLabel, contains('12h'));
    });

    test('P5 carries the 96-hour SLA copy', () {
      final item = _itemWithPriority(5);
      expect(item.priorityLabel, contains('P5'));
      expect(item.priorityLabel, contains('96h'));
    });

    test('out-of-range priority falls back to P5 label', () {
      final item = _itemWithPriority(99);
      expect(item.priorityLabel, contains('P5'));
    });
  });

  group('ReviewQueueItem.isOverdue', () {
    test('true when sla_deadline is in the past', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final item = ReviewQueueItem.fromMap({
        'id': 'q1',
        'target_table': 't',
        'target_id': 'i',
        'priority': 2,
        'queued_at': '2026-05-08T10:00:00Z',
        'sla_deadline': past.toIso8601String(),
      });
      expect(item.isOverdue, isTrue);
    });

    test('false when sla_deadline is in the future', () {
      final future = DateTime.now().add(const Duration(hours: 1));
      final item = ReviewQueueItem.fromMap({
        'id': 'q1',
        'target_table': 't',
        'target_id': 'i',
        'priority': 2,
        'queued_at': '2026-05-08T10:00:00Z',
        'sla_deadline': future.toIso8601String(),
      });
      expect(item.isOverdue, isFalse);
    });

    test('false when sla_deadline is null', () {
      final item = ReviewQueueItem.fromMap({
        'id': 'q1',
        'target_table': 't',
        'target_id': 'i',
        'priority': 2,
        'queued_at': '2026-05-08T10:00:00Z',
      });
      expect(item.isOverdue, isFalse);
    });
  });
}

ReviewQueueItem _itemWithPriority(int p) {
  return ReviewQueueItem.fromMap({
    'id': 'q1',
    'target_table': 't',
    'target_id': 'i',
    'priority': p,
    'queued_at': '2026-05-08T10:00:00Z',
  });
}
