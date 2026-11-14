import 'dart:io';
import 'package:flutter/material.dart';
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
  double _fontScale = 1.0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _currentBahasa = widget.bahasa;
    _speakContent();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _speakContent() {
    setState(() => _isPlaying = true);
    final text = widget.result.toSpeechText(bahasa: _currentBahasa);
    _ttsService.speak(text);
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _ttsService.stop();
      setState(() => _isPlaying = false);
    } else {
      _speakContent();
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.hearing, color: Color(0xFF1E56A0)),
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
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _currentBahasa = 'id');
                          _speakContent();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentBahasa == 'id'
                                ? const Color(0xFF1E56A0)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_currentBahasa == 'id') ...[
                                const Icon(Icons.pause, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                "Bahasa Indonesia",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _currentBahasa == 'id'
                                      ? Colors.white
                                      : Colors.grey[700],
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
                          setState(() => _currentBahasa = 'min');
                          _speakContent();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentBahasa == 'min'
                                ? const Color(0xFF1E56A0)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Baso Minang",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _currentBahasa == 'min'
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- Ukuran Teks Adjuster ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_fields, size: 18, color: Color(0xFF1E56A0)),
                      const SizedBox(width: 6),
                      Text(
                        "Ukuran Teks: ${_fontScale < 1.0 ? 'Kecil' : _fontScale == 1.0 ? 'Sedang' : 'Besar'}",
                        style: TextStyle(fontSize: 13 * _fontScale, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildSizeButton("A-", _fontScale == 0.9,
                            () => setState(() => _fontScale = 0.9)),
                        Container(width: 1, height: 24, color: Colors.grey[300]),
                        _buildSizeButton("A", _fontScale == 1.0,
                            () => setState(() => _fontScale = 1.0)),
                        Container(width: 1, height: 24, color: Colors.grey[300]),
                        _buildSizeButton("A+", _fontScale == 1.15,
                            () => setState(() => _fontScale = 1.15)),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD0E1FD)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Tombol Play / Pause
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E56A0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
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
                                  const Icon(Icons.graphic_eq, color: Color(0xFF1E56A0), size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    isMinang
                                        ? "Sedang mambacoan isi surek..."
                                        : "Sedang membacakan isi surat...",
                                    style: TextStyle(
                                      fontSize: 13 * _fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "01:24 / 02:40",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF3FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "1.0x",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E56A0),
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
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '"${widget.result.tenggatSub}"',
                        style: TextStyle(
                          fontSize: 13 * _fontScale,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF713F12),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Green Verified Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF059669)),
                          const SizedBox(width: 6),
                          Text(
                            widget.result.jenisDokumen,
                            style: TextStyle(
                              fontSize: 11 * _fontScale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF065F46),
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
                        color: const Color(0xFF1E56A0),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "Diterima: 14 Mei 2024",
                          style: TextStyle(fontSize: 12 * _fontScale, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          "No. Peserta: ${widget.result.nomorPeserta}",
                          style: TextStyle(
                            fontSize: 12 * _fontScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Color(0xFF1E56A0), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isMinang ? "Inti Surek Ko:" : "Inti Surat Ini:",
                          style: TextStyle(
                            fontSize: 16 * _fontScale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E56A0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.result.penjelasan,
                      style: TextStyle(
                        fontSize: 14.5 * _fontScale,
                        color: Colors.black87,
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
                  color: const Color(0xFF1E56A0),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Kartu 1: Tenggat Waktu
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.alarm, size: 14, color: Color(0xFFB45309)),
                              const SizedBox(width: 6),
                              Text(
                                "TENGGAT WAKTU",
                                style: TextStyle(
                                  fontSize: 11 * _fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB45309),
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
                            color: const Color(0xFFD97706),
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.result.tenggatSub,
                      style: TextStyle(fontSize: 13 * _fontScale, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Kartu 2: Jumlah yang Harus Dibayar
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments, size: 14, color: Color(0xFF1E40AF)),
                          const SizedBox(width: 6),
                          Text(
                            "JUMLAH YANG HARUS DIBAYAR",
                            style: TextStyle(
                              fontSize: 11 * _fontScale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E40AF),
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
                        color: const Color(0xFF1E56A0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.result.nominalSub,
                      style: TextStyle(fontSize: 13 * _fontScale, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Rincian: ${widget.result.rincian}",
                        style: TextStyle(fontSize: 12 * _fontScale, color: Colors.grey[700]),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_box, size: 14, color: Color(0xFF065F46)),
                          const SizedBox(width: 6),
                          Text(
                            "CARA & TINDAKAN",
                            style: TextStyle(
                              fontSize: 11 * _fontScale,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF065F46),
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
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "${i + 1}",
                              style: const TextStyle(
                                color: Colors.white,
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
                                color: Colors.black87,
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

              // Catatan Penting Card (Kuning)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE047)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFB45309), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isMinang ? "Catatan Pantiang:" : "Catatan Penting:",
                          style: TextStyle(
                            fontSize: 14 * _fontScale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB45309),
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
                        color: Colors.yellow[900],
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
                    _ttsService.stop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AskScreen(
                          bahasa: _currentBahasa,
                          contextDocument: widget.result.toSpeechText(bahasa: _currentBahasa),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 22),
                  label: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isMinang
                            ? "Masih Raguk? Batanyo ka BACO"
                            : "Masih Bingung? Tanya BACO Sekarang",
                        style: TextStyle(
                          fontSize: 16 * _fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E56A0),
                    foregroundColor: Colors.white,
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
        color: active ? const Color(0xFF1E56A0) : Colors.transparent,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : Colors.grey[800],
          ),
        ),
      ),
    );
  }
}
