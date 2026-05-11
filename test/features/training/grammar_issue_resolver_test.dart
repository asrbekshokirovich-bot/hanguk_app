import 'package:flutter_test/flutter_test.dart';
import 'package:hanguk_app/features/training/data/grammar_issue_resolver.dart';

void main() {
  group('resolveIssues', () {
    test('finds the first occurrence, not the last (audit A1)', () {
      const text = 'The cat sat on the mat and the cat slept.';
      final issues = resolveIssues(
        draftText: text,
        rawIssues: const [
          {'originalText': 'cat', 'suggestion': 'feline'},
        ],
      );
      expect(issues, hasLength(1));
      expect(text.substring(issues.single.start, issues.single.end), 'cat');
      // First "cat" is at index 4. Previous lastIndexOf version returned 30.
      expect(issues.single.start, 4);
    });

    test('two duplicate-word issues each map to a distinct occurrence', () {
      const text = 'cat cat cat';
      final issues = resolveIssues(
        draftText: text,
        rawIssues: const [
          {'originalText': 'cat', 'suggestion': 'one'},
          {'originalText': 'cat', 'suggestion': 'two'},
        ],
      );
      expect(issues, hasLength(2));
      expect(issues[0].start, 0);
      expect(issues[1].start, 4);
    });

    test('case-insensitive match preserves source casing', () {
      const text = 'I Like Cats.';
      final issues = resolveIssues(
        draftText: text,
        rawIssues: const [
          {'originalText': 'like', 'suggestion': 'love'},
        ],
      );
      expect(issues.single.originalText, 'Like');
      expect(issues.single.suggestion, 'love');
    });

    test('issues whose originalText is missing are skipped silently', () {
      const text = 'hello world';
      final issues = resolveIssues(
        draftText: text,
        rawIssues: const [
          {'originalText': '', 'suggestion': 'noop'},
          {'originalText': 'world', 'suggestion': 'earth'},
        ],
      );
      expect(issues, hasLength(1));
      expect(issues.single.originalText, 'world');
    });

    test('issues that do not appear in the draft are dropped', () {
      const text = 'hello world';
      final issues = resolveIssues(
        draftText: text,
        rawIssues: const [
          {'originalText': 'goodbye', 'suggestion': 'farewell'},
        ],
      );
      expect(issues, isEmpty);
    });
  });
}
