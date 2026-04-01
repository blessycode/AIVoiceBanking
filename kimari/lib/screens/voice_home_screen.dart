import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation_entry.dart';
import '../models/dashboard_summary.dart';
import '../models/voice_agent_response.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

enum VoiceUiStatus { booting, listening, processing, speaking, paused, error }

extension VoiceUiStatusPresentation on VoiceUiStatus {
  String get label {
    switch (this) {
      case VoiceUiStatus.booting:
        return 'Booting';
      case VoiceUiStatus.listening:
        return 'Listening';
      case VoiceUiStatus.processing:
        return 'Syncing';
      case VoiceUiStatus.speaking:
        return 'Speaking';
      case VoiceUiStatus.paused:
        return 'Paused';
      case VoiceUiStatus.error:
        return 'Needs Attention';
    }
  }

  IconData get icon {
    switch (this) {
      case VoiceUiStatus.booting:
        return Icons.power_settings_new_rounded;
      case VoiceUiStatus.listening:
        return Icons.mic_rounded;
      case VoiceUiStatus.processing:
        return Icons.sync_rounded;
      case VoiceUiStatus.speaking:
        return Icons.graphic_eq_rounded;
      case VoiceUiStatus.paused:
        return Icons.pause_circle_rounded;
      case VoiceUiStatus.error:
        return Icons.error_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case VoiceUiStatus.booting:
        return AppColors.gold;
      case VoiceUiStatus.listening:
        return AppColors.teal;
      case VoiceUiStatus.processing:
        return AppColors.accentLight;
      case VoiceUiStatus.speaking:
        return AppColors.goldLight;
      case VoiceUiStatus.paused:
        return AppColors.textMuted;
      case VoiceUiStatus.error:
        return AppColors.error;
    }
  }

  String get description {
    switch (this) {
      case VoiceUiStatus.booting:
        return 'Preparing the voice workspace and backend session.';
      case VoiceUiStatus.listening:
        return 'Recording your next banking instruction for up to 6 seconds.';
      case VoiceUiStatus.processing:
        return 'Uploading audio and waiting for the backend agent.';
      case VoiceUiStatus.speaking:
        return 'Jonten is speaking the latest backend response.';
      case VoiceUiStatus.paused:
        return 'The session is ready. Resume to continue the conversation.';
      case VoiceUiStatus.error:
        return 'Something blocked the voice flow. Review the message below.';
    }
  }
}

class VoiceHomeScreen extends StatefulWidget {
  const VoiceHomeScreen({
    super.key,
    this.autoStart = true,
    ApiService? apiService,
    AudioService? audioService,
    TtsService? ttsService,
  }) : _apiService = apiService,
       _audioService = audioService,
       _ttsService = ttsService;

  final bool autoStart;
  final ApiService? _apiService;
  final AudioService? _audioService;
  final TtsService? _ttsService;

  @override
  State<VoiceHomeScreen> createState() => _VoiceHomeScreenState();
}

class _VoiceHomeScreenState extends State<VoiceHomeScreen> {
  static const _sessionPreferenceKey = 'voice_session_id';

  late final ApiService _apiService;
  late final AudioService _audioService;
  late final TtsService _ttsService;

  SharedPreferences? _preferences;

  final List<ConversationEntry> _conversationEntries = <ConversationEntry>[];

  bool _loopEnabled = true;
  bool _turnInFlight = false;
  bool _backendReachable = false;
  String _sessionId = '';
  String _assistantText =
      'Jonten will guide account setup, login, balance checks, transfers, bills, and airtime through the connected backend.';
  String _transcript = '';
  String _language = 'en';
  String _agentState = 'WELCOME';
  bool _isAuthenticated = false;
  int? _userId;
  String? _errorText;
  DashboardSummary? _dashboardSummary;
  VoiceUiStatus _status = VoiceUiStatus.booting;

  @override
  void initState() {
    super.initState();
    _apiService = widget._apiService ?? ApiService();
    _audioService = widget._audioService ?? AudioService();
    _ttsService = widget._ttsService ?? TtsService();
    _loopEnabled = widget.autoStart;
    _status = widget.autoStart ? VoiceUiStatus.booting : VoiceUiStatus.paused;

    unawaited(_ttsService.initialize());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeExperience());
    });
  }

  @override
  void dispose() {
    _apiService.dispose();
    unawaited(_ttsService.dispose());
    unawaited(_audioService.dispose());
    super.dispose();
  }

  Future<void> _initializeExperience() async {
    _preferences ??= await SharedPreferences.getInstance();
    final savedSessionId =
        _preferences?.getString(_sessionPreferenceKey)?.trim() ?? '';
    final reachable = await _apiService.checkHealth();

    if (!mounted) {
      return;
    }

    setState(() {
      _backendReachable = reachable;
    });

    if (savedSessionId.isNotEmpty && reachable) {
      final summary = await _tryFetchDashboardSummary(savedSessionId);
      if (summary != null && mounted) {
        setState(() {
          _sessionId = summary.sessionId;
          _language = summary.language;
          _agentState = summary.state;
          _isAuthenticated = summary.isAuthenticated;
          _userId = summary.userId;
          _dashboardSummary = summary;
          _loopEnabled = false;
          _status = VoiceUiStatus.paused;
          _assistantText = summary.isAuthenticated
              ? 'Restored your authenticated banking session. Resume voice to continue securely.'
              : 'Restored your saved session. Resume voice to continue setup or login.';
          _errorText = null;
        });
        _appendConversation(
          ConversationRole.system,
          title: 'Session Restored',
          body: 'Recovered session ${summary.sessionId} from the backend.',
        );
        return;
      }
    }

    if (savedSessionId.isNotEmpty && !reachable && mounted) {
      setState(() {
        _sessionId = savedSessionId;
        _loopEnabled = false;
        _status = VoiceUiStatus.error;
        _errorText =
            'Saved session found, but the backend is unreachable at ${_apiService.baseUrl}.';
      });
      return;
    }

    if (widget.autoStart) {
      await _bootstrapConversation(startFresh: true);
      return;
    }

    if (mounted) {
      setState(() {
        _status = VoiceUiStatus.paused;
      });
    }
  }

  Future<void> _bootstrapConversation({bool startFresh = false}) async {
    if (_turnInFlight) {
      return;
    }

    if (startFresh || _sessionId.isEmpty) {
      _sessionId = _createSessionId();
      await _persistSessionId(_sessionId);
      _dashboardSummary = null;
      _conversationEntries.clear();
    }

    final reachable = await _apiService.checkHealth();
    if (!reachable) {
      if (!mounted) {
        return;
      }
      setState(() {
        _backendReachable = false;
        _status = VoiceUiStatus.error;
        _errorText =
            'Cannot reach the backend at ${_apiService.baseUrl}. Start FastAPI before opening the voice loop.';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _backendReachable = true;
      _errorText = null;
      _status = VoiceUiStatus.processing;
    });

    try {
      final response = await _apiService.startSession(_sessionId);
      await _handleAgentResponse(response, includeTranscript: false);
      if (_loopEnabled) {
        unawaited(_listenAndSendTurn());
      } else if (mounted) {
        setState(() {
          _status = VoiceUiStatus.paused;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = VoiceUiStatus.error;
        _errorText = error.toString();
      });
    }
  }

  Future<void> _listenAndSendTurn() async {
    if (_turnInFlight || !_loopEnabled) {
      return;
    }

    _turnInFlight = true;
    var continueLoop = false;

    try {
      if (_sessionId.isEmpty) {
        _sessionId = _createSessionId();
        await _persistSessionId(_sessionId);
      }

      final hasPermission = await _audioService.ensurePermission();
      if (!hasPermission) {
        throw const AudioServiceException(
          'Enable microphone permission to continue the voice conversation.',
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = null;
        _status = VoiceUiStatus.listening;
      });

      final audioFile = await _audioService.recordTurn();

      if (!mounted) {
        return;
      }
      setState(() {
        _status = VoiceUiStatus.processing;
      });

      final response = await _apiService.sendVoiceTurn(
        sessionId: _sessionId,
        audioFile: audioFile,
      );
      await _handleAgentResponse(response, includeTranscript: true);
      continueLoop = _loopEnabled;
    } catch (error) {
      final reachable = await _apiService.checkHealth();
      if (!mounted) {
        return;
      }
      setState(() {
        _backendReachable = reachable;
        _status = VoiceUiStatus.error;
        _errorText = error.toString();
      });
      _appendConversation(
        ConversationRole.system,
        title: 'Voice Loop Error',
        body: error.toString(),
      );
    } finally {
      _turnInFlight = false;
    }

    if (continueLoop) {
      unawaited(_listenAndSendTurn());
    }
  }

  Future<void> _handleAgentResponse(
    VoiceAgentResponse response, {
    required bool includeTranscript,
  }) async {
    final reachable = await _apiService.checkHealth();
    if (!mounted) {
      return;
    }

    setState(() {
      _backendReachable = reachable;
      _sessionId = response.sessionId;
      _assistantText = response.responseText;
      _transcript = response.transcript;
      _language = response.language;
      _agentState = response.state;
      _isAuthenticated = response.isAuthenticated;
      _userId = response.userId;
      _status = VoiceUiStatus.speaking;
      _errorText = null;
      if (!response.isAuthenticated) {
        _dashboardSummary = null;
      }
    });

    await _persistSessionId(response.sessionId);

    if (includeTranscript && response.transcript.trim().isNotEmpty) {
      _appendConversation(
        ConversationRole.customer,
        title: 'You',
        body: response.transcript.trim(),
      );
    }

    _appendConversation(
      ConversationRole.assistant,
      title: 'Jonten',
      body: response.responseText,
    );

    if (response.isAuthenticated) {
      await _refreshDashboardSummary();
    }

    await _ttsService.speak(response.responseText, language: response.language);

    if (!mounted) {
      return;
    }

    if (!_loopEnabled) {
      setState(() {
        _status = VoiceUiStatus.paused;
      });
    }
  }

  Future<void> _refreshDashboardSummary() async {
    if (_sessionId.isEmpty) {
      return;
    }

    final summary = await _tryFetchDashboardSummary(_sessionId);
    if (summary == null || !mounted) {
      return;
    }

    setState(() {
      _dashboardSummary = summary;
      _language = summary.language;
      _agentState = summary.state;
      _isAuthenticated = summary.isAuthenticated;
      _userId = summary.userId;
    });
  }

  Future<DashboardSummary?> _tryFetchDashboardSummary(String sessionId) async {
    try {
      return await _apiService.fetchDashboardSummary(sessionId);
    } on ApiException catch (error) {
      if (error.message == 'Session not found.') {
        await _clearPersistedSession();
        return null;
      }
      if (mounted) {
        setState(() {
          _errorText = error.toString();
        });
      }
      return null;
    }
  }

  Future<void> _toggleLoop() async {
    if (_loopEnabled) {
      _loopEnabled = false;
      await _ttsService.stop();
      await _audioService.cancelRecording();
      if (!mounted) {
        return;
      }
      setState(() {
        _status = VoiceUiStatus.paused;
      });
      return;
    }

    _loopEnabled = true;
    if (!mounted) {
      return;
    }
    setState(() {
      _errorText = null;
      _status = VoiceUiStatus.processing;
    });

    if (_sessionId.isEmpty) {
      await _bootstrapConversation(startFresh: true);
      return;
    }

    unawaited(_listenAndSendTurn());
  }

  Future<void> _resetConversation() async {
    await _ttsService.stop();
    await _audioService.cancelRecording();

    final nextSessionId = _createSessionId();
    await _persistSessionId(nextSessionId);

    if (!mounted) {
      return;
    }

    setState(() {
      _sessionId = nextSessionId;
      _assistantText =
          'Starting a fresh voice banking session. The backend welcome message will play next.';
      _transcript = '';
      _language = 'en';
      _agentState = 'WELCOME';
      _isAuthenticated = false;
      _userId = null;
      _errorText = null;
      _dashboardSummary = null;
      _status = VoiceUiStatus.booting;
      _loopEnabled = true;
      _conversationEntries.clear();
    });

    _appendConversation(
      ConversationRole.system,
      title: 'Session Reset',
      body: 'Created a new voice banking session.',
    );

    await _bootstrapConversation();
  }

  void _appendConversation(
    ConversationRole role, {
    required String title,
    required String body,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      _conversationEntries.add(
        ConversationEntry(
          role: role,
          title: title,
          body: body,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _persistSessionId(String value) async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(_sessionPreferenceKey, value);
  }

  Future<void> _clearPersistedSession() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.remove(_sessionPreferenceKey);
  }

  String _createSessionId() {
    final random = Random.secure().nextInt(999999);
    return 'session-${DateTime.now().millisecondsSinceEpoch}-$random';
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return DashboardScreen(
        summary: _dashboardSummary,
        assistantResponse: _assistantText,
        latestTranscript: _transcript,
        voiceStatusLabel: _status.label,
        voiceStatusColor: _status.color,
        voiceControlLabel: _loopEnabled ? 'Pause Voice Agent' : 'Resume Voice',
        voiceGreeting: 'Authenticated backend session active.',
        userDisplayName: _dashboardSummary?.userName ?? 'Secure Customer',
        sessionId: _sessionId,
        language: _language,
        agentState: _agentState,
        userId: _userId,
        conversationEntries: _conversationEntries,
        backendReachable: _backendReachable,
        backendBaseUrl: _apiService.baseUrl,
        onVoiceControlPressed: _toggleLoop,
        onResetConversation: _resetConversation,
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    if (Navigator.canPop(context))
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppColors.textPrimary,
                        tooltip: 'Back',
                      ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jonten Voice Hub',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Live voice banking connected to FastAPI and SQLite',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ConnectionPill(
                      isConnected: _backendReachable,
                      label: _backendReachable ? 'Backend Live' : 'Offline',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(
                        status: _status,
                        assistantText: _assistantText,
                        sessionId: _sessionId,
                        language: _language,
                        agentState: _agentState,
                        backendUrl: _apiService.baseUrl,
                        isAuthenticated: _isAuthenticated,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryActionButton(
                              label: _loopEnabled
                                  ? 'Pause Voice Loop'
                                  : _sessionId.isEmpty
                                  ? 'Start Voice Session'
                                  : 'Resume Listening',
                              icon: _loopEnabled
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.mic_rounded,
                              color: _loopEnabled
                                  ? AppColors.surfaceLight
                                  : AppColors.accent,
                              onPressed: _toggleLoop,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PrimaryActionButton(
                              label: 'New Session',
                              icon: Icons.refresh_rounded,
                              color: AppColors.tealDark,
                              onPressed: _resetConversation,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SectionPanel(
                        title: 'Live Session',
                        icon: _status.icon,
                        accent: _status.color,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _status.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _MetricChip(
                                  label: 'Status',
                                  value: _status.label,
                                  color: _status.color,
                                ),
                                _MetricChip(
                                  label: 'State',
                                  value: _agentState,
                                  color: AppColors.gold,
                                ),
                                _MetricChip(
                                  label: 'Language',
                                  value: _language.toUpperCase(),
                                  color: AppColors.teal,
                                ),
                                _MetricChip(
                                  label: 'Auth',
                                  value: _isAuthenticated ? 'Signed In' : 'Guest',
                                  color: _isAuthenticated
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionPanel(
                        title: 'Conversation Feed',
                        icon: Icons.forum_rounded,
                        accent: AppColors.gold,
                        child: _conversationEntries.isEmpty
                            ? const _EmptyPanel(
                                message:
                                    'The voice feed will populate here after the backend sends the first response.',
                              )
                            : Column(
                                children: _conversationEntries.reversed
                                    .take(8)
                                    .map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _ConversationTile(entry: entry),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 18),
                      _SectionPanel(
                        title: 'Suggested Prompts',
                        icon: Icons.lightbulb_outline_rounded,
                        accent: AppColors.accentLight,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _PromptChip(label: 'Create account'),
                            _PromptChip(label: 'Login to my account'),
                            _PromptChip(label: 'Check my balance'),
                            _PromptChip(label: 'Send money'),
                            _PromptChip(label: 'Pay bill'),
                            _PromptChip(label: 'Buy airtime'),
                          ],
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 18),
                        _SectionPanel(
                          title: 'Issue',
                          icon: Icons.error_outline_rounded,
                          accent: AppColors.error,
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.status,
    required this.assistantText,
    required this.sessionId,
    required this.language,
    required this.agentState,
    required this.backendUrl,
    required this.isAuthenticated,
  });

  final VoiceUiStatus status;
  final String assistantText;
  final String sessionId;
  final String language;
  final String agentState;
  final String backendUrl;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15485A), Color(0xFF0D2230)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: status.color.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: status.color.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(status.icon, color: status.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.label,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Voice-first banking workspace',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            assistantText,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                label: 'Session',
                value: sessionId.isEmpty ? 'Pending' : sessionId,
                color: AppColors.gold,
              ),
              _MetricChip(
                label: 'Lang',
                value: language.toUpperCase(),
                color: AppColors.teal,
              ),
              _MetricChip(
                label: 'State',
                value: agentState,
                color: AppColors.accentLight,
              ),
              _MetricChip(
                label: 'Mode',
                value: isAuthenticated ? 'Authenticated' : 'Entry Flow',
                color: isAuthenticated ? AppColors.success : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Backend target: $backendUrl',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.isConnected, required this.label});

  final bool isConnected;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.entry});

  final ConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final config = switch (entry.role) {
      ConversationRole.assistant => (
          color: AppColors.gold,
          icon: Icons.graphic_eq_rounded,
        ),
      ConversationRole.customer => (
          color: AppColors.teal,
          icon: Icons.mic_rounded,
        ),
      ConversationRole.system => (
          color: AppColors.accentGlow,
          icon: Icons.info_outline_rounded,
        ),
    };

    final hour = entry.timestamp.hour % 12 == 0 ? 12 : entry.timestamp.hour % 12;
    final minute = entry.timestamp.minute.toString().padLeft(2, '0');
    final suffix = entry.timestamp.hour >= 12 ? 'PM' : 'AM';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: config.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(config.icon, color: config.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$hour:$minute $suffix',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentLight.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
