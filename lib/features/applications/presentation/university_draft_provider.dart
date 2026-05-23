import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../map/domain/university.dart';

/// Maximum universities a student can have in flight at once
/// (combined: existing applications + draft selections).
const int kMaxUniversityPicks = 3;

/// Central draft of universities the student has marked but not yet
/// submitted. Both the Map tab (discovery) and the Applications tab
/// (suggestions) read and write through this notifier, so a pick made
/// in one place is reflected in the other instantly.
class UniversityDraftNotifier extends StateNotifier<List<University>> {
  UniversityDraftNotifier() : super(const []);

  bool contains(String id) => state.any((u) => u.id == id);

  /// Returns false when the cap would be exceeded — caller decides how
  /// to surface that (snackbar, disabled state, etc).
  bool add(University u, {int remainingSlots = kMaxUniversityPicks}) {
    if (contains(u.id)) return true;
    if (state.length >= remainingSlots) return false;
    state = [...state, u];
    return true;
  }

  void remove(String id) {
    state = state.where((u) => u.id != id).toList();
  }

  void toggle(University u, {int remainingSlots = kMaxUniversityPicks}) {
    if (contains(u.id)) {
      remove(u.id);
    } else {
      add(u, remainingSlots: remainingSlots);
    }
  }

  void clear() {
    state = const [];
  }
}

final universityDraftProvider =
    StateNotifierProvider<UniversityDraftNotifier, List<University>>(
  (ref) => UniversityDraftNotifier(),
);
