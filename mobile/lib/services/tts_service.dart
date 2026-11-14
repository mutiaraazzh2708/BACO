import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    await _tts.setLanguage("id-ID");
    await _tts.setSpeechRate(0.48); // Kecepatan ramah lansia/tunanetra
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      _isPlaying = true;
    });

    _tts.setCompletionHandler(() {
      _isPlaying = false;
    });

    _tts.setErrorHandler((msg) {
      _isPlaying = false;
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await stop();
    _isPlaying = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _tts.stop();
  }
}

