import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/interview_repository.dart';
import '../../../../design_system/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'interview_analytics_view.dart';

class InterviewHistoryView extends ConsumerStatefulWidget {
  const InterviewHistoryView({super.key});

  @override
  ConsumerState<InterviewHistoryView> createState() => _InterviewHistoryViewState();
}

class _InterviewHistoryViewState extends ConsumerState<InterviewHistoryView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await ref.read(interviewProvider.notifier).getSessionHistory();
    if (mounted) {
      setState(() {
        _sessions = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundNavy,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Interview History',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.vibrantLime))
                  : _sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 64, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text('No past interviews found.', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHistory,
                          color: AppColors.vibrantLime,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: _sessions.length,
                            itemBuilder: (context, index) {
                              final session = _sessions[index];
                              return _buildSessionCard(session);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    String uniName = 'Unknown Target';
    // Phase 3R-B renamed the FK column from `target_university_id` to
    // `target_institution_id`; the embed-relation alias in
    // InterviewNotifier.getSessionHistory() now reads `institution`.
    // Accept either alias for backwards compatibility with any cached
    // responses still in flight.
    final inst = (session['institution'] as Map?) ??
        (session['universities'] as Map?);
    if (inst != null) {
      final en = inst['name_en'] as String?;
      final ko = inst['name_ko'] as String?;
      uniName = (en != null && en.isNotEmpty)
          ? en
          : ((ko != null && ko.isNotEmpty) ? ko : 'Unknown University');
    }

    final createdAt = DateTime.parse(session['created_at']).toLocal();
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(createdAt);
    final isCompleted = session['status'] == 'completed';

    return GestureDetector(
      onTap: () {
        if (isCompleted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InterviewAnalyticsView(
                overrideSessionId: session['id'],
                overrideVapiCallId: session['vapi_call_id'] as String?,
                onBackPressed: () => Navigator.pop(context),
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGlass),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.greenAccent.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_outline : Icons.pending_outlined,
                color: isCompleted ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uniName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
