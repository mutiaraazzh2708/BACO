import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  double _currentMultiplier = 1.0;

  bool get isPlaying => _isPlaying;
  double get currentMultiplier => _currentMultiplier;

  Future<void> init() async {
    await _tts.setLanguage("id-ID");
    await _tts.setSpeechRate(0.48); // Kecepatan normal awal ramah lansia
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

  Future<void> setSpeedMultiplier(double multiplier) async {
    _currentMultiplier = multiplier;
    // Pada flutter_tts Android, speech rate berkisar 0.0 - 1.0
    // 0.36 = 0.75x (pelan & jelas untuk lansia)
    // 0.48 = 1.0x (normal)
    // 0.60 = 1.25x (cepat)
    final rate = (0.48 * multiplier).clamp(0.2, 0.9);
    await _tts.setSpeechRate(rate);
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
