import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/tts_service.dart';
import 'crop_screen.dart';
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

  final TransformationController _transformationController = TransformationController();
  int _quarterTurns = 0; // Rotasi 90 derajat jika foto miring
  bool _isCropped = false;

  // Zoom dalam persen 0–100 (0% = normal/fit, 100% = zoom max)
  int _zoomPercent = 0;
  static const double _minScale = 1.0;
  static const double _maxScale = 5.0;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.imageFile;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.bahasa == 'min') {
        _ttsService.speak("Posisikan dokumen dalam bingkai, sanak bisa cubit untuak zoom atau potong karateh.");
      } else {
        _ttsService.speak("Posisikan dokumen dalam bingkai, Anda dapat memperbesar, menggeser, atau memotong dokumen.");
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _applyZoomPercent(int pct) {
    final clamped = pct.clamp(0, 100);
    // Konversi 0–100% ke skala _minScale–_maxScale
    final scale = _minScale + (clamped / 100.0) * (_maxScale - _minScale);
    _transformationController.value = Matrix4.identity()..scale(scale);
    setState(() => _zoomPercent = clamped);
  }

  void _zoomIn() => _applyZoomPercent(_zoomPercent + 10);
  void _zoomOut() => _applyZoomPercent(_zoomPercent - 10);

  void _resetZoom() {
    _applyZoomPercent(0);
    setState(() => _quarterTurns = 0);
  }

  void _rotateImage() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  Future<void> _openCropScreen() async {
    final cropped = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (context) => CropScreen(
          imageFile: _currentImage,
          bahasa: widget.bahasa,
        ),
      ),
    );

    if (cropped != null && mounted) {
      setState(() {
        _currentImage = cropped;
        _isCropped = true;
        _transformationController.value = Matrix4.identity();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Dokumen berhasil dipotong (Crop)!"),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _revertToOriginal() {
    setState(() {
      _currentImage = widget.imageFile;
      _isCropped = false;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _retakePhoto(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 100);
      if (picked != null) {
        setState(() {
          _currentImage = File(picked.path);
          _isCropped = false;
          _quarterTurns = 0;
          _transformationController.value = Matrix4.identity();
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
                          ? 'BACO: "Posisikan dokumen, cubit untuak zoom / potong"'
                          : 'BACO: "Posisikan dokumen, cubit zoom / potong tepi"',
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

            // --- Area Pratinjau Dokumen (Bisa Zoom In/Out, Geser & Putar) ---
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E56A0), width: 2),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // InteractiveViewer memungkinkan Zoom In, Zoom Out, dan Geser
                      InteractiveViewer(
                        transformationController: _transformationController,
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(40),
                        minScale: _minScale,
                        maxScale: _maxScale,
                        onInteractionEnd: (details) {
                          // Sinkronkan _zoomPercent saat user pinch zoom manual
                          final scale = _transformationController.value.getMaxScaleOnAxis();
                          final pct = (((scale - _minScale) / (_maxScale - _minScale)) * 100).round().clamp(0, 100);
                          if (pct != _zoomPercent) setState(() => _zoomPercent = pct);
                        },
                        child: RotatedBox(
                          quarterTurns: _quarterTurns,
                          child: Center(
                            child: Image.file(
                              _currentImage,
                              fit: BoxFit.contain, // Menampilkan seluruh dokumen utuh
                            ),
                          ),
                        ),
                      ),

                      // Kontrol Zoom, Crop & Rotasi di Sisi Kanan Atas
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tombol Crop / Potong
                              IconButton(
                                icon: const Icon(Icons.crop, color: Color(0xFF38BDF8), size: 24),
                                tooltip: "Potong Dokumen (Crop)",
                                onPressed: _openCropScreen,
                                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                padding: EdgeInsets.zero,
                              ),
                              const Divider(height: 8, color: Colors.white24),
                              // Tombol Zoom +
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.white, size: 22),
                                tooltip: "Perbesar (+10%)",
                                onPressed: _zoomPercent < 100 ? _zoomIn : null,
                                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                padding: EdgeInsets.zero,
                              ),
                              // Label persentase zoom
                              Container(
                                width: 38,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  "$_zoomPercent%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Tombol Zoom -
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.white, size: 22),
                                tooltip: "Perkecil (-10%)",
                                onPressed: _zoomPercent > 0 ? _zoomOut : null,
                                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                padding: EdgeInsets.zero,
                              ),
                              IconButton(
                                icon: const Icon(Icons.rotate_right, color: Colors.white, size: 24),
                                tooltip: "Putar 90°",
                                onPressed: _rotateImage,
                                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                padding: EdgeInsets.zero,
                              ),
                              IconButton(
                                icon: const Icon(Icons.restart_alt, color: Colors.amber, size: 22),
                                tooltip: "Reset Posisi",
                                onPressed: _resetZoom,
                                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Hint Bawah: Cubit untuk zoom atau potong
                      Positioned(
                        bottom: 46,
                        left: 20,
                        right: 20,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              "🔍 Cubit atau tekan +/- untuk Zoom • Tekan ✂️ untuk Potong",
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                        ),
                      ),

                      // Badge Hijau Teks Terdeteksi
                      Positioned(
                        bottom: 8,
                        left: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF065F46).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF34D399)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _isCropped
                                    ? "Dokumen Sudah Dipotong (Teks Jelas)"
                                    : (isMinang
                                        ? "Teks Dokumen Nampak Jaleh"
                                        : "Teks Dokumen Terdeteksi Jelas"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Info Berkas File & Tombol Crop Cepat
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: RotatedBox(
                            quarterTurns: _quarterTurns,
                            child: Image.file(_currentImage, width: 44, height: 44, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName.length > 20 ? "${fileName.substring(0, 16)}...jpg" : fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.check, color: _isCropped ? Colors.blueAccent : const Color(0xFF34D399), size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isCropped ? "Hasil Crop Siap" : "Siap dibacakan BACO",
                                    style: TextStyle(
                                      color: _isCropped ? Colors.blueAccent : const Color(0xFF34D399),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Tombol Potong (Crop) di kartu
                        ElevatedButton.icon(
                          onPressed: _openCropScreen,
                          icon: const Icon(Icons.crop, size: 16),
                          label: const Text("Crop", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                        if (_isCropped) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.undo, color: Colors.amber, size: 20),
                            tooltip: "Kembalikan Foto Asli",
                            onPressed: _revertToOriginal,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3 Tombol: Galeri, Shutter, Balik Kamera
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _retakePhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, color: Colors.white70, size: 26),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text("Galeri", style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.camera_alt, color: Color(0xFF1E56A0), size: 28),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _retakePhoto(ImageSource.camera),
                            icon: const Icon(Icons.flip_camera_android, color: Colors.white70, size: 26),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text("Balik Kamera", style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tombol "Baca Dokumen Ini ->"
                  SizedBox(
                    width: double.infinity,
                    height: 54,
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
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMinang
                        ? "Manuju pamindaian jo pambacoan suaro AI"
                        : "Menuju pemindaian dan pembacaan suara AI",
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
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
