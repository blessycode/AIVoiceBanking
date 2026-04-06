import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/dashboard_summary.dart';
import '../models/voice_agent_response.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl, http.Client? client})
    : _baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'BACKEND_URL',
            defaultValue: 'http://10.0.2.2:8000',
          ),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  String get baseUrl => _baseUrl;

  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 300;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<VoiceAgentResponse> startSession(String sessionId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/voice-agent/start'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'session_id': sessionId}),
          )
          .timeout(const Duration(seconds: 20));

      return _parseResponse(response);
    } on SocketException {
      throw ApiException(_backendUnavailableMessage());
    } on TimeoutException {
      throw ApiException(
        'Backend timed out at $_baseUrl. Check that FastAPI is running and reachable from the device.',
      );
    }
  }

  Future<VoiceAgentResponse> sendVoiceTurn({
    required String sessionId,
    required File audioFile,
  }) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/voice-agent'))
            ..fields['session_id'] = sessionId
            ..files.add(
              await http.MultipartFile.fromPath('audio', audioFile.path),
            );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _parseResponse(response);
    } on SocketException {
      throw ApiException(_backendUnavailableMessage());
    } on FileSystemException catch (error) {
      throw ApiException(
        'The recorded audio file was not available for upload. Please try the voice turn again. ${error.message}',
      );
    } on TimeoutException {
      throw ApiException(
        'Backend timed out while processing the voice turn. Wait for the backend to warm up, then try again. Check Render logs if it keeps failing.',
      );
    }
  }

  Future<DashboardSummary> fetchDashboardSummary(String sessionId) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/voice-agent/summary/$sessionId'))
          .timeout(const Duration(seconds: 20));

      final payload = _parsePayload(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = payload is Map<String, dynamic>
            ? payload['detail'] as String? ?? 'Unable to load dashboard summary.'
            : 'Unable to load dashboard summary.';
        throw ApiException(message);
      }

      if (payload is! Map<String, dynamic>) {
        throw const ApiException('Backend returned an invalid dashboard payload.');
      }

      return DashboardSummary.fromJson(payload);
    } on SocketException {
      throw ApiException(_backendUnavailableMessage());
    } on TimeoutException {
      throw ApiException(
        'Backend timed out while loading the account summary.',
      );
    }
  }

  Future<TransactionsResponse> fetchTransactions(
    String sessionId, {
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_baseUrl/voice-agent/transactions/$sessionId?limit=$limit',
            ),
          )
          .timeout(const Duration(seconds: 20));

      final payload = _parsePayload(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = payload is Map<String, dynamic>
            ? payload['detail'] as String? ?? 'Unable to load transactions.'
            : 'Unable to load transactions.';
        throw ApiException(message);
      }

      if (payload is! Map<String, dynamic>) {
        throw const ApiException(
          'Backend returned an invalid transactions payload.',
        );
      }

      return TransactionsResponse.fromJson(payload);
    } on SocketException {
      throw ApiException(_backendUnavailableMessage());
    } on TimeoutException {
      throw ApiException(
        'Backend timed out while loading the transactions history.',
      );
    }
  }

  String _backendUnavailableMessage() {
    return 'Backend is unreachable at $_baseUrl. Start FastAPI with '
        '".venv312/bin/uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000". '
        'Use 10.0.2.2 on the Android emulator and your laptop LAN IP on a physical device.';
  }

  VoiceAgentResponse _parseResponse(http.Response response) {
    final dynamic payload = _parsePayload(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? payload['detail'] as String? ?? 'Backend request failed.'
          : 'Backend request failed.';
      throw ApiException(message);
    }

    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Backend returned an invalid JSON payload.');
    }

    return VoiceAgentResponse.fromJson(payload);
  }

  dynamic _parsePayload(http.Response response) {
    return response.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(response.body);
  }

  void dispose() {
    _client.close();
  }
}
