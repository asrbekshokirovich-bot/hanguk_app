import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../data/study_plan_repository.dart';
import 'ai_highlighting_text_controller.dart';
import 'live_metrics_bar.dart';

class AdvancedDraftingWorkspace extends ConsumerStatefulWidget {
  final String initialText;
  final String documentTitle;
  final String documentType; // 'study_plan' or 'personal_statement'

  const AdvancedDraftingWorkspace({
    super.key,
    required this.initialText,
    required this.documentTitle,
    required this.documentType,
  });

  @override
  ConsumerState<AdvancedDraftingWorkspace> createState() => _AdvancedDraftingWorkspaceState();
}

class _AdvancedDraftingWorkspaceState extends ConsumerState<AdvancedDraftingWorkspace> {
  late AiHighlightingTextController _controller;
  final FocusNode _focusNode = FocusNode();
  
  Timer? _saveDebounceTimer;
  Timer? _aiSuggestionTimer;
  
  SaveStatus _saveStatus = SaveStatus.saved;
  
  int _wordCount = 0;
  int _charCount = 0;
  
  String _aiContextStatus = "Waiting for input...";
  List<GrammarIssue> _activeIssues = [];

  @override
  void initState() {
    super.initState();
    _controller = AiHighlightingTextController(text: widget.initialText);
    _updateMetrics(widget.initialText);
    
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AdvancedDraftingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText && 
        _controller.text != widget.initialText && 
        _saveStatus != SaveStatus.unsaved) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _aiSuggestionTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    _updateMetrics(text);
    
    // Clear ghost text immediately when the user starts typing
    if (_controller.ghostText != null) {
      _controller.setGhostText(null);
    }
    
    // Update local state
    setState(() {
      _saveStatus = SaveStatus.unsaved;
    });

    // Notify provider of local draft change immediately
    ref.read(studyPlanSessionProvider.notifier).setDraftContent(widget.documentType, text);

    // AI Ghost Text Debounce (1 second)
    _aiSuggestionTimer?.cancel();
    _aiSuggestionTimer = Timer(const Duration(milliseconds: 1000), () {
      _generateAiSuggestion(text);
    });

    // Auto-save Debounce (2 seconds)
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 2000), () {
      _saveDraft(text);
    });
  }

  void _updateMetrics(String text) {
    if (!mounted) return;
    
    final trimmed = text.trim();
    final wordCount = trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
    
    setState(() {
      _wordCount = wordCount;
      _charCount = text.length;
    });
  }

  Future<void> _saveDraft(String text) async {
    if (!mounted) return;
    
    setState(() {
      _saveStatus = SaveStatus.saving;
    });
    
    await ref.read(studyPlanSessionProvider.notifier).saveDraft(widget.documentType, text);
    
    if (mounted) {
      setState(() {
        _saveStatus = SaveStatus.saved;
      });
    }
  }

  Future<void> _generateAiSuggestion(String text) async {
    if (text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _aiContextStatus = "Waiting for input...";
          _activeIssues = [];
          _controller.setIssues([]);
          _controller.setGhostText(null);
        });
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _aiContextStatus = "AI analyzing...";
      });
    }

    final result = await ref.read(studyPlanSessionProvider.notifier).superviseDraft(widget.documentType, text);
    
    if (!mounted) return;

    if (result == null || result.isEmpty) {
      setState(() {
        _aiContextStatus = "Ready";
      });
      return;
    }

    final ghostText = result['ghostText'] as String? ?? '';
    final issuesList = result['issues'] as List<dynamic>? ?? [];

    List<GrammarIssue> detectedIssues = [];
    final lowerText = text.toLowerCase();

    for (var issueItem in issuesList) {
      final original = issueItem['originalText']?.toString() ?? '';
      final suggestion = issueItem['suggestion']?.toString() ?? '';
      
      if (original.isNotEmpty) {
        // Find the last occurrence since the AI analyzes recent text
        int index = lowerText.lastIndexOf(original.toLowerCase());
        if (index != -1) {
          detectedIssues.add(GrammarIssue(
            start: index,
            end: index + original.length,
            originalText: text.substring(index, index + original.length),
            suggestion: suggestion,
          ));
        }
      }
    }

    setState(() {
      _aiContextStatus = ghostText.isNotEmpty ? "AI Predicting..." : "AI Supervision Active";
      _activeIssues = detectedIssues;
    });

    _controller.setIssues(detectedIssues);
    _controller.setGhostText(ghostText.isEmpty ? null : ghostText);
  }

  void _acceptSuggestion() {
    if (_controller.ghostText != null) {
      final currentText = _controller.text;
      final addedText = _controller.ghostText!;
      
      final newText = currentText + addedText;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      _controller.setGhostText(null);
    }
  }

  void _applyGrammarFix(GrammarIssue issue) {
    String currentText = _controller.text;
    String newText = currentText.substring(0, issue.start) + issue.suggestion + currentText.substring(issue.end);
    
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: issue.start + issue.suggestion.length),
    );
    _onTextChanged();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentSessionProvider(widget.documentType));
    final currentTrack = state.currentSession?.selectedTrack;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Workspace',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.royalBlue),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology, size: 14, color: AppColors.vibrantLime),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _aiContextStatus,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(color: AppColors.vibrantLime, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                 _saveDraft(_controller.text).then((_) {
                    ref.read(studyPlanSessionProvider.notifier).analyzeCurrentDraft(widget.documentType);
                    ref.read(studyPlanSessionProvider.notifier).updateSessionStep(widget.documentType, 4);
                 });
              },
              child: const Text('Analyze', style: TextStyle(color: AppColors.royalBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_activeIssues.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
                    SizedBox(width: 8),
                    Text('AI Supervision Warnings:', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _activeIssues.map((issue) {
                    return ActionChip(
                      backgroundColor: AppColors.backgroundNavy,
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                      label: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                          children: [
                            const TextSpan(text: 'Replace '),
                            TextSpan(text: '"${issue.originalText}"', style: const TextStyle(color: Colors.redAccent, decoration: TextDecoration.lineThrough)),
                            const TextSpan(text: ' with '),
                            TextSpan(text: '"${issue.suggestion}"', style: const TextStyle(color: AppColors.vibrantLime, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      onPressed: () => _applyGrammarFix(issue),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: KeyboardListener(
              focusNode: FocusNode(), // Dummy focus node to capture key events at bubble phase
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent && 
                    event.logicalKey == LogicalKeyboardKey.tab && 
                    _controller.ghostText != null) {
                  _acceptSuggestion();
                }
              },
              child: CallbackShortcuts(
                 bindings: {
                    const SingleActivator(LogicalKeyboardKey.tab): _acceptSuggestion,
                 },
                 child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type your ${widget.documentTitle.toLowerCase()} here...',
                    hintStyle: const TextStyle(color: Colors.white30),
                  ),
                 ),
              ),
            ),
          ),
        ),
        LiveMetricsBar(
          wordCount: _wordCount,
          charCount: _charCount,
          saveStatus: _saveStatus,
          track: currentTrack,
        ),
      ],
    );
  }
}
