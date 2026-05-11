// File deprecated 2026-05-10 (audit P2 #F16).
//
// `InterviewFeedbackView` was defined but never referenced anywhere in
// the app — the real post-session screen is `InterviewAnalyticsView`.
// Stubbed to a no-op so any stragglers that import it still compile.
//
// **Delete this file entirely on the Windows side** when convenient.
// The build sandbox is mounted read-only-for-delete so the file
// couldn't be unlinked from here.

import 'package:flutter/widgets.dart';

@Deprecated('InterviewFeedbackView removed 2026-05-10 — use InterviewAnalyticsView. Delete this file.')
class InterviewFeedbackView extends StatelessWidget {
  const InterviewFeedbackView({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
