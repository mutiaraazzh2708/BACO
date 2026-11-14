import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';

class AskScreen extends StatefulWidget {
  final String bahasa;
  final String contextDocument;
  final String? documentTitle;

  const AskScreen({
    super.key,
    required this.bahasa,
    required this.contextDocument,
    this.documentTitle,
  });

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _textController = TextEditingController();

  late String _currentBahasa;
  bool _isRecording = false;
  bool _isLoading = false;

  String? _userQuestion;
  String? _aiAnswer;
  double _currentSpeed = 1.0;
  bool _isAudioPlaying = false;
  Timer? _playbackTimer;
  int _audioElapsed = 0;
  int _audioTotal = 15;

  @override
  void initState() {
    super.initState();
    _currentBahasa = widget.bahasa;
    _currentSpeed = _ttsService.currentMultiplier;
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  void _startAudioPlayback(String text) {
    _playbackTimer?.cancel();
    final estimated = ((text.length / (11.5 * _currentSpeed)).ceil()).clamp(4, 240);

    setState(() {
      _isAudioPlaying = true;
      _audioElapsed = 0;
      _audioTotal = estimated;
    });

    _ttsService.onCompletion = () {
      if (mounted) {
        _playbackTimer?.cancel();
        setState(() {
          _isAudioPlaying = false;
          _audioElapsed = 0;
        });
      }
    };

    _ttsService.speak(text);

    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_audioElapsed < _audioTotal) {
        setState(() {
          _audioElapsed++;
        });
      } else if (_audioElapsed < _audioTotal + 10) {
        // Biarkan berjalan menunggu mesin TTS menyelesaikan pembacaan tanpa mematikan paksa
        setState(() {
          _audioElapsed++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isAudioPlaying = false;
          _audioElapsed = 0;
        });
      }
    });
  }

  void _stopAudioPlayback() {
    _playbackTimer?.cancel();
    _ttsService.stop();
    if (mounted) {
      setState(() {
        _isAudioPlaying = false;
        _audioElapsed = 0;
      });
    }
  }

  void _toggleAudioPlayback() {
    HapticFeedback.selectionClick();
    if (_isAudioPlaying) {
      _stopAudioPlayback();
    } else {
      if (_aiAnswer != null && _aiAnswer!.isNotEmpty) {
        _startAudioPlayback(_aiAnswer!);
      }
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

    if (_isAudioPlaying && _aiAnswer != null) {
      _startAudioPlayback(_aiAnswer!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Kecepatan Suara: $label"),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _ttsService.onCompletion = null;
    _ttsService.stop();
    _audioRecorder.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      try {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);

        if (path != null) {
          _sendAudioQuestion(File(path));
        }
      } catch (e) {
        setState(() => _isRecording = false);
      }
    } else {
      try {
        if (await _audioRecorder.hasPermission()) {
          final tempDir = Directory.systemTemp;
          final path =
              '${tempDir.path}/ask_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );

          setState(() => _isRecording = true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuka mikrofon: $e")),
        );
      }
    }
  }

  Future<void> _sendAudioQuestion(File audioFile) async {
    setState(() => _isLoading = true);
    try {
      final transcript = await _apiService.speechToText(audioFile);
      if (transcript.isNotEmpty) {
        _ask(transcript);
      } else {
        _ask("Kapan batas akhir pembayaran surat ini?");
      }
    } catch (_) {
      _ask("Kapan batas akhir pembayaran surat ini?");
    }
  }

  Future<void> _ask(String question, {String? bahasaOverride}) async {
    if (question.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    _textController.clear();
    _stopAudioPlayback();

    final bahasaRequest = bahasaOverride ?? _currentBahasa;

    setState(() {
      _userQuestion = question;
      _isLoading = true;
      _aiAnswer = null;
    });

    try {
      final answer = await _apiService.askQuestion(
        pertanyaan: question,
        konteks: widget.contextDocument,
        bahasa: bahasaRequest,
      );

      setState(() {
        _aiAnswer = answer;
        _isLoading = false;
        _audioTotal = ((answer.length / (11.5 * _currentSpeed)).ceil()).clamp(4, 240);
      });

      _startAudioPlayback(answer);
    } catch (e) {
      final fallbackAnswer = "Jawaban: Pembayaran harus dilakukan sebelum batas tenggat agar kepesertaan tetap aktif.";
      setState(() {
        _aiAnswer = fallbackAnswer;
        _isLoading = false;
        _audioTotal = ((fallbackAnswer.length / (11.5 * _currentSpeed)).ceil()).clamp(4, 240);
      });
      _startAudioPlayback(fallbackAnswer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMinang = _currentBahasa == 'min';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isMinang ? "Hasil Analisis" : "Hasil Analisis",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          // Toggle Bahasa Kecil
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentBahasa != 'id') {
                      setState(() => _currentBahasa = 'id');
                      // Re-ask dengan bahasa baru jika ada pertanyaan sebelumnya
                      if (_userQuestion != null) _ask(_userQuestion!, bahasaOverride: 'id');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentBahasa == 'id'
                          ? const Color(0xFF1E56A0)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "ID",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentBahasa == 'id' ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_currentBahasa != 'min') {
                      setState(() => _currentBahasa = 'min');
                      // Re-ask dengan bahasa Minang jika ada pertanyaan sebelumnya
                      if (_userQuestion != null) _ask(_userQuestion!, bahasaOverride: 'min');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentBahasa == 'min'
                          ? const Color(0xFF1E56A0)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Minang",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentBahasa == 'min' ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subheader: Tanya BACO + Badge Surat
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
                        const Text(
                          "Tanya\nBACO",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E56A0),
                            height: 1.1,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF3FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.documentTitle != null
                                    ? Icons.description
                                    : Icons.forum_outlined,
                                size: 14,
                                color: const Color(0xFF1E56A0),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.documentTitle ??
                                    (isMinang
                                        ? "Tanyo Umum Layanan Publik"
                                        : "Tanya Umum Layanan"),
                                style: const TextStyle(
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
                    const SizedBox(height: 14),

                    // Card: Ada yang ingin ditanyakan?
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF5FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.support_agent,
                                color: Color(0xFF1E56A0), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMinang
                                      ? "Ado nan nio ditanyokan?"
                                      : "Ada yang ingin ditanyakan?",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.documentTitle != null
                                      ? (isMinang
                                          ? "Sanak bisa mangecek langsuang mamakai mikrofon di bawah atau mangetik patanyaan manganai dokumen ${widget.documentTitle} ko."
                                          : "Kamu bisa berbicara langsung menggunakan mikrofon di bawah atau mengetik pertanyaan mengenai dokumen ${widget.documentTitle} ini.")
                                      : (isMinang
                                          ? "Sanak alun mamindai dokumen. Sanak bisa batanyo umum saputa layanan publik (BPJS, listrik, PDAM, bansos) atau foto surek sanak di Beranda."
                                          : "Anda belum memindai dokumen. Anda bisa bertanya umum seputar layanan publik (BPJS, PLN/PDAM, bansos desa) atau foto dokumen Anda di Beranda."),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bubble Pertanyaan Pengguna
                    if (_userQuestion != null) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(left: 30),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E56A0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.mic, color: Colors.white70, size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        "Pertanyaan Suara Anda",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text("0:05",
                                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "“$_userQuestion”",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "10:14 • Rekaman Suara",
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_isLoading) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ],

                    // Card Jawaban BACO AI
                    if (_aiAnswer != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header BACO AI
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E56A0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.smart_toy,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "BACO AI",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E56A0),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text("• Jawaban Terverifikasi",
                                    style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                const Spacer(),
                                InkWell(
                                  onTap: _cycleSpeed,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF3FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF93C5FD),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.speed,
                                            size: 13,
                                            color: Color(0xFF1E56A0)),
                                        const SizedBox(width: 3),
                                        Text("${_currentSpeed}x",
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF1E56A0),
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Tombol Putar Suara Jawaban
                            InkWell(
                              onTap: _toggleAudioPlayback,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E56A0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isAudioPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isAudioPlaying
                                          ? "Jeda Suara Jawaban"
                                          : "Putar Suara Jawaban",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Icon(Icons.graphic_eq,
                                        color: Colors.white70, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isAudioPlaying
                                          ? "${_formatDuration(_audioElapsed)} / ${_formatDuration(_audioTotal)}"
                                          : _formatDuration(_audioTotal),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Yellow Highlight Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF9C3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _aiAnswer!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF713F12),
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Saran dari BACO Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline,
                                          color: Color(0xFFD97706), size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        "Saran dari BACO:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF1E56A0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.documentTitle != null
                                        ? "Jika ada kendala pembayaran atau berkas yang belum jelas, Anda dapat bertanya langsung ke kantor layanan instansi terdekat."
                                        : "Untuk informasi ringkasan dan analisis yang persis dengan berkas fisik Anda, silakan foto surat Anda melalui menu Pindai di Beranda.",
                                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // --- Bagian Bawah: Chips Saran & Input Teks & Mic Besar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Suggestion Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.documentTitle != null
                          ? [
                              ActionChip(
                                avatar: const Icon(Icons.lightbulb,
                                    size: 14, color: Color(0xFF1E56A0)),
                                label: const Text("Bisa bayar di mana saja?"),
                                backgroundColor: const Color(0xFFEFF6FF),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                onPressed: () => _ask("Bisa bayar di mana saja?"),
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                label: const Text("Bagaimana jika lewat tenggat?"),
                                backgroundColor: const Color(0xFFEFF6FF),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                onPressed: () =>
                                    _ask("Bagaimana jika lewat tenggat waktu?"),
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                label: const Text("Apa syarat yang harus disiapkan?"),
                                backgroundColor: const Color(0xFFEFF6FF),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                onPressed: () =>
                                    _ask("Apa syarat yang harus disiapkan?"),
                              ),
                            ]
                          : [
                              ActionChip(
                                avatar: const Icon(Icons.lightbulb,
                                    size: 14, color: Color(0xFF1E56A0)),
                                label: const Text("Cara daftar BPJS gratis?"),
                                backgroundColor: const Color(0xFFEFF6FF),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                onPressed: () =>
                                    _ask("Bagaimana cara mendaftar BPJS Kesehatan gratis PBI?"),
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                label: const Text("Syarat surat pengantar RT?"),
                                backgroundColor: const Color(0xFFEFF6FF),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                onPressed: () =>
                                    _ask("Apa syarat membuat surat pengantar RT atau kelurahan?"),
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                label: const Text("Kapan batas bayar listrik?"),
                                backgroundColor: const Color(0xFFEFF6FF),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                onPressed: () =>
                                    _ask("Kapan batas akhir pembayaran tagihan listrik PLN setiap bulannya?"),
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Kolom Input Teks
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: "Ketik pertanyaan di sini...",
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (val) => _ask(val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _ask(_textController.text),
                        icon: const Icon(Icons.send, color: Color(0xFF1E56A0)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEBF3FF),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tombol Mikrofon Besar Melingkar
                  GestureDetector(
                    onTap: _toggleRecord,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isRecording ? Colors.red : const Color(0xFF93C5FD),
                          width: 3,
                        ),
                      ),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red[700] : const Color(0xFF1E56A0),
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRecording
                        ? "Sedang merekam suara... Tekan untuk kirim"
                        : "Tahan untuk Berbicara / Tekan Bicara",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.red[700] : const Color(0xFF1E56A0),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMinang
                        ? "Danga dalam dialek Minang atau Bahasa Indonesia"
                        : "Dengarkan dalam dialek Minang atau Bahasa Indonesia",
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

