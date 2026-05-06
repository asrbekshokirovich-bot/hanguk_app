import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/adaptive/hanguk_scaffold.dart';
import '../data/interview_repository.dart';

import 'widgets/interview_setup_view.dart';
import 'widgets/interview_active_view.dart';
import 'widgets/interview_analytics_view.dart';
import 'widgets/interview_history_view.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  /// Optional initial configuration passed from the TrainingTab dialog.
  /// When provided, the session starts automatically in initState so the
  /// user sees the interview screen immediately (no dialog blocking).
  final String? initialSessionType;
  final String? initialUniversityId;
  final String? initialUniversityName;
  final String? initialLanguage;

  const InterviewScreen({
    super.key,
    this.initialSessionType,
    this.initialUniversityId,
    this.initialUniversityName,
    this.initialLanguage,
  });

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen> {
  bool _showAnalytics = false;

  @override
  void initState() {
    super.initState();
    // If launched from the training tab dialog with pre-filled config,
    // start the session immediately so users don't wait in a blocked dialog.
    if (widget.initialUniversityId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(interviewProvider.notifier).startSession(
          sessionType: widget.initialSessionType ?? 'university_specific',
          targetUniversityId: widget.initialUniversityId,
          targetUniversityName: widget.initialUniversityName,
          language: widget.initialLanguage ?? 'ko',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewProvider);

    return HangukScaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Interview Practice'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (state.status == 'active')
            TextButton(
              onPressed: () async {
                await ref.read(interviewProvider.notifier).endSession(
                  language: state.selectedLanguage,
                );
                // Note: Vapi call cleanup is handled by InterviewActiveView.dispose()
                // via the centralized _stopCall() method.
              },
              child: const Text('End Session', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: SafeArea(
        child: _buildCurrentView(state),
      ),
    );
  }

  Widget _buildCurrentView(InterviewSessionState state) {
    if (state.status == 'idle') {
      // Loading state while startSession() runs after navigation
      if (state.isLoading) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.vibrantLime),
              SizedBox(height: 16),
              Text(
                'Setting up your interview...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      }
      return InterviewSetupView(
        onHistoryTapped: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InterviewHistoryView()),
          );
        },
      );
    } else if (state.status == 'completed') {
      // Analytics is the richer post-session view — overall + per-metric
      // scores, strengths/improvements, and the audio player for replaying
      // the recorded session. The simpler InterviewFeedbackView is reachable
      // separately if needed.
      return const InterviewAnalyticsView();
    } else {
      return const InterviewActiveView();
    }
  }
}
