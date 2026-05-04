import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/adaptive/hanguk_scaffold.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../applications/data/applications_repository.dart';
import '../data/study_plan_repository.dart';

import 'widgets/study_plan_chat_fab.dart';
import 'widgets/study_plan_analysis_view.dart';
import 'widgets/advanced_drafting_workspace.dart';

class StudyPlanScreen extends ConsumerStatefulWidget {
  final String documentType; // 'study_plan' or 'personal_statement'
  const StudyPlanScreen({super.key, required this.documentType});

  @override
  ConsumerState<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends ConsumerState<StudyPlanScreen> {
  final TextEditingController _draftController = TextEditingController();
  String? _exampleSelectedUniName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyPlanSessionProvider.notifier).fetchSessions(widget.documentType);
    });
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  String get documentTitle => widget.documentType == 'study_plan' 
    ? 'Study Plan Builder' 
    : 'Personal Statement';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentSessionProvider(widget.documentType));

    return HangukScaffold(
      appBar: AppBar(
        title: Text(documentTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (state.currentSession != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => ref.read(studyPlanSessionProvider.notifier).clearCurrentSession(widget.documentType),
            )
        ],
      ),
      body: SafeArea(
        child: state.isSessionsLoading && state.currentSession == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.vibrantLime))
            : state.currentSession == null
                ? _buildSessionList(state)
                : _buildSessionWizard(state),
      ),
      floatingActionButton: state.currentSession != null ? StudyPlanChatFab(documentType: widget.documentType) : null,
    );
  }

  Widget _buildSessionList(StudyPlanSessionState state) {
    final relevantSessions = state.sessions;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vibrantLime,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create New Session', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              _showCreateSessionDialog();
            },
          ),
          const SizedBox(height: 32),
          const Text('Your Saved Drafts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
             child: relevantSessions.isEmpty
              ? const Center(child: Text('No previous drafts found.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                 itemCount: relevantSessions.length,
                 itemBuilder: (context, i) {
                   final s = relevantSessions[i];
                   return ListTile(
                     contentPadding: EdgeInsets.zero,
                     leading: const Icon(Icons.edit_document, color: AppColors.royalBlue),
                     title: Text('${s.universityNameEn ?? 'General'} ${widget.documentType == 'study_plan' ? 'Study Plan' : 'Personal Statement'}', style: const TextStyle(color: Colors.white)),
                     subtitle: Text('Status: ${s.status}', style: const TextStyle(color: Colors.white54)),
                     trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppColors.backgroundNavy,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: Colors.white10),
                                  ),
                                  title: const Text('Delete Session', style: TextStyle(color: Colors.white)),
                                  content: const Text('Are you sure you want to delete this session? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        ref.read(studyPlanSessionProvider.notifier).deleteSession(widget.documentType, s.id);
                                      },
                                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
                       ]
                     ),
                     onTap: () {
                         ref.read(studyPlanSessionProvider.notifier).loadSession(widget.documentType, s.id).then((_) {
                             _draftController.text = ref.read(documentSessionProvider(widget.documentType)).draftContent;
                         });
                     },
                   );
                 },
              )
          ),
        ],
      )
    );
  }

  Widget _buildSessionWizard(StudyPlanSessionState state) {
     final session = state.currentSession!;
     
     return Column(
        children: [
           _buildStepper(session.currentStep),
           Expanded(
              child: _buildCurrentStep(state, session.currentStep)
           )
        ]
     );
  }

  Widget _buildStepper(int currentStep) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildStepIcon(1, currentStep, Icons.info_outline, 'Guide'),
          _buildConnector(1, currentStep),
          _buildStepIcon(2, currentStep, Icons.format_quote, 'Example'),
          _buildConnector(2, currentStep),
          _buildStepIcon(3, currentStep, Icons.edit_document, 'Draft'),
          _buildConnector(3, currentStep),
          _buildStepIcon(4, currentStep, Icons.analytics_outlined, 'Feedback'),
        ],
      ),
    );
  }

  Widget _buildStepIcon(int step, int currentStep, IconData icon, String label) {
    final isActive = currentStep == step;
    final isPast = currentStep > step;
    final color = isActive || isPast ? AppColors.vibrantLime : Colors.white24;

    return GestureDetector(
       onTap: () {
          if (isPast || isActive) {
             ref.read(studyPlanSessionProvider.notifier).updateSessionStep(widget.documentType, step);
          }
       },
       child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color.withOpacity(0.2) : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
       )
    );
  }

  Widget _buildConnector(int step, int currentStep) {
    final isActive = currentStep > step;
    return Container(
      width: 20, // Fixed width instead of Expanded
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isActive ? AppColors.vibrantLime : Colors.white24,
    );
  }

  Widget _buildCurrentStep(StudyPlanSessionState state, int step) {
     if (state.isLoading) {
        return const Center(child: CircularProgressIndicator(color: AppColors.vibrantLime));
     }

     switch(step) {
        case 1: return _buildInstructionsStep(state);
        case 2: return _buildExampleStep(state);
        case 3: return _buildDraftingStep(state);
        case 4: return StudyPlanAnalysisView(documentType: widget.documentType);
        default: return const SizedBox();
     }
  }

  Widget _buildInstructionsStep(StudyPlanSessionState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(
              widget.documentType == 'study_plan' 
                ? 'Study Plan yozish bo\'yicha qo\'llanma'
                : 'Personal Statement yozish bo\'yicha qo\'llanma', 
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            Text(
              widget.documentType == 'study_plan'
                ? 'Study Plan — bu sizning nega Janubiy Koreyada o\'qimoqchi ekanligingiz, oldingizga qo\'ygan maqsadlaringiz va o\'qishni bitirgandan keyingi rejalaringiz haqida batafsil ma\'lumot beruvchi muhim hujjat hisoblanadi.'
                : 'Personal Statement — bu sizning shaxsingiz, o\'tmishdagi yutuqlaringiz, qiziqishlaringiz va nega aynan ushbu mutaxassislikka munosib ekanligingizni ko\'rsatuvchi insho hisoblanadi.', 
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)
            ),
            const SizedBox(height: 24),
            if (widget.documentType == 'study_plan') ...[
              _buildGuideItem(
                icon: Icons.flag,
                title: '1. Maqsad va Motivatsiya',
                description: 'Nega aynan ushbu mutaxassislikni tanladingiz? Nega Janubiy Koreya va siz tanlagan universitet bu maqsadingizga mos keladi?',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                icon: Icons.menu_book,
                title: '2. Ta\'lim Rejasi',
                description: 'O\'qish davrida qaysi fanlarga ko\'proq e\'tibor qaratmoqchisiz? Til o\'rganish rejangiz qanday?',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                icon: Icons.rocket_launch,
                title: '3. Kelajakdagi Rejalar',
                description: 'O\'qishni tamomlagandan so\'ng qanday ish bilan shug\'ullanmoqchisiz? Vataningizga qaytib qanday hissa qo\'shasiz?',
              ),
            ] else ...[
              _buildGuideItem(
                icon: Icons.history_edu,
                title: '1. O\'tmish va Tajriba',
                description: 'Maktab/litsey davridagi yutuqlaringiz, qatnashgan olimpiadalaringiz va qiziqishlaringiz haqida yozing.',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                icon: Icons.psychology,
                title: '2. Shaxsiy Xislatlar',
                description: 'Sizni qanday xislatlar boshqalardan ajratib turadi? Qiyinchiliklarni qanday yenggansiz?',
              ),
              const SizedBox(height: 16),
              _buildGuideItem(
                icon: Icons.stars,
                title: '3. Nega ushbu soha?',
                description: 'Ushbu mutaxassislikka bo\'lgan qiziqishingiz qachon va qanday paydo bo\'lgan?',
              ),
            ],
            
            const SizedBox(height: 48),
            const Text(
              'Tavsiya etilgan videolar (CRM)', 
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            // Dummy Video List
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: const Center(
                              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '${widget.documentType == 'study_plan' ? 'Study Plan' : 'Personal Statement'} sirlari - ${index + 1}-qism',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vibrantLime,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => ref.read(studyPlanSessionProvider.notifier).updateSessionStep(widget.documentType, 2),
                child: const Text('Read Examples', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24), // Bottom padding
         ]
      )
    );
  }

  Widget _buildGuideItem({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.royalBlue.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.vibrantLime, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExampleStep(StudyPlanSessionState state) {
    // Automatically use the university selected during session creation
    final uniName = state.currentSession?.universityNameEn ?? 'Target University';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const Icon(Icons.school, color: AppColors.vibrantLime, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    'Target University',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    uniName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.vibrantLime.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.vibrantLime.withOpacity(0.3)),
              ),
              child: Text(
                state.currentSession?.selectedTrack?.toUpperCase() ?? 'GENERAL',
                style: const TextStyle(color: AppColors.vibrantLime, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white10),
        const SizedBox(height: 24),
        _buildExampleContent(uniName),
      ],
    );
  }

  Widget _buildExampleContent(String uniName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AiExampleCard(
          key: ValueKey('uni_\${uniName}'),
          universityName: uniName, 
          index: 1, 
          isEmbassy: false,
        ),
        const SizedBox(height: 24),
        _AiExampleCard(
          key: ValueKey('embassy_\${uniName}'),
          universityName: 'Korea Respublikasi Elchixonasi (Visa)', 
          index: 2, 
          isEmbassy: true,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.vibrantLime,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => ref.read(studyPlanSessionProvider.notifier).updateSessionStep(widget.documentType, 3),
          child: const Text('Start Drafting', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDraftingStep(StudyPlanSessionState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AdvancedDraftingWorkspace(
        initialText: _draftController.text,
        documentTitle: documentTitle,
        documentType: widget.documentType, // Pass documentType
      ),
    );
  }

  void _showCreateSessionDialog() {
    String selectedTrack = 'english';
    String? selectedUniId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final applicationsAsync = ref.watch(applicationsProvider);

            return AlertDialog(
              backgroundColor: AppColors.backgroundNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Colors.white10),
              ),
              title: Text(
                'Start New ${widget.documentType == 'study_plan' ? 'Study Plan' : 'Personal Statement'}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                          return const Text('No active applications found. Please apply first.', style: TextStyle(color: Colors.white54, fontSize: 12));
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
                                onTap: () => setDialogState(() => selectedUniId = uni.id),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('2. Select Language Track', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TrackChip(
                            label: 'English',
                            isSelected: selectedTrack == 'english',
                            icon: Icons.language,
                            onTap: () => setDialogState(() => selectedTrack = 'english'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TrackChip(
                            label: 'Korean',
                            isSelected: selectedTrack == 'korean',
                            icon: Icons.translate,
                            onTap: () => setDialogState(() => selectedTrack = 'korean'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                if (ref.watch(documentSessionProvider(widget.documentType)).error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      ref.watch(documentSessionProvider(widget.documentType)).error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                TextButton(
                  onPressed: ref.watch(documentSessionProvider(widget.documentType)).isLoading 
                      ? null 
                      : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vibrantLime,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: (selectedUniId == null || ref.watch(documentSessionProvider(widget.documentType)).isLoading) 
                    ? null 
                    : () async {
                      final session = await ref.read(studyPlanSessionProvider.notifier).createSession(
                        widget.documentType,
                        targetUniversityId: selectedUniId,
                        selectedTrack: selectedTrack,
                      );
                      
                      if (session != null && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  child: ref.watch(documentSessionProvider(widget.documentType)).isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                      )
                    : const Text('Create Session', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _AiExampleCard extends StatefulWidget {
  final String universityName;
  final int index;
  final bool isEmbassy;
  const _AiExampleCard({super.key, required this.universityName, required this.index, this.isEmbassy = false});

  @override
  State<_AiExampleCard> createState() => _AiExampleCardState();
}

class _AiExampleCardState extends State<_AiExampleCard> {
  late Future<String> _aiFuture;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final String studentName = user?.userMetadata?['full_name'] as String? ?? 'A passionate student';

    final List<String> _uniTemplates = [
      // Template 1: Classic Academic & General Innovation
      '''Dear Admissions Committee at ${widget.universityName},

[INTRODUCTION]
My name is $studentName, and I am writing to express my sincere interest in pursuing my academic studies at ${widget.universityName}. With a strong foundational academic background and an unwavering passion for innovation and cross-cultural exchange, I believe that joining your esteemed institution will be a pivotal step in achieving my long-term career aspirations and academic goals.

[ACADEMIC BACKGROUND & MOTIVATION]
My academic journey thus far has instilled in me a deep curiosity and a rigorous work ethic. During my previous studies, I consistently engaged in projects that required critical thinking, leadership, and analytical prowess. I specifically chose ${widget.universityName} because of its globally recognized faculty, state-of-the-art research facilities, and its profound commitment to fostering a vibrant, diverse intellectual community. The unique curriculum offered by your university, which heavily balances theoretical knowledge with practical applications, aligns perfectly with my personal framework for success.

[DETAILED STUDY PLAN]
If granted the opportunity to study at ${widget.universityName}, my primary goal is to immerse myself fully in my major while integrating seamlessly into the South Korean academic environment. During the first year, I will dedicate my time to mastering the core subjects and improving my Korean language proficiency to enhance my daily communication and cultural understanding. 

In subsequent years, I plan to actively participate in research seminars, collaborate intimately with professors on ongoing empirical projects, and join student-led academic clubs. I am particularly interested in exploring how modern technologies can be adapted to solve real-world socio-economic problems in developing economies. I will spend my free time utilizing the university library resources to draft comprehensive research papers that contribute to the academic legacy of the institution.

[CONCLUSION & FUTURE GOALS]
Looking towards the future, my ultimate vision is to return to my home country and become a visionary industry leader and a specialist in my field. I intend to leverage the world-class education, global perspective, and robust network I build at ${widget.universityName} to establish strategic initiatives that drive technological and social advancement. I am confident that the rigorous academic environment at your university will equip me with the expertise and resilience necessary to make a meaningful impact globally. 

Thank you for considering my application. I look forward to the possibility of contributing to and growing within the vibrant community at ${widget.universityName}.''',

      // Template 2: Tech-Driven & Practical Industry Focus
      '''To the Respected Admissions Committee at ${widget.universityName},

[INTRODUCTION]
I am $studentName, and it is with great enthusiasm that I submit my application to join the vibrant academic community at ${widget.universityName}. Ever since my early education, my primary focus has been on exploring the intersection of modern technology and sustainable industry practices. I am convinced that studying in South Korea will provide the perfect catalyst for my professional and intellectual growth.

[ACADEMIC BACKGROUND & MOTIVATION]
Throughout my prior schooling, I have maintained excellent grades while leading several extracurricular initiatives related to environmental awareness and digital transformation. I selected ${widget.universityName} after extensive secondary research due to your institution's unparalleled connections with major tech industries and start-up incubators. Your hands-on approach to learning, combined with a forward-thinking pedagogical style, precisely matches the environment I need to thrive and innovate.

[DETAILED STUDY PLAN]
Upon my arrival at ${widget.universityName}, my immediate priority will be to achieve a high proficiency in the Korean language through intensive language courses, ensuring I can communicate effectively with my peers and mentors. Academically, I plan to dive deeply into my major courses, putting a strong emphasis on laboratory work and data analytics.

By my junior and senior years, my goal is to secure an internship or a cooperative placement facilitated by the university. I wish to participate in hackathons, innovation challenges, and symposiums hosted by ${widget.universityName}. My overarching objective during my studies is to develop an actionable tech product or service model that addresses supply chain inefficiencies in developing regions.

[CONCLUSION & FUTURE GOALS]
After completing my degree, I plan to return to my home country equipped with the technical skills and leadership qualities necessary to foster local start-up ecosystems. By utilizing the incredible foundation provided by ${widget.universityName}, I aim to build a bridge of collaboration between tech firms in South Korea and emerging markets. I am deeply passionate about making a difference and hope to bring my unique perspective to your campus. Thank you for your time and consideration.''',

      // Template 3: Cultural Exchange & Global Business Leadership
      '''Dear Members of the Admissions Office at ${widget.universityName},

[INTRODUCTION]
Allow me to introduce myself. My name is $studentName, and I am honored to present my application for undergraduate studies at ${widget.universityName}. Driven by an insatiable desire to understand global markets and intercultural dynamics, I view South Korea not just as a hub of economic miracles, but as the perfect training ground for the next generation of global leaders.

[ACADEMIC BACKGROUND & MOTIVATION]
In my previous academic pursuits, I have consistently gravitated towards subjects like economics, social sciences, and international relations. I have always pushed myself out of my comfort zone, participating in debate clubs and organizing community events. ${widget.universityName} stands out to me immensely because of its truly international student body and its curriculum that emphasizes global business strategy. The opportunity to learn from world-renowned professors while engaging with diverse perspectives is what drew me specifically to your esteemed organization.

[DETAILED STUDY PLAN]
My strategy for succeeding at ${widget.universityName} is structured and ambitious. In the initial phase of my studies, I will focus on building a robust academic foundation and dedicating significant hours to mastering the Korean language. I believe that understanding the local culture and language is crucial to grasping the nuances of the Korean economic model.

Later in my program, I intend to actively seek out collaborative projects with students from various faculties. I aim to join business and cultural exchange societies on campus, eventually taking on a leadership role. Furthermore, I plan to write a comprehensive undergraduate thesis utilizing case studies of South Korean conglomerates and their expansion strategies, with guidance from your distinguished faculty members.

[CONCLUSION & FUTURE GOALS]
Post-graduation, my ambition is to launch a multinational trading or consulting firm that facilitates bilateral trade and cultural exchange between my home country and South Korea. The education and experiences I will gain at ${widget.universityName} will serve as the crucial bedrock for this lifelong mission. I am deeply committed to upholding the values of your university and leaving a positive mark on the campus community. Thank you for reviewing my profile.''',
    ];

    final List<String> _embassyTemplates = [
      '''To the Respected Consul at the Embassy of the Republic of Korea,

[INTRODUCTION AND VISA PURPOSE]
My name is $studentName, and I am respectfully submitting my student visa application to pursue my higher education in South Korea. After meticulous research and preparation, I have chosen to advance my academic and professional career within your country's esteemed educational system. South Korea's impeccable reputation for technological advancement, safety, and cultural richness makes it the ideal destination for international students like myself.

[ACADEMIC BACKGROUND]
During my previous academic years, I have consistently demonstrated a strong dedication to my studies and a clear, focused ambition for my future career. I have been accepted into the university to further hone my skills and expand my global perspective. I am absolutely committed to maintaining a high academic standing and strictly adhering to all the rules, laws, and cultural etiquette of South Korea during my stay.

[DETAILED STUDY & LIVING PLAN]
My primary objective is strictly educational. Upon arriving in South Korea, my initial focus will be entirely on completing my language program and securing my academic foundation. I have secured sufficient financial sponsorship to cover my tuition fees and living expenses, ensuring that I can devote 100% of my time and energy to my studies without any distractions. I will actively participate in university-organized cultural exchange programs to foster positive relations between our nations.

[CONCLUSION AND GUARANTEE OF RETURN]
Most importantly, upon the successful completion of my degree, I guarantee that I will return to my home country. My long-term career goal is to utilize the invaluable knowledge and professional network I acquire in South Korea to contribute to the economic and technological growth of my homeland. I am an honest and highly motivated student, and I humbly request that you grant me the student visa to fulfill my academic dreams. Thank you for your time and consideration.''',

      '''Hurmatli Konsul / To the Respected Consul,

[INTRODUCTION AND VISA PURPOSE]
My name is $studentName, and I am writing to strongly support my student visa application. It has been my lifelong ambition to study in South Korea, a country globally recognized for its exceptional educational standards, rapid economic development, and rich cultural heritage. I am deeply honored to have received admission to pursue my academic goals in your remarkable country.

[ACADEMIC BACKGROUND]
I possess a solid academic record and a genuine thirst for knowledge. My previous educational experiences have deeply prepared me for the rigorous academic environment in South Korea. I chose South Korea because the specific curriculum offered directly aligns with my career ambitions to become a highly skilled specialist in my field, a dream that requires the world-class education that only your institutions can provide.

[DETAILED STUDY & LIVING PLAN]
If granted the visa, my sole priority will be my studies. I have thoroughly planned my timeline: the first year will be dedicated to adapting to the new environment, perfecting my language skills, and mastering core academic subjects. I am fully financially supported by my parents/sponsors, which guarantees that my living, medical, and educational expenses are completely covered. I am fully aware of and commit to strictly obeying all visa regulations and the laws of the Republic of Korea.

[CONCLUSION AND GUARANTEE OF RETURN]
I wish to explicitly state my intention to return to my home country immediately following my graduation. There is a high demand for international experts in my field here, and the degree I earn in South Korea will guarantee me a prestigious leading position in my homeland. I view this educational journey as a critical investment in my future. I kindly ask for a favorable decision on my visa application. Thank you.''',
    ];

    // Pick a truly random template each time the widget is built based on type
    final random = Random();
    final _templates = widget.isEmbassy ? _embassyTemplates : _uniTemplates;
    final selectedExample = _templates[random.nextInt(_templates.length)];

    // Simulate thinking time dynamically so cards load progressively
    _aiFuture = Future.delayed(Duration(milliseconds: 1500 + (widget.index * 900)), () => selectedExample);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.royalBlue.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withOpacity(0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(widget.isEmbassy ? Icons.account_balance : Icons.school, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isEmbassy ? 'Elchixona uchun Namuna' : '${widget.universityName} uchun Namuna',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<String>(
            future: _aiFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.vibrantLime),
                      SizedBox(height: 16),
                      Text('AI namuna yozmoqda...', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Xatolik: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      snapshot.data!,
                      style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Nusxa olish'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.vibrantLime),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: snapshot.data!)).then((_) {
                               if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Matn nusxalandi!'), 
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                               }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
