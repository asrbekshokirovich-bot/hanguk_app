import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../data/interview_repository.dart';

class InterviewFeedbackView extends ConsumerWidget {
  const InterviewFeedbackView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interviewProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(Icons.analytics, color: AppColors.vibrantLime, size: 64),
          ),
          const SizedBox(height: 24),
          const Text(
            'Interview Feedback',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (state.feedback != null) ...[
            _ScoreBar(label: 'Overall Score', score: state.feedback!['overall_score'] ?? 0),
            _ScoreBar(label: 'Confidence', score: state.feedback!['confidence_score'] ?? 0),
            _ScoreBar(label: 'Language', score: state.feedback!['language_score'] ?? 0),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(16)
              ),
              child: Text(
                state.feedback!['detailed_feedback'] ?? 'Great job.',
                style: const TextStyle(color: Colors.white70, height: 1.5),
              )
            )
          ] else
            const Text('No feedback data returned from server.', style: TextStyle(color: Colors.white54)),
            
          const SizedBox(height: 32),
          if (state.feedback != null && (state.feedback!['message_scores'] as List?)?.isNotEmpty == true)
            _buildTranscriptReplay(state),

          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
               // We reset session to go back to Setup
               ref.read(interviewProvider.notifier).resetSession();
            },
            child: const Text('Practice Again', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptReplay(InterviewSessionState state) {
    final studentMessages = state.messages.where((m) => m.role == 'student' && !m.content.contains('[Interview started')).toList();
    final messageScores = state.feedback!['message_scores'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Transcript & Fixes',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...List.generate(studentMessages.length, (index) {
          if (index >= messageScores.length) return const SizedBox.shrink();
          final msg = studentMessages[index];
          final scoreData = messageScores[index] as Map<String, dynamic>;
          final idealHint = scoreData['ideal_hint'] as String?;

          return _MessageFixCard(
            originalText: msg.content,
            idealHint: idealHint,
            score: scoreData['score'] ?? 0,
          );
        }),
      ],
    );
  }
}

class _MessageFixCard extends StatefulWidget {
  final String originalText;
  final String? idealHint;
  final num score;

  const _MessageFixCard({required this.originalText, this.idealHint, required this.score});

  @override
  State<_MessageFixCard> createState() => _MessageFixCardState();
}

class _MessageFixCardState extends State<_MessageFixCard> {
  bool _expanded = false;

  // Audit F17: the Edge Function has historically returned per-message
  // scores on a 0–10 scale while `_ScoreBar` (above) assumes 0–100. We
  // standardize on 0–100 by scaling small values up. A score that's
  // already 0–100 stays untouched.
  num get _scoreOn100 => widget.score <= 10 ? widget.score * 10 : widget.score;

  @override
  Widget build(BuildContext context) {
    final score100 = _scoreOn100;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: const Text('You said:',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            subtitle: Text(widget.originalText,
                style: const TextStyle(color: Colors.white)),
            trailing: CircleAvatar(
              backgroundColor:
                  score100 > 70 ? AppColors.vibrantLime : AppColors.warning,
              radius: 14,
              child: Text(
                '${score100.round()}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (widget.idealHint != null && widget.idealHint!.isNotEmpty) ...[
             InkWell(
               onTap: () => setState(() => _expanded = !_expanded),
               child: Container(
                 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                 decoration: BoxDecoration(
                   color: AppColors.royalBlue.withOpacity(0.1),
                   borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.auto_fix_high, color: AppColors.royalBlue, size: 16),
                     const SizedBox(width: 8),
                     const Text('Tap to see native fix', style: TextStyle(color: AppColors.royalBlue, fontWeight: FontWeight.bold)),
                     const Spacer(),
                     Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.royalBlue),
                   ],
                 ),
               ),
             ),
             if (_expanded)
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppColors.royalBlue.withOpacity(0.2),
                   borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                 ),
                 child: Text(
                   widget.idealHint!,
                   style: const TextStyle(color: Colors.white, height: 1.5),
                 ),
               ),
          ]
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final num score;

  const _ScoreBar({required this.label, required this.score});

  // Same normalization as `_MessageFixCard` (audit F17). Accept either
  // a 0–10 score (Edge Function legacy shape) or a 0–100 score.
  num get _scoreOn100 => score <= 10 ? score * 10 : score;

  @override
  Widget build(BuildContext context) {
    final s = _scoreOn100.clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: s / 100,
                minHeight: 8,
                backgroundColor: Colors.white10,
                color: s > 70 ? AppColors.vibrantLime : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${s.round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
