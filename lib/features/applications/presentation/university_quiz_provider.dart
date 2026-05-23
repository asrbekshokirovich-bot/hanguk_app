import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../map/domain/university.dart';

/// Lightweight student preferences captured by the 3-question quiz on
/// the Suggestions panel. Stored in-memory only — survives within a
/// session and is used to (a) order the suggested-universities list
/// and (b) annotate cards with "why this matches" chips.
///
/// We intentionally avoid persisting the answers to backend or local
/// storage in this phase: the questions are quick enough to re-answer,
/// and the privacy / consent story is simpler with in-memory state.
@immutable
class QuizPreferences {
  /// Empty string means "any". One of: '', 'seoul', 'busan', 'gyeonggi', 'other'.
  final String region;

  /// What the student cares about most. One of: '', 'top', 'partner', 'verified'.
  final String priority;

  /// Anything goes for now — the quiz can keep growing. Empty when
  /// the student has not answered any question yet.
  final bool hasAnswered;

  const QuizPreferences({
    this.region = '',
    this.priority = '',
    this.hasAnswered = false,
  });

  QuizPreferences copyWith({String? region, String? priority, bool? hasAnswered}) {
    return QuizPreferences(
      region: region ?? this.region,
      priority: priority ?? this.priority,
      hasAnswered: hasAnswered ?? this.hasAnswered,
    );
  }

  /// Returns the human-readable match reasons (already localized in
  /// English — wire l10n in once the strings settle). Used by both the
  /// suggestions card "Why this matches" chips and the Map's
  /// "Recommended" sort.
  List<String> matchReasonsFor(University u) {
    if (!hasAnswered) return const [];
    final reasons = <String>[];

    if (region.isNotEmpty && _regionMatches(u.location, region)) {
      reasons.add('Matches your region');
    }

    switch (priority) {
      case 'top':
        if (u.isTopTier) reasons.add('Top tier');
        break;
      case 'partner':
        if (u.isPartner) reasons.add('Partner university');
        break;
      case 'verified':
        if (u.isAccredited) reasons.add('Verified (IEQAS)');
        break;
    }
    return reasons;
  }

  /// Region matching is intentionally fuzzy — `location` is a free-text
  /// city label that may be "Seoul" / "서울" / "Seoul, Korea". We
  /// lowercase and check for a substring so the quiz works against
  /// the existing data without backend changes.
  static bool _regionMatches(String location, String region) {
    final loc = location.toLowerCase();
    switch (region) {
      case 'seoul':
        return loc.contains('seoul') || loc.contains('서울');
      case 'busan':
        return loc.contains('busan') || loc.contains('부산');
      case 'gyeonggi':
        return loc.contains('gyeonggi') ||
            loc.contains('suwon') ||
            loc.contains('incheon') ||
            loc.contains('경기') ||
            loc.contains('인천') ||
            loc.contains('수원');
      case 'other':
        // Anywhere outside the three big metros.
        return !loc.contains('seoul') &&
            !loc.contains('busan') &&
            !loc.contains('gyeonggi') &&
            !loc.contains('incheon') &&
            !loc.contains('suwon') &&
            !loc.contains('서울') &&
            !loc.contains('부산');
      default:
        return false;
    }
  }
}

class UniversityQuizNotifier extends StateNotifier<QuizPreferences> {
  UniversityQuizNotifier() : super(const QuizPreferences());

  void setRegion(String region) => state = state.copyWith(region: region);
  void setPriority(String priority) => state = state.copyWith(priority: priority);

  void finish() => state = state.copyWith(hasAnswered: true);

  void reset() => state = const QuizPreferences();
}

final universityQuizProvider =
    StateNotifierProvider<UniversityQuizNotifier, QuizPreferences>(
  (ref) => UniversityQuizNotifier(),
);
