import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/application.dart';
import '../../map/domain/university.dart';
import '../data/applications_repository.dart';
import 'university_draft_provider.dart';

class ApplicationsTabState {
  final List<StudentApplication> applications;
  final List<University> suggestions;

  const ApplicationsTabState({
    required this.applications,
    required this.suggestions,
  });

  bool get hasActiveApplications => applications.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;

  List<StudentApplication> get pendingApps =>
      applications.where((app) => app.status == 'pending_approval').toList();

  List<StudentApplication> get activeApps =>
      applications.where((app) => app.status != 'pending_approval').toList();

  int get maxAllowedApplications => kMaxUniversityPicks;

  /// Slots still free given the student's existing applications. Used
  /// by the draft notifier to cap how many new picks they can add.
  int get remainingSlots =>
      (maxAllowedApplications - applications.length).clamp(0, maxAllowedApplications);

  bool get shouldShowSuggestions =>
      suggestions.isNotEmpty && applications.length < maxAllowedApplications;

  // isEmpty ONLY when there are no applications AND no suggestions to show
  // i.e., the student has nothing at all — no pending, no active, no suggestions
  bool get isEmpty => applications.isEmpty && suggestions.isEmpty;
}

final applicationsTabProvider = FutureProvider.autoDispose<ApplicationsTabState>((ref) async {
  // Fetch both concurrently to avoid race conditions and UI flickering
  final results = await Future.wait([
    ref.watch(applicationsProvider.future),
    ref.watch(suggestedUniversitiesProvider.future),
  ]);

  return ApplicationsTabState(
    applications: results[0] as List<StudentApplication>,
    suggestions: results[1] as List<University>,
  );
});
