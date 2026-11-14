import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/tts_service.dart';
import 'processing_screen.dart';

class CameraPreviewScreen extends StatefulWidget {
  final File imageFile;
  final String bahasa;

  const CameraPreviewScreen({
    super.key,
    required this.imageFile,
    required this.bahasa,
  });

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late File _currentImage;
  final ImagePicker _picker = ImagePicker();
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _currentImage = widget.imageFile;

    // Ucapkan panduan suara saat masuk ke layar kamera/pratinjau
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.bahasa == 'min') {
        _ttsService.speak("Posisikan sadoalah karateh dalam bingkai, pastian nampak jaleh.");
      } else {
        _ttsService.speak("Posisikan seluruh kertas dalam bingkai, pastikan terlihat jelas.");
      }
    });
  }

  Future<void> _retakePhoto(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 100);
      if (picked != null) {
        setState(() {
          _currentImage = File(picked.path);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isMinang = widget.bahasa == 'min';
    final fileName = _currentImage.path.split(Platform.pathSeparator).last;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // --- Header: Kembali ke Beranda & Flash ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back, size: 18, color: Colors.black87),
                          const SizedBox(width: 6),
                          Text(
                            isMinang ? "Kambali ka Beranda" : "Kembali ke Beranda",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on, color: Colors.amber, size: 22),
                  ),
                ],
              ),
            ),

            // Banner Petunjuk Pencahayaan
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.light_mode, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    isMinang
                        ? "Pastian cahayo cukuik & dokumen data"
                        : "Pastikan cahaya cukup & dokumen datar",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Banner Suara BACO
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E56A0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMinang
                          ? 'BACO: "Posisikan sadoalah karateh dalam bingkai"'
                          : 'BACO: "Posisikan seluruh kertas dalam bingkai"',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Area Pratinjau Dokumen ---
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E56A0), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        _currentImage,
                        fit: BoxFit.cover,
                      ),
                      // Reticle di tengah
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.crop_free, color: Colors.white70, size: 30),
                        ),
                      ),
                      // Badge Teks Dokumen Terdeteksi Jelas
                      Positioned(
                        bottom: 14,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF065F46).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF34D399)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                isMinang
                                    ? "Teks Dokumen Nampak Jaleh"
                                    : "Teks Dokumen Terdeteksi Jelas",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Bagian Bawah Kontrol ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Info Berkas File
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_currentImage, width: 44, height: 44, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName.length > 24 ? "${fileName.substring(0, 20)}...jpg" : fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Row(
                                children: [
                                  Icon(Icons.check, color: Color(0xFF34D399), size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "Siap dibacakan BACO",
                                    style: TextStyle(color: Color(0xFF34D399), fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _retakePhoto(ImageSource.camera),
                          child: const Text("Ulangi", style: TextStyle(color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3 Tombol: Galeri, Shutter, Balik Kamera
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _retakePhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, color: Colors.white70, size: 28),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              padding: const EdgeInsets.all(14),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text("Galeri", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      // Tombol Shutter Utama
                      GestureDetector(
                        onTap: () => _retakePhoto(ImageSource.camera),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent, width: 3),
                          ),
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.camera_alt, color: Color(0xFF1E56A0), size: 30),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _retakePhoto(ImageSource.camera),
                            icon: const Icon(Icons.flip_camera_android, color: Colors.white70, size: 28),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              padding: const EdgeInsets.all(14),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text("Balik Kamera", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tombol "Baca Dokumen Ini ->"
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProcessingScreen(
                              imageFile: _currentImage,
                              bahasa: widget.bahasa,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E56A0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isMinang ? "Baco Dokumen Ko" : "Baca Dokumen Ini",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMinang
                        ? "Manuju pamindaian jo pambacoan suaro AI"
                        : "Menuju pemindaian dan pembacaan suara AI",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

