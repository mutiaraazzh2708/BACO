import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/analysis_result.dart';
import '../services/tts_service.dart';
import 'ask_screen.dart';

class ResultScreen extends StatefulWidget {
  final AnalysisResult result;
  final File? imageFile;
  final String bahasa; // 'id' atau 'min'

  const ResultScreen({
    super.key,
    required this.result,
    this.imageFile,
    required this.bahasa,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TtsService _ttsService = TtsService();
  late String _currentBahasa;
  int _zoomPercent = 0; // Rentang 0% s/d 100%
  double _fontScale = 1.0;
  bool _isPlaying = false;
  bool _isHighContrast = false;
  double _currentSpeed = 1.0;
  Timer? _playbackTimer;
  int _elapsedSeconds = 0;
  int _totalSeconds = 20;

  void _zoomIn() {
    if (_zoomPercent < 100) {
      HapticFeedback.selectionClick();
      setState(() {
        _zoomPercent = (_zoomPercent + 10).clamp(0, 100);
        _fontScale = 1.0 + (_zoomPercent / 100.0) * 0.30;
      });
    }
  }

  void _zoomOut() {
    if (_zoomPercent > 0) {
      HapticFeedback.selectionClick();
      setState(() {
        _zoomPercent = (_zoomPercent - 10).clamp(0, 100);
        _fontScale = 1.0 + (_zoomPercent / 100.0) * 0.30;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _currentBahasa = widget.bahasa;
    _currentSpeed = _ttsService.currentMultiplier;
    _speakContent();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _ttsService.onCompletion = null;
    _ttsService.stop();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  void _speakContent() {
    _playbackTimer?.cancel();
    final text = widget.result.toSpeechText(bahasa: _currentBahasa);
    final estimated = ((text.length / (11.5 * _currentSpeed)).ceil()).clamp(5, 360);

    setState(() {
      _isPlaying = true;
      _elapsedSeconds = 0;
      _totalSeconds = estimated;
    });

    _ttsService.onCompletion = () {
      if (mounted) {
        _playbackTimer?.cancel();
        setState(() {
          _isPlaying = false;
          _elapsedSeconds = 0;
        });
      }
    };

    _ttsService.speak(text);

    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_elapsedSeconds < _totalSeconds) {
        setState(() {
          _elapsedSeconds++;
        });
      } else if (_elapsedSeconds < _totalSeconds + 10) {
        setState(() {
          _elapsedSeconds++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isPlaying = false;
          _elapsedSeconds = 0;
        });
      }
    });
  }

  void _togglePlayPause() {
    HapticFeedback.selectionClick();
    if (_isPlaying) {
      _playbackTimer?.cancel();
      _ttsService.stop();
      setState(() {
        _isPlaying = false;
        _elapsedSeconds = 0;
      });
    } else {
      _speakContent();
    }
  }

  void _cycleSpeed() async {
    HapticFeedback.selectionClick();
    double nextSpeed;
    String label;
    if (_currentSpeed == 1.0) {
      nextSpeed = 1.25;
      label = "1.25x (Cepat)";
    } else if (_currentSpeed == 1.25) {
      nextSpeed = 0.75;
      label = "0.75x (Pelan & Jelas untuk Lansia)";
    } else {
      nextSpeed = 1.0;
      label = "1.0x (Normal)";
    }

    setState(() {
      _currentSpeed = nextSpeed;
    });

    await _ttsService.setSpeedMultiplier(nextSpeed);

    if (_isPlaying) {
      _speakContent();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Kecepatan Suara: $label"),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleHighContrast() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isHighContrast = !_isHighContrast;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMinang = _currentBahasa == 'min';

    final bgCol = _isHighContrast ? Colors.black : const Color(0xFFF8FAFC);
    final cardCol = _isHighContrast ? const Color(0xFF141414) : Colors.white;
    final primaryCol = _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E56A0);
    final textCol = _isHighContrast ? Colors.white : Colors.black87;
    final borderCol = _isHighContrast ? const Color(0xFFFFD700) : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isMinang ? "Hasil Analisis" : "Hasil Analisis",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textCol),
        ),
        centerTitle: true,
        backgroundColor: cardCol,
        foregroundColor: textCol,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(Icons.hearing, color: primaryCol),
            onPressed: _speakContent,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Toggle Bahasa Pill (Bahasa Indonesia / Baso Minang) ---
              Container(
                decoration: BoxDecoration(
                  color: _isHighContrast ? const Color(0xFF222222) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(24),
                  border: _isHighContrast ? Border.all(color: const Color(0xFFFFD700)) : null,
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentBahasa = 'id');
                          _speakContent();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentBahasa == 'id' ? primaryCol : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_currentBahasa == 'id') ...[
                                Icon(Icons.pause,
                                    size: 14,
                                    color: _isHighContrast ? Colors.black : Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                "Bahasa Indonesia",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _currentBahasa == 'id'
                                      ? (_isHighContrast ? Colors.black : Colors.white)
                                      : (_isHighContrast ? Colors.white70 : Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentBahasa = 'min');
                          _speakContent();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentBahasa == 'min' ? primaryCol : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Baso Minang",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _currentBahasa == 'min'
                                  ? (_isHighContrast ? Colors.black : Colors.white)
                                  : (_isHighContrast ? Colors.white70 : Colors.grey[700]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- Bar Aksesibilitas: Ukuran Teks & Tombol Kontras Tinggi (WCAG) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _toggleHighContrast,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isHighContrast ? const Color(0xFFFFD700) : cardCol,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isHighContrast ? const Color(0xFFFFD700) : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.contrast,
                            size: 16,
                            color: _isHighContrast ? Colors.black : const Color(0xFF1E56A0),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isHighContrast ? "Kontras: ON" : "Mode Kontras",
                            style: TextStyle(
                              fontSize: 12 * _fontScale,
                              fontWeight: FontWeight.bold,
                              color: _isHighContrast ? Colors.black : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pengatur Zoom Teks (Persis Desain: 🔍 Zoom  −  100%  +)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isHighContrast ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border.all(
                        color: _isHighContrast ? const Color(0xFFFFD700) : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search,
                          size: 15,
                          color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Zoom",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isHighContrast ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tombol −
                        InkWell(
                          onTap: _zoomPercent > 0 ? _zoomOut : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _zoomPercent > 0
                                  ? (_isHighContrast ? const Color(0xFF333333) : const Color(0xFFF1F5F9))
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.remove,
                              size: 14,
                              color: _zoomPercent > 0
                                  ? (_isHighContrast ? Colors.white : Colors.black87)
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            "$_zoomPercent%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E56A0),
                            ),
                          ),
                        ),
                        // Tombol +
                        InkWell(
                          onTap: _zoomPercent < 100 ? _zoomIn : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _zoomPercent < 100
                                  ? (_isHighContrast ? const Color(0xFF333333) : const Color(0xFFF1F5F9))
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: _zoomPercent < 100
                                  ? (_isHighContrast ? Colors.white : Colors.black87)
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // --- Audio Player Card (Atas) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardCol,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    if (!_isHighContrast)
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: primaryCol,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: _isHighContrast ? Colors.black : Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.graphic_eq, color: primaryCol, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isPlaying
                                        ? (isMinang
                                            ? "Sedang mambacoan isi surek..."
                                            : "Sedang membacakan isi surat...")
                                        : (isMinang
                                            ? "Putar suaro untuak mandanga..."
                                            : "Putar suara untuk mendengarkan..."),
                                    style: TextStyle(
                                      fontSize: 13 * _fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: textCol,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isPlaying
                                    ? "${_formatDuration(_elapsedSeconds)} / ${_formatDuration(_totalSeconds)}"
                                    : "0:00 / ${_formatDuration(_totalSeconds)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isHighContrast ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _cycleSpeed,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isHighContrast ? const Color(0xFF262626) : const Color(0xFFEBF3FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF93C5FD),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.speed, size: 14, color: primaryCol),
                                const SizedBox(width: 4),
                                Text(
                                  "${_currentSpeed}x",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryCol,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Yellow Subtitle Highlight Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isHighContrast ? const Color(0xFF262626) : const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(10),
                        border: _isHighContrast ? Border.all(color: const Color(0xFFFFD700)) : null,
                      ),
                      child: Text(
                        '"${widget.result.tenggatSub}"',
                        style: TextStyle(
                          fontSize: 13 * _fontScale,
                          fontWeight: FontWeight.w600,
                          color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF713F12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // --- Card: Dokumen Resmi Terverifikasi ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardCol,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isHighContrast ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF34D399)),
                          const SizedBox(width: 6),
                          Text(
                            widget.result.jenisDokumen,
                            style: TextStyle(
                              fontSize: 11 * _fontScale,
                              fontWeight: FontWeight.bold,
                              color: _isHighContrast ? Colors.white : const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.result.judul,
                      style: TextStyle(
                        fontSize: 18 * _fontScale,
                        fontWeight: FontWeight.w900,
                        color: primaryCol,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "Diterima: 14 Mei 2024",
                          style: TextStyle(
                            fontSize: 12 * _fontScale,
                            color: _isHighContrast ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          "No. Peserta: ${widget.result.nomorPeserta}",
                          style: TextStyle(
                            fontSize: 12 * _fontScale,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // --- Card: Inti Surat Ini ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isHighContrast ? const Color(0xFF161616) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: primaryCol, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isMinang ? "Inti Surek Ko:" : "Inti Surat Ini:",
                          style: TextStyle(
                            fontSize: 16 * _fontScale,
                            fontWeight: FontWeight.bold,
                            color: primaryCol,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.result.penjelasan,
                      style: TextStyle(
                        fontSize: 14.5 * _fontScale,
                        color: textCol,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // --- Section: ! TIGA INFORMASI UTAMA ---
              Text(
                isMinang ? "! TIGO INFORMASI UTAMA" : "! TIGA INFORMASI UTAMA",
                style: TextStyle(
                  fontSize: 14 * _fontScale,
                  fontWeight: FontWeight.w900,
                  color: primaryCol,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Kartu 1: Tenggat Waktu + TOMBOL PENGINGAT (Anti-Denda)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardCol,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isHighContrast ? const Color(0xFF332A00) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.alarm,
                                  size: 14,
                                  color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFFB45309)),
                              const SizedBox(width: 6),
                              Text(
                                "TENGGAT WAKTU",
                                style: TextStyle(
                                  fontSize: 11 * _fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "Tersisa 6 Hari Lagi",
                          style: TextStyle(
                            fontSize: 12 * _fontScale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.result.tenggat,
                      style: TextStyle(
                        fontSize: 24 * _fontScale,
                        fontWeight: FontWeight.w900,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.result.tenggatSub,
                      style: TextStyle(
                        fontSize: 13 * _fontScale,
                        color: _isHighContrast ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Kartu 2: Jumlah yang Harus Dibayar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardCol,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isHighContrast ? const Color(0xFF1E293B) : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments,
                              size: 14,
                              color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E40AF)),
                          const SizedBox(width: 6),
                          Text(
                            "JUMLAH YANG HARUS DIBAYAR",
                            style: TextStyle(
                              fontSize: 11 * _fontScale,
                              fontWeight: FontWeight.bold,
                              color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.result.nominal,
                      style: TextStyle(
                        fontSize: 26 * _fontScale,
                        fontWeight: FontWeight.w900,
                        color: primaryCol,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.result.nominalSub,
                      style: TextStyle(
                        fontSize: 13 * _fontScale,
                        color: _isHighContrast ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isHighContrast ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Rincian: ${widget.result.rincian}",
                        style: TextStyle(
                          fontSize: 12 * _fontScale,
                          color: _isHighContrast ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Kartu 3: Cara & Tindakan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardCol,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isHighContrast ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_box, size: 14, color: Color(0xFF34D399)),
                          const SizedBox(width: 6),
                          Text(
                            "CARA & TINDAKAN",
                            style: TextStyle(
                              fontSize: 11 * _fontScale,
                              fontWeight: FontWeight.bold,
                              color: _isHighContrast ? Colors.white : const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < widget.result.langkahTindakan.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: primaryCol,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "${i + 1}",
                              style: TextStyle(
                                color: _isHighContrast ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.result.langkahTindakan[i],
                              style: TextStyle(
                                fontSize: 13.5 * _fontScale,
                                color: textCol,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (i < widget.result.langkahTindakan.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Catatan Penting Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isHighContrast ? const Color(0xFF262626) : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFFFDE047),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFFB45309),
                            size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isMinang ? "Catatan Pantiang:" : "Catatan Penting:",
                          style: TextStyle(
                            fontSize: 14 * _fontScale,
                            fontWeight: FontWeight.bold,
                            color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isMinang
                          ? "BACO mambantu marangkum surek resmi. Untuak kapastian labiah lanjuik, silakan konfirmasi ka kantor BPJS Kesehatan tadakek."
                          : "BACO membantu merangkum surat resmi. Untuk kepastian lebih lanjut, silakan konfirmasi ke kantor BPJS Kesehatan terdekat.",
                      style: TextStyle(
                        fontSize: 12.5 * _fontScale,
                        color: _isHighContrast ? Colors.white70 : Colors.yellow[900],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Bawah: Masih Bingung? Tanya BACO Sekarang ->
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _ttsService.stop();

                    String docTitle = "Dokumen Terpindai";
                    final p = widget.result.penjelasan.toLowerCase();
                    if (p.contains("bpjs")) {
                      docTitle = "Surat BPJS";
                    } else if (p.contains("listrik") || p.contains("pln")) {
                      docTitle = "Tagihan Listrik";
                    } else if (p.contains("pdam") || p.contains("air")) {
                      docTitle = "Tagihan PDAM";
                    } else if (p.contains("desa") || p.contains("kelurahan") || p.contains("rt")) {
                      docTitle = "Surat Desa/Kelurahan";
                    }
                    if (widget.result.nominal.isNotEmpty && widget.result.nominal != "Tidak ada") {
                      docTitle = "$docTitle (${widget.result.nominal})";
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AskScreen(
                          bahasa: _currentBahasa,
                          contextDocument: widget.result.toSpeechText(bahasa: _currentBahasa),
                          documentTitle: docTitle,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.chat_bubble_outline,
                      size: 22, color: _isHighContrast ? Colors.black : Colors.white),
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isMinang ? "Masih Raguk? Batanyo ka BACO" : "Masih Bingung? Tanya BACO Sekarang",
                        style: TextStyle(
                          fontSize: 16 * _fontScale,
                          fontWeight: FontWeight.bold,
                          color: _isHighContrast ? Colors.black : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward,
                          size: 18, color: _isHighContrast ? Colors.black : Colors.white),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCol,
                    foregroundColor: _isHighContrast ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeButton(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: active
            ? (_isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E56A0))
            : Colors.transparent,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active
                ? (_isHighContrast ? Colors.black : Colors.white)
                : (_isHighContrast ? Colors.white : Colors.grey[800]),
          ),
        ),
      ),
    );
  }
}
