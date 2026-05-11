import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../applications/data/applications_repository.dart';
import '../../home/presentation/home_tab_provider.dart';
import '../data/interview_repository.dart';
import 'study_plan_screen.dart';
import 'interview_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TrainingTab extends ConsumerWidget {
  const TrainingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Training Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prepare for your university applications with AI-guided training modules.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTrainingCard(
                      context,
                      title: 'Study Plan Builder',
                      description: 'Craft a compelling roadmap for your academic journey.',
                      icon: Icons.edit_document,
                      color: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudyPlanScreen(documentType: 'study_plan')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTrainingCard(
                      context,
                      title: 'Personal Statement',
                      description: 'Write effective and engaging personal essays.',
                      icon: Icons.person_search_rounded,
                      color: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudyPlanScreen(documentType: 'personal_statement')),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTrainingCard(
                      context,
                      title: 'Interview Preparation',
                      description: 'Practice mock questions and improve your confidence.',
                      icon: Icons.mic_rounded,
                      color: AppColors.vibrantLime,
                      isDarkIcon: true,
                      onTap: () => _showInterviewSetupDialog(context, ref),
                    ),
                    const SizedBox(height: 100), // padding for global FAB
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingCard(BuildContext context, {
    required String title, 
    required String description, 
    required IconData icon, 
    required Color color,
    bool isDarkIcon = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F213D).withOpacity(0.6), // deep glassmorphism
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.4),
                    color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.8), size: 16),
            ),
          ],
        ),
      ),
    );
  }
  void _showInterviewSetupDialog(BuildContext context, WidgetRef ref) {
    String selectedTrack = 'ko';
    String selectedPersona = 'friendly'; // audit F12 — was hardcoded
    String? selectedUniId;
    String? selectedUniName;

    // Audit U17: error from a previous attempt would persist in state and
    // render at the bottom of this dialog when re-opened, even though it
    // was no longer relevant. Clear it before showing.
    ref.read(interviewProvider.notifier).clearError();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final applicationsAsync = ref.watch(applicationsProvider);
            final interviewState = ref.watch(interviewProvider);

            return AlertDialog(
              backgroundColor: AppColors.backgroundNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Colors.white10),
              ),
              title: const Text(
                'Interview Preparation',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Select Target University', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    applicationsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.vibrantLime)),
                      error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                      data: (applications) {
                        if (applications.isEmpty) {
                          // Empty-state CTA: send the user to the Applications tab
                          // so they can add a university (the previous behaviour
                          // left "Start Interview" permanently disabled with no
                          // path forward — see INTERVIEW_QA_REPORT.md §1).
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white10),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withOpacity(0.02),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'No applications yet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add a target university first — interview '
                                  'practice tailors questions to that school.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.vibrantLime,
                                      foregroundColor: Colors.black,
                                    ),
                                    icon: const Icon(Icons.school, size: 18),
                                    label: const Text(
                                      'Apply to a university',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      // 0 = Applications tab in HomeScreen.
                                      ref.read(homeTabProvider.notifier).state = 0;
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Container(
                          height: 150,
                          width: double.maxFinite,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: applications.length,
                            itemBuilder: (context, i) {
                              final uni = applications[i].university;
                              if (uni == null) return const SizedBox.shrink();
                              final isSelected = selectedUniId == uni.id;
                              return ListTile(
                                dense: true,
                                title: Text(uni.name, style: TextStyle(color: isSelected ? AppColors.vibrantLime : Colors.white)),
                                leading: Icon(Icons.school, color: isSelected ? AppColors.vibrantLime : Colors.white24),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.vibrantLime) : null,
                                onTap: () => setDialogState(() {
                                  selectedUniId = uni.id;
                                  selectedUniName = uni.name;
                                }),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('2. Select Interview Track', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TrackChip(
                            label: 'Korean',
                            isSelected: selectedTrack == 'ko',
                            icon: Icons.translate,
                            onTap: () => setDialogState(() => selectedTrack = 'ko'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TrackChip(
                            label: 'English',
                            isSelected: selectedTrack == 'en',
                            icon: Icons.language,
                            onTap: () => setDialogState(() => selectedTrack = 'en'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Audit F12 — persona was previously hardcoded to
                    // 'friendly' on this entry path.
                    const Text(
                      '3. Interviewer Persona',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPersona,
                          isExpanded: true,
                          dropdownColor: AppColors.backgroundNavy,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: const [
                            DropdownMenuItem(
                              value: 'friendly',
                              child: Text('Friendly admissions officer'),
                            ),
                            DropdownMenuItem(
                              value: 'strict',
                              child: Text('Strict professor'),
                            ),
                            DropdownMenuItem(
                              value: 'impatient',
                              child: Text('Impatient visa officer'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedPersona = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (interviewState.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      interviewState.error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: interviewState.isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantLime,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: selectedUniId == null
                    ? null
                    : () async {
                      // Proactively request microphone synchronously within the button tap user gesture.
                      // On Web, browsers handle microphone natively during Vapi JS start, and permission_handler will crash.
                      if (!kIsWeb) {
                        final status = await Permission.microphone.request();
                        if (!status.isGranted && context.mounted) {
                          // Audit U16: if the user has permanently denied
                          // the permission, a snackbar alone is a dead
                          // end. Offer to deep-link them into the OS
                          // settings page where they can re-enable.
                          if (status.isPermanentlyDenied) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Microphone is blocked in system settings.',
                                ),
                                action: SnackBarAction(
                                  label: 'Open settings',
                                  onPressed: () => openAppSettings(),
                                ),
                                duration: const Duration(seconds: 6),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Microphone access is required for the interview.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                      }

                      // Reset any previous session state
                      ref.read(interviewProvider.notifier).resetSession();

                      // [FIXED] Navigate FIRST, then let InterviewScreen start the session.
                      // Previously, startSession() was awaited here, blocking the dialog UI
                      // for seconds. Now the user sees the interview screen immediately.
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InterviewScreen(
                              initialSessionType: 'university_specific',
                              initialUniversityId: selectedUniId,
                              initialUniversityName: selectedUniName,
                              initialLanguage: selectedTrack,
                              initialPersona: selectedPersona,
                            ),
                          ),
                        );
                      }
                    },
                  child: const Text('Start Interview', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TrackChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _TrackChip({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.vibrantLime : Colors.white24;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
