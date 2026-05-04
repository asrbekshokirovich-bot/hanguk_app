import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../data/interview_repository.dart';

class InterviewSetupView extends ConsumerStatefulWidget {
  final VoidCallback onHistoryTapped;
  const InterviewSetupView({super.key, required this.onHistoryTapped});

  @override
  ConsumerState<InterviewSetupView> createState() => _InterviewSetupViewState();
}

class _InterviewSetupViewState extends ConsumerState<InterviewSetupView> {
  String _sessionType = 'general';
  String _language = 'ko';
  String _focusTopic = '';
  String _persona = 'friendly';
  bool _timedMode = false;

  void _start() {
    ref.read(interviewProvider.notifier).startSession(
      sessionType: _sessionType,
      language: _language,
      focusTopic: _focusTopic.isNotEmpty ? _focusTopic : null,
      persona: _persona,
      timedMode: _timedMode,
      timeLimitSeconds: _timedMode ? 300 : null, // 5 min default
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interviewProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Interview Setup',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.history, color: AppColors.royalBlue),
                onPressed: widget.onHistoryTapped,
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure your AI interviewer settings before starting.',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 32),

          _buildLabel('Interview Type'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sessionType,
                dropdownColor: AppColors.backgroundNavy,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General Introduction')),
                  DropdownMenuItem(value: 'university_specific', child: Text('University Specific')),
                  DropdownMenuItem(value: 'visa', child: Text('Visa / Embassy Check')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sessionType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel('Language'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LanguageOption(
                  title: 'Korean',
                  isSelected: _language == 'ko',
                  onTap: () => setState(() => _language = 'ko'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _LanguageOption(
                  title: 'English',
                  isSelected: _language == 'en',
                  onTap: () => setState(() => _language = 'en'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildLabel('Interviewer Persona'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _persona,
                dropdownColor: AppColors.backgroundNavy,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: const [
                  DropdownMenuItem(value: 'friendly', child: Text('Friendly Admissions Officer')),
                  DropdownMenuItem(value: 'strict', child: Text('Strict Professor')),
                  DropdownMenuItem(value: 'impatient', child: Text('Impatient Visa Officer')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _persona = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildLabel('Focus Topic (Optional)'),
          const SizedBox(height: 8),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Discussing my computer science major...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => _focusTopic = val,
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.royalBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.royalBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: AppColors.royalBlue),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Timed Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('5 minute strict limit', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ],
                  ),
                ),
                Switch(
                  value: _timedMode,
                  activeColor: AppColors.royalBlue,
                  onChanged: (val) => setState(() => _timedMode = val),
                )
              ],
            ),
          ),
          const SizedBox(height: 48),

          if (state.isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.vibrantLime))
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vibrantLime,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Practice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              onPressed: _start,
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.royalBlue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.royalBlue : Colors.white10),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.royalBlue : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
