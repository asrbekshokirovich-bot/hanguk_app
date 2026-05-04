import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../data/study_plan_repository.dart';

class StudyPlanChatFab extends ConsumerStatefulWidget {
  final String documentType;
  const StudyPlanChatFab({super.key, required this.documentType});

  @override
  ConsumerState<StudyPlanChatFab> createState() => _StudyPlanChatFabState();
}

class _StudyPlanChatFabState extends ConsumerState<StudyPlanChatFab> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    if (!_isOpen) {
      return FloatingActionButton(
        backgroundColor: AppColors.vibrantLime,
        child: const Icon(Icons.chat_bubble_outline, color: Colors.black),
        onPressed: () => setState(() => _isOpen = true),
      );
    }

    // Floating window
    return Container(
      width: 320,
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.vibrantLime.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AI Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => setState(() => _isOpen = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
          const Divider(color: Colors.white10),
          const Expanded(
            child: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.psychology_outlined, color: AppColors.vibrantLime, size: 48),
                   SizedBox(height: 16),
                   Text(
                     'AI Assistant is thinking...\nAsk me anything about your draft!', 
                     textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.white54, fontSize: 13),
                   ),
                 ],
               ),
            ),
          ),
          // Simulating text input
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12),
             decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(24),
             ),
             child: const TextField(
                style: TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                   border: InputBorder.none,
                   hintText: 'Ask a question...',
                   hintStyle: TextStyle(color: Colors.white30),
                   suffixIcon: Icon(Icons.send, color: AppColors.vibrantLime, size: 18),
                ),
             ),
          )
        ],
      ),
    );
  }
}
