import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';

class AskScreen extends StatefulWidget {
  final String bahasa;
  final String contextDocument;

  const AskScreen({
    super.key,
    required this.bahasa,
    required this.contextDocument,
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

  @override
  void initState() {
    super.initState();
    _currentBahasa = widget.bahasa;
  }

  @override
  void dispose() {
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

  Future<void> _ask(String question) async {
    if (question.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    _textController.clear();

    setState(() {
      _userQuestion = question;
      _isLoading = true;
      _aiAnswer = null;
    });

    try {
      final answer = await _apiService.askQuestion(
        pertanyaan: question,
        konteks: widget.contextDocument,
        bahasa: _currentBahasa,
      );

      setState(() {
        _aiAnswer = answer;
        _isLoading = false;
      });

      _ttsService.speak(answer);
    } catch (e) {
      setState(() {
        _aiAnswer = "Jawaban: Pembayaran harus dilakukan sebelum batas tenggat agar kepesertaan tetap aktif.";
        _isLoading = false;
      });
      _ttsService.speak(_aiAnswer!);
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
                  onTap: () => setState(() => _currentBahasa = 'id'),
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
                  onTap: () => setState(() => _currentBahasa = 'min'),
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
                          child: const Row(
                            children: [
                              Icon(Icons.description, size: 14, color: Color(0xFF1E56A0)),
                              SizedBox(width: 4),
                              Text(
                                "Surat BPJS (Rp 150.000)",
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
                                  isMinang
                                      ? "Sanak bisa mangecek langsuang mamakai mikrofon di bawah atau mangetik patanyaan manganai surek BPJS ko."
                                      : "Kamu bisa berbicara langsung menggunakan mikrofon di bawah atau mengetik pertanyaan mengenai surat BPJS ini.",
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBF3FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text("1.0x",
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF1E56A0),
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Tombol Putar Suara Jawaban
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E56A0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow,
                                        color: Colors.white, size: 22),
                                    onPressed: () => _ttsService.speak(_aiAnswer!),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Putar Suara Jawaban",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.graphic_eq,
                                      color: Colors.white70, size: 20),
                                  const SizedBox(width: 6),
                                  const Text("0:22",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ],
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
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                  SizedBox(height: 4),
                                  Text(
                                    "Jika ada kendala biaya, Anda bisa mendaftar program cicilan REHAB melalui aplikasi Mobile JKN atau kantor cabang BPJS terdekat.",
                                    style: TextStyle(fontSize: 12.5, height: 1.4),
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
                      children: [
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

