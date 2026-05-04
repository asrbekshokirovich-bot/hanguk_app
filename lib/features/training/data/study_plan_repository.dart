import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudyPlanSession {
  final String id;
  final String studentId;
  final String documentType;
  final String? targetUniversityId;
  final int currentStep;
  final String status;
  final String? universityNameEn;
  final String? selectedTrack; // 'english' or 'korean'

  StudyPlanSession({
    required this.id,
    required this.studentId,
    required this.documentType,
    this.targetUniversityId,
    required this.currentStep,
    required this.status,
    this.universityNameEn,
    this.selectedTrack,
  });

  factory StudyPlanSession.fromJson(Map<String, dynamic> json) {
    return StudyPlanSession(
      id: json['id'],
      studentId: json['student_id'],
      documentType: json['document_type'],
      targetUniversityId: json['target_university_id'],
      currentStep: json['current_step'],
      status: json['status'],
      universityNameEn: json['university']?['name_en'],
      selectedTrack: json['selected_track'],
    );
  }
}

class StudyPlanDraft {
  final String id;
  final String content;
  final int version;
  
  StudyPlanDraft({required this.id, required this.content, required this.version});
  
  factory StudyPlanDraft.fromJson(Map<String, dynamic> json) {
    return StudyPlanDraft(
      id: json['id'],
      content: json['content'],
      version: json['version'],
    );
  }
}

class StudyPlanAnalysis {
  final String id;
  final num? overallScore;
  final List<dynamic>? grammarErrors;
  final String? contentFeedback;
  final List<dynamic>? strengths;
  final List<dynamic>? improvements;
  final String? aiResponse;

  StudyPlanAnalysis({
    required this.id,
    this.overallScore,
    this.grammarErrors,
    this.contentFeedback,
    this.strengths,
    this.improvements,
    this.aiResponse,
  });

  factory StudyPlanAnalysis.fromJson(Map<String, dynamic> json) {
    return StudyPlanAnalysis(
      id: json['id'],
      overallScore: json['overall_score'],
      grammarErrors: json['grammar_errors'],
      contentFeedback: json['content_feedback'],
      strengths: json['strengths'],
      improvements: json['improvements'],
      aiResponse: json['ai_response'],
    );
  }
}

class ChatMessage {
  final String role;
  final String content;
  ChatMessage({required this.role, required this.content});
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(role: json['role'], content: json['content']);
  }
}

class StudyPlanSessionState {
  final bool isLoading;
  final bool isSessionsLoading;
  final String? error;
  
  final List<StudyPlanSession> sessions;
  final StudyPlanSession? currentSession;
  final List<StudyPlanDraft> drafts;
  final List<StudyPlanAnalysis> analyses;
  final List<ChatMessage> chatHistory;
  
  // Track ongoing drafted text to preserve state across tabs locally before saving
  final String draftContent;

  const StudyPlanSessionState({
    this.isLoading = false,
    this.isSessionsLoading = false,
    this.error,
    this.sessions = const [],
    this.currentSession,
    this.drafts = const [],
    this.analyses = const [],
    this.chatHistory = const [],
    this.draftContent = '',
  });

  StudyPlanSessionState copyWith({
    bool? isLoading,
    bool? isSessionsLoading,
    String? error,
    List<StudyPlanSession>? sessions,
    StudyPlanSession? currentSession,
    List<StudyPlanDraft>? drafts,
    List<StudyPlanAnalysis>? analyses,
    List<ChatMessage>? chatHistory,
    String? draftContent,
    bool clearError = false,
  }) {
    return StudyPlanSessionState(
      isLoading: isLoading ?? this.isLoading,
      isSessionsLoading: isSessionsLoading ?? this.isSessionsLoading,
      error: clearError ? null : (error ?? this.error),
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      drafts: drafts ?? this.drafts,
      analyses: analyses ?? this.analyses,
      chatHistory: chatHistory ?? this.chatHistory,
      draftContent: draftContent ?? this.draftContent,
    );
  }
}

class StudyPlanSessionNotifier extends Notifier<Map<String, StudyPlanSessionState>> {
  @override
  Map<String, StudyPlanSessionState> build() {
    return const {};
  }

  StudyPlanSessionState _getState(String type) => state[type] ?? const StudyPlanSessionState();

  void _setState(String type, StudyPlanSessionState newState) {
    state = {...state, type: newState};
  }

  void setDraftContent(String type, String text) {
    _setState(type, _getState(type).copyWith(draftContent: text));
  }

  void clearError(String type) {
    _setState(type, _getState(type).copyWith(clearError: true));
  }

  Future<void> fetchSessions(String type) async {
    _setState(type, _getState(type).copyWith(isSessionsLoading: true));
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await client
          .from('study_plan_sessions')
          .select('*, university:target_university_id(name_en)')
          .eq('student_id', user.id)
          .eq('document_type', type) // Filter by document type
          .order('updated_at', ascending: false);

      final List<StudyPlanSession> loaded = (response as List)
          .map((data) => StudyPlanSession.fromJson(data))
          .toList();

      _setState(type, _getState(type).copyWith(isSessionsLoading: false, sessions: loaded));
    } catch (e) {
      _setState(type, _getState(type).copyWith(isSessionsLoading: false, error: e.toString()));
    }
  }

  Future<StudyPlanSession?> createSession(String type, {String? targetUniversityId, String? selectedTrack}) async {
    final documentType = type;
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    _setState(type, _getState(type).copyWith(isLoading: true, clearError: true));
    try {
      final response = await client.from('study_plan_sessions').insert({
        'student_id': user.id,
        'document_type': documentType,
        'target_university_id': targetUniversityId,
        'current_step': 1,
        'status': 'in_progress',
      }).select('*, university:target_university_id(name_en)').single();

      final session = StudyPlanSession.fromJson(response);
      
      // Manually add the selectedTrack into the session object for the in-memory state
      final sessionWithTrack = StudyPlanSession(
        id: session.id,
        studentId: session.studentId,
        documentType: session.documentType,
        currentStep: session.currentStep,
        status: session.status,
        targetUniversityId: session.targetUniversityId,
        universityNameEn: session.universityNameEn,
        selectedTrack: selectedTrack,
      );

      _setState(type, _getState(type).copyWith(
        isLoading: false,
        sessions: [sessionWithTrack, ..._getState(type).sessions],
        currentSession: sessionWithTrack,
        drafts: [],
        analyses: [],
        chatHistory: [],
        draftContent: '',
      ));
      return sessionWithTrack;
    } catch (e) {
      _setState(type, _getState(type).copyWith(
          isLoading: false, error: 'Failed to create session: $e'));
      return null;
    }
  }

  Future<void> loadSession(String type, String sessionId) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    _setState(type, _getState(type).copyWith(isLoading: true, clearError: true));
    try {
      final sessionResp = await client
          .from('study_plan_sessions')
          .select('*, university:target_university_id(name_en)')
          .eq('id', sessionId)
          .eq('student_id', user.id)
          .single();

      final draftsResp = await client
          .from('study_plan_drafts')
          .select()
          .eq('session_id', sessionId)
          .order('version', ascending: false);

      final analysesResp = await client
          .from('study_plan_analyses')
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: false);

      final chatResp = await client
          .from('study_plan_chat_history')
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      final session = StudyPlanSession.fromJson(sessionResp);
      final drafts = (draftsResp as List).map((j) => StudyPlanDraft.fromJson(j)).toList();
      final analyses = (analysesResp as List).map((j) => StudyPlanAnalysis.fromJson(j)).toList();
      final chatHistory = (chatResp as List).map((j) => ChatMessage.fromJson(j)).toList();

      _setState(type, _getState(type).copyWith(
        isLoading: false,
        currentSession: session,
        drafts: drafts,
        analyses: analyses,
        chatHistory: chatHistory,
        draftContent: drafts.isNotEmpty ? drafts.first.content : '',
      ));
    } catch (e) {
      _setState(type, _getState(type).copyWith(
          isLoading: false, error: 'Failed to load session data: $e'));
    }
  }

  Future<void> updateSessionStep(String type, int step) async {
    final currentSession = _getState(type).currentSession;
    if (currentSession == null) return;
    try {
      await Supabase.instance.client
          .from('study_plan_sessions')
          .update({'current_step': step, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', currentSession.id);
      
      final updatedSession = StudyPlanSession(
         id: currentSession.id,
         studentId: currentSession.studentId,
         documentType: currentSession.documentType,
         currentStep: step,
         status: currentSession.status,
         targetUniversityId: currentSession.targetUniversityId,
         universityNameEn: currentSession.universityNameEn,
         selectedTrack: currentSession.selectedTrack,
      );

      final updatedSessions = _getState(type).sessions.map((s) => s.id == updatedSession.id ? updatedSession : s).toList();
      
      _setState(type, _getState(type).copyWith(currentSession: updatedSession, sessions: updatedSessions));
    } catch (e) {
      print('Failed to update session step: $e');
    }
  }

  Future<void> saveDraft(String type, String content) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final currentState = _getState(type);
    if (currentState.currentSession == null || user == null) return;

    final wordCount = content.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    final nextVersion = currentState.drafts.isNotEmpty 
      ? currentState.drafts.map((d) => d.version).reduce((a, b) => a > b ? a : b) + 1 
      : 1;

    try {
      final response = await client.from('study_plan_drafts').insert({
        'session_id': currentState.currentSession!.id,
        'student_id': user.id,
        'version': nextVersion,
        'content': content,
        'word_count': wordCount,
        'source': 'typed',
      }).select().single();

      final draft = StudyPlanDraft.fromJson(response);
      _setState(type, currentState.copyWith(drafts: [draft, ...currentState.drafts], draftContent: content));
    } catch (e) {
      _setState(type, currentState.copyWith(error: 'Failed to save draft: $e'));
    }
  }

  Future<void> deleteSession(String type, String sessionId) async {
    try {
      await Supabase.instance.client
          .from('study_plan_sessions')
          .delete()
          .eq('id', sessionId);
          
      final updatedSessions = _getState(type).sessions.where((s) => s.id != sessionId).toList();
      _setState(type, _getState(type).copyWith(
        sessions: updatedSessions, 
        currentSession: _getState(type).currentSession?.id == sessionId ? null : _getState(type).currentSession
      ));
    } catch(e) {
      print('delete error: $e');
    }
  }

  void clearCurrentSession(String type) {
    _setState(type, const StudyPlanSessionState());
  }

  /// AI Invocation using Edge Functions
  Future<StudyPlanAnalysis?> analyzeCurrentDraft(String type) async {
    final currentState = _getState(type);
    final draft = currentState.drafts.isNotEmpty ? currentState.drafts.first : null;
    if (draft == null || currentState.currentSession == null) return null;

    _setState(type, currentState.copyWith(isLoading: true, clearError: true));
    try {
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'study-plan-trainer',
        body: {
          'action': 'analyze',
          'documentType': currentState.currentSession!.documentType,
          'content': draft.content,
          'targetUniversityId': currentState.currentSession!.targetUniversityId,
          'selectedTrack': currentState.currentSession!.selectedTrack,
          'language': 'en',
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'Empty response from Trainer AI');
      }

      final aiResponseText = data['response'] as String? ?? '';

      final insertResp = await client.from('study_plan_analyses').insert({
        'session_id': currentState.currentSession!.id,
        'draft_id': draft.id,
        'ai_response': aiResponseText,
      }).select().single();

      final analysis = StudyPlanAnalysis.fromJson(insertResp);
      _setState(type, _getState(type).copyWith(isLoading: false, analyses: [analysis, ..._getState(type).analyses]));
      return analysis;

    } catch (e) {
      _setState(type, _getState(type).copyWith(isLoading: false, error: 'AI Error: $e'));
      return null;
    }
  }

  Future<Map<String, dynamic>?> superviseDraft(String type, String content) async {
    final currentState = _getState(type);
    if (currentState.currentSession == null || content.isEmpty) return null;

    try {
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'study-plan-trainer',
        body: {
          'action': 'draft_supervise',
          'documentType': currentState.currentSession!.documentType,
          'content': content,
          'targetUniversityId': currentState.currentSession!.targetUniversityId,
          'selectedTrack': currentState.currentSession!.selectedTrack,
          'language': 'en',
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        return null;
      }

      final aiResponseText = data['response'] as String? ?? '{}';
      
      // Parse JSON
      if (aiResponseText.startsWith('{') && aiResponseText.endsWith('}')) {
        return Map<String, dynamic>.from(jsonDecode(aiResponseText));
      }
      return {};
    } catch (e) {
      print('Supervise AI Error: $e');
      return null;
    }
  }
}


final studyPlanSessionProvider = NotifierProvider<StudyPlanSessionNotifier, Map<String, StudyPlanSessionState>>(() {
  return StudyPlanSessionNotifier();
});

// Helper provider to get state for a specific document type
final documentSessionProvider = Provider.family<StudyPlanSessionState, String>((ref, type) {
  final allStates = ref.watch(studyPlanSessionProvider);
  return allStates[type] ?? const StudyPlanSessionState();
});
