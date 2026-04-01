class VoiceAgentResponse {
  const VoiceAgentResponse({
    required this.sessionId,
    required this.transcript,
    required this.state,
    required this.language,
    required this.isAuthenticated,
    required this.userId,
    required this.responseText,
  });

  final String sessionId;
  final String transcript;
  final String state;
  final String language;
  final bool isAuthenticated;
  final int? userId;
  final String responseText;

  factory VoiceAgentResponse.fromJson(Map<String, dynamic> json) {
    return VoiceAgentResponse(
      sessionId: json['session_id'] as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
      state: json['state'] as String? ?? 'UNKNOWN',
      language: json['language'] as String? ?? 'en',
      isAuthenticated: json['is_authenticated'] as bool? ?? false,
      userId: json['user_id'] as int?,
      responseText: json['response_text'] as String? ?? '',
    );
  }
}
