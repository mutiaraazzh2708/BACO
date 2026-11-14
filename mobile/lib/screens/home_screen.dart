import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import 'camera_preview_screen.dart';
import 'ask_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();

  String _selectedBahasa = 'id'; // 'id' atau 'min'
  int _zoomPercent = 0; // Rentang 0% s/d 100%
  double _fontScale = 1.0;
  int _currentNavIndex = 0; // Selalu 0 (Beranda) saat berada di layar utama
  bool _isHighContrast = false; // Mode Kontras Tinggi Standar WCAG
  bool _isPanduanPlaying = false;
  Timer? _panduanTimer;
  int _panduanElapsed = 0;
  int _panduanTotal = 18;
  double _currentSpeed = 1.0;

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
    _ttsService.init();
    _currentSpeed = _ttsService.currentMultiplier;
  }

  @override
  void dispose() {
    _panduanTimer?.cancel();
    _ttsService.onCompletion = null;
    _ttsService.stop();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
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

    if (_isPanduanPlaying) {
      _startPanduanVoice();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Kecepatan Suara: $label"),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startPanduanVoice() {
    _panduanTimer?.cancel();
    final text = _selectedBahasa == 'min'
        ? "Salamaik datang di BACO! Asisten Suara untuak Mambaco Dokumen Layanan Publik. "
          "Takan tombol Foto Dokumen di bawah untuak mamoto surek sanak, nantik ambo bacoan intinyo."
        : "Selamat datang di BACO! Asisten suara untuk memahami dokumen resmi. "
          "Arahkan kamera ke surat atau dokumen Anda, tekan tombol Foto Dokumen di bawah, "
          "dan BACO akan membacakan rangkumannya dengan suara jernih.";

    final estimated = ((text.length / (11.5 * _currentSpeed)).ceil()).clamp(5, 60);

    setState(() {
      _isPanduanPlaying = true;
      _panduanElapsed = 0;
      _panduanTotal = estimated;
    });

    _ttsService.onCompletion = () {
      if (mounted) {
        _panduanTimer?.cancel();
        setState(() {
          _isPanduanPlaying = false;
          _panduanElapsed = 0;
        });
      }
    };

    _ttsService.speak(text);

    _panduanTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_panduanElapsed < _panduanTotal) {
        setState(() {
          _panduanElapsed++;
        });
      } else if (_panduanElapsed < _panduanTotal + 8) {
        setState(() {
          _panduanElapsed++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isPanduanPlaying = false;
          _panduanElapsed = 0;
        });
      }
    });
  }

  void _stopPanduanVoice() {
    _panduanTimer?.cancel();
    _ttsService.stop();
    if (mounted) {
      setState(() {
        _isPanduanPlaying = false;
        _panduanElapsed = 0;
      });
    }
  }

  void _togglePanduanVoice() {
    HapticFeedback.selectionClick();
    if (_isPanduanPlaying) {
      _stopPanduanVoice();
    } else {
      _startPanduanVoice();
    }
  }

  void _toggleHighContrast() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isHighContrast = !_isHighContrast;
    });

    if (_isHighContrast) {
      final msg = _selectedBahasa == 'min'
          ? "Mode kontras tinggi aktif untuak tunanetra jo lansia."
          : "Mode kontras tinggi aktif untuk lansia dan tunanetra.";
      _ttsService.speak(msg);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.mediumImpact();
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (picked != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraPreviewScreen(
              imageFile: File(picked.path),
              bahasa: _selectedBahasa,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuka kamera/galeri: $e"),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _currentNavIndex = 0;
        });
      }
    }
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: _apiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pengaturan Alamat Server Backend"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Alamat server laptop untuk koneksi HP (contoh: http://10.246.74.45:8000)",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Base URL Backend",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _apiService.baseUrl = controller.text.trim();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Alamat backend disimpan: ${_apiService.baseUrl}"),
                ),
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMinang = _selectedBahasa == 'min';

    // Warna Dinamis Berdasarkan Mode Kontras Tinggi
    final bgCol = _isHighContrast ? Colors.black : const Color(0xFFF8FAFC);
    final cardCol = _isHighContrast ? const Color(0xFF141414) : Colors.white;
    final primaryCol = _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E56A0);
    final textCol = _isHighContrast ? Colors.white : Colors.black87;
    final borderCol = _isHighContrast ? const Color(0xFFFFD700) : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgCol,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Atas: Logo BACO & Toggle Bahasa ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onLongPress: _showSettingsDialog,
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: primaryCol,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.hearing,
                          color: _isHighContrast ? Colors.black : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  // Toggle Bahasa Pill
                  Container(
                    decoration: BoxDecoration(
                      color: _isHighContrast ? const Color(0xFF222222) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(24),
                      border: _isHighContrast ? Border.all(color: const Color(0xFFFFD700)) : null,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedBahasa = 'id');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedBahasa == 'id' ? primaryCol : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                if (_selectedBahasa == 'id') ...[
                                  Icon(Icons.pause,
                                      size: 14,
                                      color: _isHighContrast ? Colors.black : Colors.white),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  "Indonesia",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedBahasa == 'id'
                                        ? (_isHighContrast ? Colors.black : Colors.white)
                                        : (_isHighContrast ? Colors.white70 : Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedBahasa = 'min');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedBahasa == 'min' ? primaryCol : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Minang",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedBahasa == 'min'
                                    ? (_isHighContrast ? Colors.black : Colors.white)
                                    : (_isHighContrast ? Colors.white70 : Colors.grey[700]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Mode Aksesibilitas Suara Aktif Banner ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isHighContrast ? const Color(0xFF1E1E1E) : const Color(0xFFEEF5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFFD0E1FD),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.volume_up,
                        size: 20, color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E56A0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMinang
                            ? "Mode Aksesibilitas Suara Aktif"
                            : "Mode Aksesibilitas Suara Aktif",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E56A0),
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
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
                  // Toggle Mode Kontras Tinggi
                  InkWell(
                    onTap: _toggleHighContrast,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isHighContrast ? const Color(0xFFFFD700) : Colors.white,
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
              const SizedBox(height: 16),

              // --- Badge Layanan Terbuka & Gratis ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isHighContrast ? const Color(0xFF222222) : const Color(0xFFE0EDFD),
                  borderRadius: BorderRadius.circular(20),
                  border: _isHighContrast ? Border.all(color: const Color(0xFFFFD700)) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified,
                        size: 16, color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E56A0)),
                    const SizedBox(width: 6),
                    Text(
                      "Layanan Suara Terbuka & Gratis",
                      style: TextStyle(
                        fontSize: 12 * _fontScale,
                        fontWeight: FontWeight.bold,
                        color: _isHighContrast ? const Color(0xFFFFD700) : const Color(0xFF1E56A0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- Headline ---
              Text(
                "Selamat Datang di BACO",
                style: TextStyle(
                  fontSize: 26 * _fontScale,
                  fontWeight: FontWeight.w900,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isMinang
                    ? "Bia Dokumen Mudah Dimangarati."
                    : "Biar Dokumen Mudah Dimengerti.",
                style: TextStyle(
                  fontSize: 19 * _fontScale,
                  fontWeight: FontWeight.bold,
                  color: primaryCol,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isMinang
                    ? "Arahkan kamera ka surek atau dokumen resmi sanak, BACO ka mambacoan dan manjalaskannyo langsuang lewaik suaro janiah."
                    : "Arahkan kamera ke surat atau dokumen resmi Anda, BACO akan membacakan dan menjelaskannya langsung lewat suara jernih.",
                style: TextStyle(
                  fontSize: 15 * _fontScale,
                  color: _isHighContrast ? Colors.white70 : Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),

              // --- Card: Panduan Singkat ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardCol,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    if (!_isHighContrast)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isHighContrast ? const Color(0xFF262626) : const Color(0xFFEBF3FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.record_voice_over, color: primaryCol, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMinang ? "Panduan Singkek" : "Panduan Singkat",
                                style: TextStyle(
                                  fontSize: 16 * _fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isPanduanPlaying
                                    ? "${_formatDuration(_panduanElapsed)} / ${_formatDuration(_panduanTotal)}"
                                    : (isMinang ? "Danga patunjuak 20 datiak" : "Dengarkan petunjuk 20 detik"),
                                style: TextStyle(
                                  fontSize: 13 * _fontScale,
                                  color: _isPanduanPlaying
                                      ? primaryCol
                                      : (_isHighContrast ? Colors.white70 : Colors.grey[600]),
                                  fontWeight: _isPanduanPlaying ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge Kecepatan Suara Panduan
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
                        const SizedBox(width: 8),
                        Icon(Icons.graphic_eq, color: primaryCol, size: 26),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _togglePanduanVoice,
                        icon: Icon(_isPanduanPlaying ? Icons.pause : Icons.play_arrow, size: 22),
                        label: Text(
                          _isPanduanPlaying
                              ? (isMinang ? "Hantian Panduan Suaro ⏸" : "Hentikan Panduan Suara ⏸")
                              : (isMinang ? "Danga Panduan Suara 🔊" : "Dengarkan Panduan Suara 🔊"),
                          style: TextStyle(
                            fontSize: 14 * _fontScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isHighContrast
                              ? const Color(0xFFFFD700)
                              : (_isPanduanPlaying ? const Color(0xFF1E56A0) : const Color(0xFFEBF3FF)),
                          foregroundColor: _isHighContrast
                              ? Colors.black
                              : (_isPanduanPlaying ? Colors.white : const Color(0xFF1E56A0)),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // --- Tombol Utama: Foto Dokumen (Besar & Haptic Feedback) ---
              InkWell(
                onTap: () => _pickImage(ImageSource.camera),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    color: primaryCol,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: primaryCol.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isHighContrast ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: _isHighContrast ? Colors.black : Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "📸 Foto Dokumen",
                              style: TextStyle(
                                fontSize: 19 * _fontScale,
                                fontWeight: FontWeight.bold,
                                color: _isHighContrast ? Colors.black : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMinang
                                  ? "Sentuh untuak mamindai surek fisik"
                                  : "Sentuh untuk memindai surat fisik",
                              style: TextStyle(
                                fontSize: 13 * _fontScale,
                                color: _isHighContrast ? Colors.black87 : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: _isHighContrast ? Colors.black : Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // --- Tombol Sekunder: Pilih dari Galeri HP ---
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: Icon(Icons.photo_library_outlined, color: primaryCol, size: 22),
                label: Text(
                  isMinang ? "🖼️ Piliah dari Galeri HP" : "🖼️ Pilih dari Galeri HP",
                  style: TextStyle(
                    fontSize: 16 * _fontScale,
                    fontWeight: FontWeight.bold,
                    color: primaryCol,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: cardCol,
                  side: BorderSide(color: primaryCol, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Bagian: Jenis Surat Yang Bisa Dibantu ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMinang ? "Jinih Surek Nan Bisa Dibantu:" : "Jenis Surat Yang Bisa Dibantu:",
                    style: TextStyle(
                      fontSize: 16 * _fontScale,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                  Text(
                    "Otomatis & Akurat",
                    style: TextStyle(
                      fontSize: 12 * _fontScale,
                      fontWeight: FontWeight.bold,
                      color: primaryCol,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildSuratCard(
                icon: Icons.shield,
                iconColor: primaryCol,
                bgColor: _isHighContrast ? const Color(0xFF222222) : const Color(0xFFEEF5FF),
                title: "📄 Surat BPJS & Kesehatan",
                desc: "Rujukan puskesmas, obat, status aktif iuran",
                cardCol: cardCol,
                borderCol: borderCol,
                textCol: textCol,
              ),
              const SizedBox(height: 10),
              _buildSuratCard(
                icon: Icons.bolt,
                iconColor: Colors.amber[800]!,
                bgColor: _isHighContrast ? const Color(0xFF222222) : const Color(0xFFFFF7ED),
                title: "⚡ Tagihan Listrik & Air (PDAM)",
                desc: "Nominal jatuh tempo dibaca jelas tanpa keliru",
                cardCol: cardCol,
                borderCol: borderCol,
                textCol: textCol,
              ),
              const SizedBox(height: 10),
              _buildSuratCard(
                icon: Icons.account_balance,
                iconColor: Colors.green[700]!,
                bgColor: _isHighContrast ? const Color(0xFF222222) : const Color(0xFFF0FDF4),
                title: "🏛️ Surat Kelurahan & RT/RW",
                desc: "Undangan bansos, pengantar KTP, himbauan warga",
                cardCol: cardCol,
                borderCol: borderCol,
                textCol: textCol,
              ),
              const SizedBox(height: 18),

              // --- Footer Banner: Dirancang Khusus Aksesibilitas ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isHighContrast ? const Color(0xFF1E1E1E) : const Color(0xFFEEF5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  children: [
                    Icon(Icons.accessibility_new, color: primaryCol, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isMinang
                            ? "Dirancang khusus ramah lansia & tunanetra jo navigasi sederhana dan audio otomatis."
                            : "Dirancang khusus ramah lansia & tunanetra dengan navigasi sederhana dan audio otomatis.",
                        style: TextStyle(
                          fontSize: 13 * _fontScale,
                          color: _isHighContrast ? Colors.white : const Color(0xFF1E56A0),
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        backgroundColor: cardCol,
        selectedItemColor: primaryCol,
        unselectedItemColor: _isHighContrast ? Colors.white54 : Colors.grey[500],
        onTap: (index) async {
          HapticFeedback.selectionClick();
          if (index == 0) {
            setState(() => _currentNavIndex = 0);
          } else if (index == 1) {
            _pickImage(ImageSource.camera);
          } else if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AskScreen(
                  bahasa: _selectedBahasa,
                  contextDocument:
                      "Layanan publik umum Indonesia (BPJS Kesehatan, Tagihan Listrik PLN, PDAM, Administrasi Desa/Kelurahan)",
                  documentTitle: null,
                ),
              ),
            );
            if (mounted) {
              setState(() => _currentNavIndex = 0);
            }
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner),
            label: "Pindai",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over),
            label: "Tanya BACO",
          ),
        ],
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

  Widget _buildSuratCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String desc,
    required Color cardCol,
    required Color borderCol,
    required Color textCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15 * _fontScale,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12.5 * _fontScale,
                    color: _isHighContrast ? Colors.white70 : Colors.grey[600],
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
