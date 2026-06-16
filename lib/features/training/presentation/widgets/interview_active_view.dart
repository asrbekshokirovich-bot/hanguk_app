import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vapi/vapi.dart';
import 'dart:async';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/interview_repository.dart';
import '../../data/vapi_event_parser.dart' as vapi;

class InterviewActiveView extends ConsumerStatefulWidget {
  const InterviewActiveView({super.key});

  @override
  ConsumerState<InterviewActiveView> createState() =>
      _InterviewActiveViewState();
}

class _InterviewActiveViewState extends ConsumerState<InterviewActiveView>
    with WidgetsBindingObserver {
  VapiClient? _client;
  VapiCall? _call;
  StreamSubscription? _eventSub;
  // Connection phase model:
  //   _isConnecting  → handshake in flight, before the call goes live.
  //   _isCallActive  → the call is LIVE (Vapi sent 'call-start'/'listening').
  // Previously _isCallActive was set true the instant _startCall ran, which
  // conflated "connecting" with "live" and — combined with waitUntilActive —
  // left the UI stuck on "Connecting…" forever when the early call-start /
  // speech-start events were emitted before the listener was attached.
  bool _isConnecting = true;
  bool _isCallActive = false;
  bool _isAI_Speaking = false;
  bool _firstMessageReceived = false;
  String _currentWords = '';
  Timer? _silenceTimer;
  bool _showCoachingWarning = false;
  // _errorMessage holds a raw (likely English) detail string from the
  // Vapi SDK or a status-update payload. The locale-aware "Connection
  // interrupted: …" wrapper is applied in _buildStatusText below.
  String? _errorMessage;
  bool _isStopping = false;
  bool _aiRequestedEnd = false;
  bool _didEndSession = false;
  Timer? _forceEndTimer;
  Timer? _timeLimitTimer;
  // Fires if the call never goes live within the deadline, so a silently
  // stuck handshake surfaces as an error instead of an endless spinner.
  Timer? _connectTimer;
  static const _connectTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVapi();
  }

  // Audit U18: backgrounding the app mid-call should end the session
  // cleanly instead of leaving an orphan Vapi WebRTC connection and a
  // permanently-`active` DB row.
  //
  // Conservative choice: **end on background.** The alternative is
  // pause-and-resume — much more complex, Vapi-side fragile (mic
  // permission may revoke, peers may renegotiate), and a longer-lived
  // session means more cost. The audit's stated default is correct;
  // we revisit if users complain that backgrounding for a Slack
  // notification kills their practice.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // End on background whether the call is live OR still connecting, so we
      // never leave an orphan WebRTC connection / permanently-active DB row.
      if (!_didEndSession && (_isCallActive || _isConnecting)) {
        _didEndSession = true;
        unawaited(_completeAutoEnd());
      }
    }
  }

  Future<void> _initVapi() async {
    // Await Web SDK JS injection securely before instantiating to prevent silent crashes
    try {
      await VapiClient.platformInitialized.future;
    } catch (e) {
      debugPrint('Vapi Web SDK initialization failed: $e');
    }

    // AppConfig centralizes the Vapi key — no more hardcoded strings in widgets
    _client = VapiClient(AppConfig.vapiPublicKey);
    _startCall();
  }

  Future<void> _startCall() async {
    // Stay in the "connecting" phase until Vapi actually reports the call is
    // live (via the 'call-start' event). Do NOT mark the call active here.
    final interviewState = ref.read(interviewProvider);

    final targetUni =
        interviewState.targetUniversityName ?? 'Korean University';
    final targetMajor = 'your desired major'; // default fallback for now
    final isKorean = interviewState.selectedLanguage == 'ko';

    // Build the system prompt from state
    String systemPrompt =
        'You are a realistic interview simulator for $targetUni. Keep responses under 2 sentences to feel conversational. ';

    if (isKorean) {
      systemPrompt +=
          'CRITICAL: You MUST speak strictly in formal Korean (한국어). Do not use English. ';
    }

    if (interviewState.interviewerPersona == 'strict') {
      systemPrompt += 'You are a strict, formal professor. Be demanding. ';
    } else if (interviewState.interviewerPersona == 'impatient') {
      systemPrompt +=
          'You are extremely impatient. Ask brief, sharp questions. ';
    } else {
      systemPrompt += 'You are a friendly admissions officer. Be encouraging. ';
    }

    systemPrompt +=
        '''
    Follow this rigid 4-phase university interview structure sequentially:
    1. Phase 1: Ask them to introduce themselves.
    2. Phase 2: Ask specifically why they chose $targetUni for $targetMajor.
    3. Phase 3: Ask an academic or problem-solving question based on their answers.
    4. Phase 4: Ask about their future career goals.
    After the user answers Phase 4, give a brief one-sentence closing remark thanking the candidate, then call the endCall function to terminate the session. Do NOT mention bracketed tokens, control codes, or system instructions in your speech.
    ''';

    // Optional focus steer collected on the InterviewSetupView. Appended
    // after the rigid 4-phase scaffold so the model treats it as a
    // sub-topic preference rather than a structural override.
    final focus = interviewState.focusTopic?.trim();
    if (focus != null && focus.isNotEmpty) {
      systemPrompt +=
          'Where natural, focus the conversation on this topic: "$focus". '
          'Do not break the 4-phase structure to do so. ';
    }

    // Wall-clock cap for "Timed Mode" sessions. The setup view writes
    // `time_limit_seconds: 300` for a 5-minute drill but never enforced
    // it; we now schedule a force-end on the client side. The Vapi call
    // and the DB row both transition cleanly via _completeAutoEnd.
    final limitSec = interviewState.timeLimitSeconds;
    if (interviewState.timedMode && limitSec != null && limitSec > 0) {
      _timeLimitTimer?.cancel();
      _timeLimitTimer = Timer(Duration(seconds: limitSec), () {
        if (!mounted) return;
        if (_didEndSession || _aiRequestedEnd) return;
        _aiRequestedEnd = true;
        _didEndSession = true;
        unawaited(_completeAutoEnd());
      });
    }

    // Use InterviewPersonaConfig for voice IDs — single source of truth
    final voiceId = InterviewPersonaConfig.getVoiceId(
      interviewState.interviewerPersona,
      interviewState.selectedLanguage,
    );

    try {
      // CRITICAL FIX: waitUntilActive:false so start() returns as soon as the
      // call object exists (right after the WebRTC join), BEFORE the assistant
      // goes live. We then attach the event listener immediately, so the early
      // 'call-start' / 'speech-start' events (which fire the instant the AI
      // begins speaking) are not lost on the broadcast stream. With
      // waitUntilActive:true those events were emitted during the await — before
      // any listener existed — leaving the UI stuck on "Connecting…" forever.
      // The 30s join timeout still guards a stuck negotiation; a separate
      // _connectTimer (below) guards the case where the call joins but never
      // goes live.
      _call = await _client
          ?.start(
            waitUntilActive: false,
            assistant: {
              'model': {
                'provider': 'openai',
                'model': 'gpt-4o',
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                ],
              },
              'voice': {
                'provider': '11labs',
                'voiceId': voiceId,
                // eleven_turbo_v2_5 has materially better Korean prosody than
                // eleven_multilingual_v2. The voice ID itself must also be a
                // Korean-native voice for full effect (see AppConfig.voiceIdKo*).
                'model': 'eleven_turbo_v2_5',
              },
              'endCallFunctionEnabled': true,
              'recordingEnabled': true,
              // Force the AI to speak first on connect rather than waiting for
              // user voice activity. Without this flag, Vapi treats the call as
              // user-initiated and the firstMessage is never delivered.
              'firstMessageMode': 'assistant-speaks-first',
              // The AI always opens the conversation AND asks the first
              // question itself, so the student never has to start. Keep it a
              // concrete opening question (self-introduction) rather than a
              // generic "are you ready?".
              'firstMessage': isKorean
                  ? '안녕하세요! $targetUni 지원자님, 지금부터 면접을 시작하겠습니다. '
                        '먼저 간단하게 자기소개를 해 주시겠어요?'
                  : 'Hello! Welcome to your interview for $targetUni. '
                        'To begin, could you please introduce yourself briefly?',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'Vapi handshake timed out after 30 seconds.',
            ),
          );

      // If the user exited while we were still joining, tear the call down
      // immediately instead of leaking a live mic/WebRTC session.
      if (!mounted || _isStopping) {
        try {
          await _call?.stop();
        } catch (_) {
          // already ended — nothing to hang up
        }
        _call?.dispose();
        _client?.dispose();
        return;
      }

      // Persist the Vapi call id now (we have it post-join); the global
      // "connected" flag is flipped on the 'call-start' event below.
      if (_call != null) {
        ref.read(interviewProvider.notifier).setVapiCallId(_call!.id);
      }
      debugPrint('[VAPI] Joined call ${_call?.id}; awaiting call-start.');

      // Guard: if the call joined but never goes live, surface an error and
      // let the user retry/exit instead of spinning on "Connecting…".
      _connectTimer?.cancel();
      _connectTimer = Timer(_connectTimeout, () {
        if (!mounted || _isCallActive || _didEndSession) return;
        ref.read(interviewProvider.notifier).setVapiConnected(false);
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Connection timed out. Please try again.';
        });
      });

      _eventSub = _call?.onEvent.listen((event) {
        if (!mounted) return;

        final eventLabel = event.label;
        final eventValue = event.value;

        // The call is now LIVE — leave the connecting phase. This is the
        // event that previously got lost, stranding the UI on "Connecting…".
        if (eventLabel == 'call-start') {
          _connectTimer?.cancel();
          ref.read(interviewProvider.notifier).setVapiConnected(true);
          setState(() {
            _isConnecting = false;
            _isCallActive = true;
          });
        } else if (eventLabel == 'call-end') {
          debugPrint('[VAPI] Call ended.');
          _connectTimer?.cancel();
          // Ended before ever going live → it failed to connect. Surface it
          // instead of leaving a dead "Connecting…" screen.
          if (!_didEndSession && !_isCallActive && _errorMessage == null) {
            ref.read(interviewProvider.notifier).setVapiConnected(false);
            setState(() {
              _isConnecting = false;
              _errorMessage = 'Could not connect the call. Please try again.';
            });
          }
        } else if (eventLabel == 'status-update' ||
            eventLabel == 'statusUpdate') {
          debugPrint('[VAPI STATUS UPDATE] $eventValue');
          final statusString = eventValue.toString().toLowerCase();

          if (statusString.contains('error')) {
            ref.read(interviewProvider.notifier).setVapiConnected(false);
            if (mounted) {
              // Audit U12: surface the actual error string from the
              // event payload instead of a misleading generic message.
              // Fall back to the generic copy only when nothing usable
              // is available.
              String? extractedDetail;
              if (eventValue is Map) {
                final m = eventValue;
                final v =
                    m['errorMsg'] ??
                    m['message'] ??
                    m['error'] ??
                    m['detail'] ??
                    m['status'];
                if (v != null) extractedDetail = v.toString();
              }
              extractedDetail ??= eventValue.toString();
              if (extractedDetail.length > 240) {
                extractedDetail = '${extractedDetail.substring(0, 240)}…';
              }
              setState(() {
                _isConnecting = false;
                _isCallActive = false;
                _isAI_Speaking = false;
                // Store raw detail; _buildStatusText wraps it with
                // l.connectionInterrupted at render time so the wrapper
                // follows the active locale.
                _errorMessage = extractedDetail;
              });
            }
          }
        }

        if (eventLabel == 'message' && eventValue is Map) {
          final eventType = eventValue['type'];

          if (eventType == 'speech-start') {
            _connectTimer?.cancel();
            // Defensive: if 'call-start' was somehow missed, the AI speaking
            // is unambiguous proof the call is live.
            ref.read(interviewProvider.notifier).setVapiConnected(true);
            setState(() {
              _isConnecting = false;
              _isCallActive = true;
              _isAI_Speaking = true;
              _firstMessageReceived = true;
              _currentWords = '';
            });
          } else if (eventType == 'speech-end') {
            setState(() {
              _isAI_Speaking = false;
            });
            // If the AI has invoked endCall, wait until its closing remark
            // finishes speaking before tearing down. This is the auto-end
            // path — Task 3 of interview-training-fixes.plan.md.
            if (_aiRequestedEnd && !_didEndSession) {
              _didEndSession = true;
              _forceEndTimer?.cancel();
              unawaited(_completeAutoEnd());
            }
          } else if (eventType == 'tool-calls' ||
              eventType == 'function-call') {
            // Vapi emits 'tool-calls' (newer) or 'function-call' (older) when
            // the AI invokes a built-in tool. Listen for the endCall function.
            if (_isEndCallTool(eventValue) && !_aiRequestedEnd) {
              _aiRequestedEnd = true;
              // Fallback: if speech-end never fires (network glitch), force
              // teardown after 8 seconds so the user is not stuck.
              _forceEndTimer = Timer(const Duration(seconds: 8), () {
                if (_aiRequestedEnd && !_didEndSession && mounted) {
                  _didEndSession = true;
                  unawaited(_completeAutoEnd());
                }
              });
            }
          } else if (eventType == 'transcript') {
            final transcriptRole = eventValue['role']?.toString();
            final transcriptText = eventValue['transcript'] as String?;
            final isFinal = eventValue['transcriptType'] == 'final';
            if (transcriptText == null || transcriptText.isEmpty) {
              // skip empty events
            } else if (transcriptRole == 'user') {
              setState(() {
                _currentWords = transcriptText;
              });
              _checkCoachingWarnings(transcriptText);
              if (isFinal) {
                ref
                    .read(interviewProvider.notifier)
                    .logTranscript(transcriptText);
                _resetSilenceTimer();
              }
            } else if (transcriptRole == 'assistant' && isFinal) {
              // Persist the interviewer's spoken response too — without it
              // the `interview-feedback` Edge Function scores a one-sided
              // conversation. See audit F9.
              ref
                  .read(interviewProvider.notifier)
                  .logTranscriptWithRole(transcriptText, 'assistant');
            }
          }
        }
      });
    } catch (e, st) {
      debugPrint('Vapi Start Error Type: ${e.runtimeType}');
      debugPrint('Vapi Start Error: $e');
      debugPrint('Vapi StackTrace: $st');
      // Notify provider of failed connection so UI can react globally
      _connectTimer?.cancel();
      ref.read(interviewProvider.notifier).setVapiConnected(false);
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isCallActive = false;
          // Expose explicit native parsing errors and connection timeouts dynamically to the UI!
          _errorMessage = e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceAll('VapiStartCallException: ', 'Vapi Engine Error: ');
        });
      }
    }
  }

  /// Centralized stop/cleanup for the Vapi call.
  /// Always call this instead of calling _call?.dispose() directly.
  Future<void> _stopCall() async {
    if (_isStopping) return;
    _isStopping = true;

    _silenceTimer?.cancel();
    _forceEndTimer?.cancel();
    _timeLimitTimer?.cancel();
    _connectTimer?.cancel();
    await _eventSub?.cancel();
    // CRITICAL: the hang-up (`leave()`) must FULLY COMPLETE before we
    // `dispose()` the underlying Daily client. Previously these were fired
    // back-to-back without awaiting, so on exit during the connect phase the
    // native client got torn down mid-`leave()` — a race that froze the UI
    // thread ("app isn't responding"). Await the stop, swallow the
    // already-ended case, then dispose.
    try {
      await _call?.stop();
    } catch (_) {
      // VapiCallEndedException (or any teardown error) — already gone.
    }
    _call?.dispose();
    _client?.dispose();
    // Sync disconnected state to global provider safely
    if (mounted) {
      ref.read(interviewProvider.notifier).setVapiConnected(false);
      setState(() {
        _isConnecting = false;
        _isCallActive = false;
        _isAI_Speaking = false;
      });
    }
  }

  /// Detects whether a Vapi 'tool-calls' or 'function-call' event
  /// represents the built-in `endCall` function being invoked by the
  /// AI. Delegates to the pure-Dart `vapi.isEndCallTool` helper so the
  /// logic is unit-testable without a widget tree.
  bool _isEndCallTool(Map eventValue) => vapi.isEndCallTool(eventValue);

  /// Tear down the call and ask the provider to fetch feedback. Riverpod will
  /// flip state.status to 'completed', which causes InterviewScreen to swap
  /// the active view out for the post-session view.
  Future<void> _completeAutoEnd() async {
    final lang = ref.read(interviewProvider).selectedLanguage;
    await _stopCall();
    if (!mounted) return;
    await ref.read(interviewProvider.notifier).endSession(language: lang);
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 8), () {
      if (_isCallActive && !_isAI_Speaking && mounted && !_isStopping) {
        ref
            .read(interviewProvider.notifier)
            .getHint(
              _currentWords.isEmpty
                  ? 'The student is stuck and said nothing.'
                  : _currentWords,
            );
      }
    });
  }

  // Word-boundary aware. Audit U13: prior version split on raw substrings
  // so 'um' matched inside 'umbrella'. RegExp(r'\bum\b') etc. is correct
  // for Latin script; Korean fillers don't have word boundaries the same
  // way so we keep the substring match for those (they're short particles
  // that rarely produce false positives in practice).
  static final RegExp _enFillers = RegExp(
    r'\b(?:um+|uh+|like|you know)\b',
    caseSensitive: false,
  );
  static const List<String> _koFillers = ['그냥', '음', '어'];

  void _checkCoachingWarnings(String text) {
    if (text.isEmpty) return;
    final lower = text.toLowerCase();
    final enHits = _enFillers.allMatches(lower).length;
    var koHits = 0;
    for (final filler in _koFillers) {
      koHits += lower.split(filler).length - 1;
    }
    final fillerCount = enHits + koHits;
    if (fillerCount >= 4) {
      setState(() {
        _showCoachingWarning = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Delegate to _stopCall for centralized cleanup — ensures stop() is
    // always awaited before dispose(). Fire-and-forget since a synchronous
    // dispose() can't await; the sequencing inside _stopCall still
    // guarantees leave()→dispose() ordering on the call objects.
    unawaited(_stopCall());
    // Audit F14: if the user backs out without ever triggering
    // _completeAutoEnd (no AI-end, no manual end button, no time-limit
    // expiry), mark the row as 'abandoned' so history-replay isn't
    // littered with permanently-active sessions.
    if (!_didEndSession) {
      final notifier = ref.read(interviewProvider.notifier);
      // Fire-and-forget — the network call shouldn't block widget teardown.
      unawaited(notifier.markAbandoned());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(interviewProvider);

    return PopScope(
      // While the call is live (or still connecting/preparing), the system
      // back gesture must run the SAME clean end→feedback path as the
      // on-screen button — never an abrupt route pop that tears down Vapi
      // unsequenced and can freeze the UI. Once the session has ended we let
      // the pop through.
      canPop: _didEndSession,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _didEndSession) return;
        _didEndSession = true;
        unawaited(_completeAutoEnd());
      },
      child: Stack(
        children: [
          Column(
            children: [
              // University Indicator
            if (state.targetUniversityName != null)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.vibrantLime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.vibrantLime.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school,
                      color: AppColors.vibrantLime,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        state.targetUniversityName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.vibrantLime,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_showCoachingWarning)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error),
                ),
                child: Text(
                  '⚠️ ${l.coachingFiller}',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            // AI Avatar
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: _isAI_Speaking
                      ? AppColors.vibrantLime
                      : Colors.white10,
                  width: _isAI_Speaking ? 4 : 1,
                ),
                boxShadow: _isAI_Speaking
                    ? [
                        BoxShadow(
                          color: AppColors.vibrantLime.withValues(alpha: 0.5),
                          blurRadius: 40,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.psychology, color: Colors.white54, size: 80),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.selectedLanguage.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _buildStatusText(l),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _errorMessage != null
                    ? AppColors.error
                    : (_isAI_Speaking
                          ? AppColors.error
                          : (_isCallActive
                                ? AppColors.vibrantLime
                                : Colors.white54)),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),

            // Transcript & controls panel
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.liveHints.isNotEmpty && _isCallActive) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.royalBlue.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.lifelineHintsTitle,
                              style: const TextStyle(
                                color: AppColors.royalBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...state.liveHints.map(
                              (h) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• $h',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Audit U14: show a two-sided ledger of the last few
                    // turns instead of just the very last student utterance.
                    // While Vapi is mid-utterance, live partial transcript
                    // is also shown at the top.
                    Flexible(
                      child: SingleChildScrollView(
                        reverse: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_isCallActive && _currentWords.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  _currentWords,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            for (final m in _lastTurns(state.messages, 6))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 64,
                                      child: Text(
                                        m.role == 'interviewer'
                                            ? l.speakerAi
                                            : l.speakerYou,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: m.role == 'interviewer'
                                              ? AppColors.vibrantLime
                                              : Colors.white54,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        m.content,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          height: 1.45,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () {
                        // Single exit button → ALWAYS go to the feedback screen
                        // and let the AI generate feedback from the transcript.
                        // (Even a short/early-ended session is marked completed
                        // and openable from History, never silently abandoned.)
                        if (_didEndSession) return;
                        _didEndSession = true;
                        unawaited(_completeAutoEnd());
                      },
                      child: Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white10,
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.endInterview,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
          if (state.isProcessing || state.isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.vibrantLime),
            ),
        ],
      ),
    );
  }

  /// Returns the most-recent [maxTurns] interview messages in
  /// chronological order, after stripping the synthetic
  /// "[Interview started …]" sentinel a previous version of
  /// `sendMessage` used to emit.
  List<InterviewMessage> _lastTurns(
    List<InterviewMessage> messages,
    int maxTurns,
  ) {
    final cleaned = messages
        .where((m) => !m.content.contains('[Interview started'))
        .toList(growable: false);
    if (cleaned.length <= maxTurns) return cleaned;
    return cleaned.sublist(cleaned.length - maxTurns);
  }

  String _buildStatusText(AppLocalizations l) {
    if (_errorMessage != null) return l.connectionInterrupted(_errorMessage!);
    if (_aiRequestedEnd) return l.wrappingUp;
    if (_isAI_Speaking) return l.aiSpeaking;
    // Still establishing the call / waiting for the interviewer to greet.
    if (_isConnecting) return l.greetWait;
    if (_isCallActive && !_firstMessageReceived) {
      return l.greetWait;
    }
    if (_isCallActive) return l.yourTurn;
    return l.connecting;
  }
}
