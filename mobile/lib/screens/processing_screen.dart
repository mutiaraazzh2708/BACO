import 'dart:io';
import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final File imageFile;
  final String bahasa;

  const ProcessingScreen({
    super.key,
    required this.imageFile,
    required this.bahasa,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();

  int _currentStep = 1; // 0 = step 1 done, 1 = step 2 in progress, 2 = step 3 done
  AnalysisResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startProcess();
  }

  Future<void> _startProcess() async {
    final isMinang = widget.bahasa == 'min';

    // Suara BACO berbicara saat loading
    final voiceText = isMinang
        ? "Mohon tunggu sabanta yo, ambo sadang mambaco dokumen sanak..."
        : "Mohon tunggu sebentar ya, saya sedang membaca dokumen Anda...";
    _ttsService.speak(voiceText);

    // Simulasi tahapan visual untuk estetika pengguna
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _currentStep = 2);
    });

    try {
      final res = await _apiService.analyzeDocument(
        imageFile: widget.imageFile,
        bahasa: widget.bahasa,
      );

      if (mounted) {
        setState(() {
          _result = res;
          _currentStep = 3;
        });

        // Beralih otomatis ke layar hasil
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _navigateToResult();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  void _navigateToResult() {
    if (_result != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            result: _result!,
            imageFile: widget.imageFile,
            bahasa: widget.bahasa,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMinang = widget.bahasa == 'min';

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(isMinang ? "Kasalahan" : "Gagal Membaca"),
          backgroundColor: const Color(0xFF1E56A0),
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 70, color: Colors.red[700]),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _errorMessage = null);
                  _startProcess();
                },
                icon: const Icon(Icons.refresh),
                label: Text(isMinang ? "Cubo Liak" : "Coba Lagi"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E56A0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E56A0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hearing, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "BACO",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E56A0),
                            ),
                          ),
                          Text(
                            "Asisten Suara Warga",
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0EDFD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Color(0xFF1E56A0), size: 10),
                        SizedBox(width: 6),
                        Text(
                          "Pemeriksaan Dokumen",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E56A0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Banner: BACO Berbicara ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD0E1FD)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E56A0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.volume_up, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🔊 BACO Berbicara:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E56A0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMinang
                                ? "“Mohon tunggu sabanta yo, ambo sadang membaco dokumen sanak...”"
                                : "“Mohon tunggu sebentar ya, ambo sedang membaco dokumen sanak...”",
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // --- Miniatur Dokumen & Sedang Menyelaraskan Piksel ---
              Container(
                width: 220,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(widget.imageFile, fit: BoxFit.cover),
                      Container(color: Colors.black.withOpacity(0.15)),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.document_scanner, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Pill Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF1E56A0), size: 9),
                    SizedBox(width: 6),
                    Text(
                      "Sedang Menyelaraskan Piksel",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E56A0)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Judul Tengah
              Text(
                isMinang ? "BACO sadang mambaco dokumen..." : "BACO sedang membaca dokumen...",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                "Memindai teks dan menerjemahkan ke dalam bahasa yang mudah dimengerti.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              // --- Card: TAHAPAN PEMINDAIAN ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TAHAPAN PEMINDAIAN",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Langkah 1
                    _buildStepRow(
                      icon: Icons.check_circle,
                      iconColor: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                      borderColor: const Color(0xFFA7F3D0),
                      title: "Membaca & mendeteksi teks surat",
                      status: "Selesai • 100% akurat",
                      trailingIcon: Icons.check,
                    ),
                    const SizedBox(height: 10),

                    // Langkah 2
                    _buildStepRow(
                      icon: Icons.hourglass_top,
                      iconColor: const Color(0xFF1E56A0),
                      bgColor: const Color(0xFFEFF6FF),
                      borderColor: const Color(0xFFBFDBFE),
                      title: "Mengekstrak tanggal tenggat & nominal",
                      status: _currentStep >= 2 ? "Sedang dianalisis..." : "Menunggu giliran",
                      trailingIcon: Icons.hourglass_empty,
                    ),
                    const SizedBox(height: 10),

                    // Langkah 3
                    _buildStepRow(
                      icon: Icons.circle_outlined,
                      iconColor: Colors.grey[400]!,
                      bgColor: const Color(0xFFF8FAFC),
                      borderColor: Colors.grey[300]!,
                      title: "Menyusun ringkasan & rekaman suara",
                      status: _currentStep >= 3 ? "Siap ditampilkan" : "Menunggu giliran",
                      trailingIcon: Icons.more_horiz,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kotak Tips Kuning
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE047)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Color(0xFFCA8A04), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tidak perlu menekan tombol apa pun, layar akan beralih otomatis dalam beberapa detik.",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.yellow[900],
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Buka Hasil Analisis Sekarang
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _result != null ? _navigateToResult : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E56A0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Buka Hasil Analisis Sekarang",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tekan jika layar tidak berpindah otomatis dalam 10 detik.",
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String status,
    required IconData trailingIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(fontSize: 12, color: iconColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(trailingIcon, color: iconColor, size: 20),
        ],
      ),
    );
  }
}

