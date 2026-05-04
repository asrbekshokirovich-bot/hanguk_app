import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../core/config/app_config.dart';

// ---------------------------------------------------------------------------
// Persona / Voice configuration — single source of truth for both Vapi and TTS
// ---------------------------------------------------------------------------
class InterviewPersonaConfig {
  static String getVoiceId(String persona, String language) {
    if (persona == 'strict') {
      return language == 'ko' ? 'TX3Omw2n4tG93wHn3C2j' : 'pNInz6obbfdqIjc9VDzA';
    } else if (persona == 'impatient') {
      return language == 'ko' ? 'ErXwobaYiN019PkySvjV' : 'MF3mGyEYCl7XYWbV9V6O';
    }
    // Default: friendly
    return language == 'ko' ? 'cgSgspJ2msm6clMCkdW9' : 'nPczCjzI2devNBz1zQrb';
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------
class InterviewMessage {
  final String id;
  final String role; // 'interviewer' | 'student'
  final String content;
  final String createdAt;

  const InterviewMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class InterviewSessionState {
  final String? sessionId;
  final String sessionType;
  final String status;
  final List<InterviewMessage> messages;
  final Map<String, dynamic>? feedback;
  final String? targetUniversityId;
  final String? targetUniversityName;
  final String selectedLanguage;
  final bool isLoading;
  final bool isProcessing;
  final String interviewerPersona;
  final List<String> liveHints;
  final String? error;
  final bool isVapiConnected; // true when WebRTC call is live
  final String? vapiCallId; // Stores the underlying session ID for audio recordings

  const InterviewSessionState({
    this.sessionId,
    this.sessionType = 'general',
    this.status = 'idle',
    this.messages = const [],
    this.feedback,
    this.targetUniversityId,
    this.targetUniversityName,
    this.selectedLanguage = 'ko',
    this.isLoading = false,
    this.isProcessing = false,
    this.interviewerPersona = 'friendly',
    this.liveHints = const [],
    this.error,
    this.isVapiConnected = false,
    this.vapiCallId,
  });

  InterviewSessionState copyWith({
    String? sessionId,
    String? sessionType,
    String? status,
    List<InterviewMessage>? messages,
    Map<String, dynamic>? feedback,
    String? targetUniversityId,
    String? targetUniversityName,
    String? selectedLanguage,
    bool? isLoading,
    bool? isProcessing,
    String? interviewerPersona,
    List<String>? liveHints,
    String? error,
    bool clearError = false,
    bool? isVapiConnected,
    String? vapiCallId,
  }) {
    return InterviewSessionState(
      sessionId: sessionId ?? this.sessionId,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      feedback: feedback ?? this.feedback,
      targetUniversityId: targetUniversityId ?? this.targetUniversityId,
      targetUniversityName: targetUniversityName ?? this.targetUniversityName,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      interviewerPersona: interviewerPersona ?? this.interviewerPersona,
      liveHints: liveHints ?? this.liveHints,
      error: clearError ? null : (error ?? this.error),
      isVapiConnected: isVapiConnected ?? this.isVapiConnected,
      vapiCallId: vapiCallId ?? this.vapiCallId,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class InterviewNotifier extends Notifier<InterviewSessionState> {
  @override
  InterviewSessionState build() {
    return const InterviewSessionState();
  }

  // ── Session lifecycle ────────────────────────────────────────────────────

  Future<void> startSession({
    String sessionType = 'general',
    String? targetUniversityId,
    String? targetUniversityName,
    String language = 'ko',
    String? focusTopic,
    String persona = 'friendly',
    bool timedMode = false,
    int? timeLimitSeconds,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create Session in DB
      final response = await client.from('interview_sessions').insert({
        'student_id': user.id,
        'session_type': sessionType,
        'target_university_id': targetUniversityId,
        'status': 'active',
        'focus_topic': focusTopic,
        'timed_mode': timedMode,
        'time_limit_seconds': timeLimitSeconds,
      }).select().single();

      final newSessionId = response['id'] as String;

      state = state.copyWith(
        sessionId: newSessionId,
        sessionType: sessionType,
        status: 'active',
        messages: [],
        feedback: null,
        targetUniversityId: targetUniversityId,
        targetUniversityName: targetUniversityName,
        selectedLanguage: language,
        interviewerPersona: persona,
        liveHints: [],
        // NOTE: We do NOT call sendMessage here anymore.
        // Vapi handles the greeting via its own firstMessage field.
        // Calling sendMessage here caused a duplicate greeting race condition.
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start interview: ${e.toString()}',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Vapi connection state sync ───────────────────────────────────────────

  /// Called by InterviewActiveView to sync the WebRTC call state into the
  /// global provider so other widgets can react to connection status.
  void setVapiConnected(bool value) {
    state = state.copyWith(isVapiConnected: value);
  }

  void setVapiCallId(String callId) {
    state = state.copyWith(vapiCallId: callId);
  }

  // ── Text-only interview: full AI round-trip ──────────────────────────────

  Future<String?> sendMessage(String studentText, {String language = 'ko'}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      state = state.copyWith(error: 'No active session');
      return null;
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      // Add temporary student message
      if (!studentText.contains('[Interview started')) {
        final newStudentMsg = InterviewMessage(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          role: 'student',
          content: studentText,
          createdAt: DateTime.now().toIso8601String(),
        );
        state = state.copyWith(messages: [...state.messages, newStudentMsg]);
      }

      final client = Supabase.instance.client;

      // Call interview-ai edge function for text-based response
      final response = await client.functions.invoke(
        'interview-ai',
        body: {
          'sessionId': sessionId,
          'studentMessage': studentText,
          'sessionType': state.sessionType,
          'language': state.selectedLanguage,
          'persona': state.interviewerPersona,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'Empty response from AI Interviewer');
      }

      final aiText = data['response'] as String? ?? 'No response generated.';

      final aiMsg = InterviewMessage(
        id: 'interviewer-${DateTime.now().millisecondsSinceEpoch}',
        role: 'interviewer',
        content: aiText,
        createdAt: DateTime.now().toIso8601String(),
      );

      state = state.copyWith(messages: [...state.messages, aiMsg]);
      return aiText;

    } on FunctionException catch (e) {
      final errDetail = (e.details is Map) ? (e.details as Map)['error'] : e.details;
      state = state.copyWith(error: 'AI Interview error: ${errDetail ?? e.toString()}');
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Failed to process answer: ${e.toString()}');
      return null;
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  // ── Vapi mode: transcript logging only (NO AI call) ─────────────────────

  /// Used during a live Vapi WebRTC session to persist the student's
  /// transcript to the DB without triggering a redundant Gemini AI response.
  /// The voice AI (GPT-4o via Vapi) already handles the conversation.
  Future<void> logTranscript(String studentText) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    try {
      final client = Supabase.instance.client;
      await client.from('interview_messages').insert({
        'session_id': sessionId,
        'role': 'student',
        'content': studentText,
      });

      final newStudentMsg = InterviewMessage(
        id: 'vapi-${DateTime.now().millisecondsSinceEpoch}',
        role: 'student',
        content: studentText,
        createdAt: DateTime.now().toIso8601String(),
      );
      state = state.copyWith(messages: [...state.messages, newStudentMsg]);
    } catch (e) {
      // Non-critical — don't surface to user, just log
      debugPrint('Failed to log Vapi transcript: $e');
    }
  }

  // ── End session & feedback ───────────────────────────────────────────────

  Future<Map<String, dynamic>?> endSession({String language = 'ko'}) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return null;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final client = Supabase.instance.client;

      final response = await client.functions.invoke(
        'interview-feedback',
        body: {
          'sessionId': sessionId,
          'language': language,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'Failed to get feedback');
      }

      final fb = data['feedback'] as Map<String, dynamic>;
      
      state = state.copyWith(
        status: 'completed',
        feedback: fb,
        isVapiConnected: false, // Vapi call is over at this point
      );

      return fb;
    } catch (e) {
      state = state.copyWith(error: 'Failed to end session: ${e.toString()}');
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── TTS Audio (fallback for non-Vapi text mode) ──────────────────────────

  /// Extracts MP3 bytes from the ElevenLabs TTS edge function.
  /// Uses InterviewPersonaConfig for voice selection (single source of truth).
  Future<String?> generateTTSAudioPath(String text, String language) async {
    try {
      final client = Supabase.instance.client;
      final token = client.auth.currentSession?.accessToken;
      if (token == null) return null;

      // Centralized voice selection — no more duplicated voice ID strings here
      final voiceId = InterviewPersonaConfig.getVoiceId(state.interviewerPersona, language);

      final edgeUrl = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/elevenlabs-tts');

      final response = await http.post(
        edgeUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'apikey': AppConfig.supabaseAnonKey,
        },
        body: jsonEncode({
          'text': text,
          'voiceId': voiceId,
        }),
      );

      if (response.statusCode == 401 || response.body.contains('Invalid_api_key')) {
        debugPrint('ElevenLabs API Key error (401). Falling back to Browser TTS.');
        return '__BROWSER_TTS__';
      }

      if (response.statusCode != 200) {
        throw Exception('TTS Request failed with ${response.statusCode}: ${response.body}');
      }

      // Save binary to temp local file for playback via just_audio
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(response.bodyBytes);
      
      return file.path;

    } catch (e) {
      state = state.copyWith(error: 'Voice playback error: ${e.toString()}');
      return null;
    }
  }

  // ── Hint generation ──────────────────────────────────────────────────────

  Future<void> getHint(String contextText) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;

    try {
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'interview-ai',
        body: {
          'sessionId': sessionId,
          'studentMessage': contextText,
          'sessionType': state.sessionType,
          'language': state.selectedLanguage,
          'persona': state.interviewerPersona,
          'action': 'get_hint',
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['hints'] != null) {
        final hintsRaw = data['hints'] as String;
        final parsedHints = hintsRaw
            .split('\n')
            .map((s) => s.trim().replaceAll(RegExp(r'^[-*•]\s*'), ''))
            .where((s) => s.isNotEmpty)
            .take(3)
            .toList();
        state = state.copyWith(liveHints: parsedHints);
      }
    } catch (e) {
      debugPrint('Failed to get hints: $e');
    }
  }

  // ── Feedback & History ──────────────────────────────────────────────────

  Future<void> loadFeedback(String targetSessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'interview-feedback',
        body: {
          'sessionId': targetSessionId,
          'language': state.selectedLanguage,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['feedback'] != null) {
        state = state.copyWith(feedback: data['feedback']);
      } else if (data != null && data['error'] != null) {
        state = state.copyWith(error: data['error']);
      }
    } catch (e) {
      debugPrint('Failed to load feedback: $e');
      state = state.copyWith(error: 'Failed to load feedback: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<List<Map<String, dynamic>>> getSessionHistory() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return [];

      final response = await client
          .from('interview_sessions')
          .select('*, universities:target_university_id(name_en, name_ko)')
          .eq('student_id', user.id)
          .order('created_at', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Failed to fetch session history: $e');
      return [];
    }
  }

  Future<String?> fetchRecordingUrl(String vapiCallId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client.functions.invoke(
        'vapi-fetch-recording',
        body: {'callId': vapiCallId},
      );

      final data = response.data as Map<String, dynamic>?;
      return data?['recordingUrl'] as String?;
    } catch (e) {
      debugPrint('Failed to fetch Vapi recording URL: $e');
      return null;
    }
  }

  // ── Reset ────────────────────────────────────────────────────────────────

  void resetSession() {
    state = const InterviewSessionState();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final interviewProvider = NotifierProvider<InterviewNotifier, InterviewSessionState>(() {
  return InterviewNotifier();
});
