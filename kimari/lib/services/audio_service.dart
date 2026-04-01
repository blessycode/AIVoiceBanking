import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> ensurePermission() {
    return _recorder.hasPermission();
  }

  Future<File> recordTurn({
    Duration maxDuration = const Duration(seconds: 6),
  }) async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      throw const AudioServiceException('Microphone permission not granted.');
    }

    final recordingsDir = await _getRecordingsDirectory();
    final fileName = 'voice_turn_${DateTime.now().millisecondsSinceEpoch}.wav';
    final outputPath = '${recordingsDir.path}/$fileName';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: outputPath,
    );

    await Future<void>.delayed(maxDuration);

    final recordingPath = await _recorder.stop();
    final resolvedPath = (recordingPath?.isNotEmpty ?? false)
        ? recordingPath!
        : outputPath;

    final audioFile = await _waitForRecordedFile(
      primaryPath: resolvedPath,
      fallbackPath: outputPath,
    );

    if (audioFile == null) {
      throw const AudioServiceException('Recording did not complete.');
    }

    return audioFile;
  }

  Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  Future<void> dispose() async {
    await cancelRecording();
    await _recorder.dispose();
  }

  Future<Directory> _getRecordingsDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final recordingsDir = Directory('${supportDir.path}/voice_turns');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    return recordingsDir;
  }

  Future<File?> _waitForRecordedFile({
    required String primaryPath,
    required String fallbackPath,
  }) async {
    final candidates = <String>{primaryPath, fallbackPath}.toList();

    for (var attempt = 0; attempt < 20; attempt++) {
      for (final path in candidates) {
        final file = File(path);
        if (await file.exists()) {
          final length = await file.length();
          if (length > 0) {
            return file;
          }
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    return null;
  }
}

class AudioServiceException implements Exception {
  const AudioServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
