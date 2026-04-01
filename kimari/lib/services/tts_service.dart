import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  Future<void> speak(String text, {String language = 'en'}) async {
    await initialize();
    await _tts.stop();
    await _tts.setLanguage(_resolveVoiceLanguage(language));
    await _tts.speak(text);
  }

  Future<void> stop() async {
    if (_initialized) {
      await _tts.stop();
    }
  }

  Future<void> dispose() async {
    await stop();
  }

  String _resolveVoiceLanguage(String code) {
    switch (code) {
      case 'sn':
        return 'en-ZW';
      case 'nd':
        return 'en-ZA';
      default:
        return 'en-US';
    }
  }
}
