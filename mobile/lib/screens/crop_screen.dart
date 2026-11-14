import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CropScreen extends StatefulWidget {
  final File imageFile;
  final String bahasa;

  const CropScreen({
    super.key,
    required this.imageFile,
    required this.bahasa,
  });

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  ui.Image? _decodedImage;
  bool _isLoading = true;

  // Normalized crop rectangle: 0.0 sampai 1.0 relatif terhadap dimensi gambar
  double _cropLeft = 0.05;
  double _cropTop = 0.05;
  double _cropRight = 0.95;
  double _cropBottom = 0.95;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _decodedImage = frame.image;
        _isLoading = false;
      });
    } catch (_) {
      Navigator.pop(context);
    }
  }

  Future<void> _applyCrop() async {
    if (_decodedImage == null) return;

    setState(() => _isLoading = true);

    try {
      final img = _decodedImage!;
      final imgW = img.width.toDouble();
      final imgH = img.height.toDouble();

      final srcX = (_cropLeft * imgW).clamp(0.0, imgW);
      final srcY = (_cropTop * imgH).clamp(0.0, imgH);
      final srcW = ((_cropRight - _cropLeft) * imgW).clamp(20.0, imgW - srcX);
      final srcH = ((_cropBottom - _cropTop) * imgH).clamp(20.0, imgH - srcY);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final srcRect = Rect.fromLTWH(srcX, srcY, srcW, srcH);
      final dstRect = Rect.fromLTWH(0, 0, srcW, srcH);

      canvas.drawImageRect(img, srcRect, dstRect, Paint());
      final picture = recorder.endRecording();
      final croppedUiImage = await picture.toImage(srcW.round(), srcH.round());
      final byteData =
          await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final tempPath =
            '${Directory.systemTemp.path}/crop_${DateTime.now().millisecondsSinceEpoch}.png';
        final croppedFile = File(tempPath);
        await croppedFile.writeAsBytes(byteData.buffer.asUint8List());

        if (mounted) {
          Navigator.pop(context, croppedFile);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memotong gambar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMinang = widget.bahasa == 'min';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          isMinang ? "Potong Dokumen (Crop)" : "Potong Dokumen (Crop)",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _applyCrop,
            icon: const Icon(Icons.check, color: Color(0xFF38BDF8), size: 20),
            label: Text(
              isMinang ? "Terapkan" : "Terapkan",
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Instruksi
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFF1E293B),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.touch_app,
                            color: Color(0xFF38BDF8), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          isMinang
                              ? "Geser suduik kotak untuak marapikan pinggia karateh"
                              : "Geser sudut kotak untuk merapikan tepi dokumen",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // Area Gambar dengan Crop Box
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boxW = constraints.maxWidth;
                        final boxH = constraints.maxHeight;

                        final imgW = _decodedImage!.width.toDouble();
                        final imgH = _decodedImage!.height.toDouble();

                        // Hitung posisi tampilan gambar agar pas di layar
                        final scale =
                            (boxW / imgW < boxH / imgH) ? boxW / imgW : boxH / imgH;
                        final renderW = imgW * scale;
                        final renderH = imgH * scale;
                        final renderLeft = (boxW - renderW) / 2;
                        final renderTop = (boxH - renderH) / 2;

                        return Stack(
                          children: [
                            // Tampilan Gambar Asli
                            Positioned(
                              left: renderLeft,
                              top: renderTop,
                              width: renderW,
                              height: renderH,
                              child: RawImage(
                                image: _decodedImage,
                                fit: BoxFit.fill,
                              ),
                            ),

                            // Overlay Gelap & Bingkai Crop
                            Positioned.fill(
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  // Geser seluruh kotak crop jika disentuh di tengah
                                  final dx = details.delta.dx / renderW;
                                  final dy = details.delta.dy / renderH;

                                  final width = _cropRight - _cropLeft;
                                  final height = _cropBottom - _cropTop;

                                  setState(() {
                                    if (_cropLeft + dx >= 0 &&
                                        _cropRight + dx <= 1.0) {
                                      _cropLeft += dx;
                                      _cropRight = _cropLeft + width;
                                    }
                                    if (_cropTop + dy >= 0 &&
                                        _cropBottom + dy <= 1.0) {
                                      _cropTop += dy;
                                      _cropBottom = _cropTop + height;
                                    }
                                  });
                                },
                                child: CustomPaint(
                                  painter: CropOverlayPainter(
                                    renderRect: Rect.fromLTWH(renderLeft,
                                        renderTop, renderW, renderH),
                                    cropLeft: _cropLeft,
                                    cropTop: _cropTop,
                                    cropRight: _cropRight,
                                    cropBottom: _cropBottom,
                                  ),
                                ),
                              ),
                            ),

                            // 4 Sudut Handle yang Dapat Ditarik (Interactive Handles)
                            // 1. Kiri Atas
                            _buildHandle(
                              x: renderLeft + _cropLeft * renderW,
                              y: renderTop + _cropTop * renderH,
                              onDrag: (dx, dy) {
                                setState(() {
                                  _cropLeft = (_cropLeft + dx / renderW)
                                      .clamp(0.0, _cropRight - 0.15);
                                  _cropTop = (_cropTop + dy / renderH)
                                      .clamp(0.0, _cropBottom - 0.15);
                                });
                              },
                            ),

                            // 2. Kanan Atas
                            _buildHandle(
                              x: renderLeft + _cropRight * renderW,
                              y: renderTop + _cropTop * renderH,
                              onDrag: (dx, dy) {
                                setState(() {
                                  _cropRight = (_cropRight + dx / renderW)
                                      .clamp(_cropLeft + 0.15, 1.0);
                                  _cropTop = (_cropTop + dy / renderH)
                                      .clamp(0.0, _cropBottom - 0.15);
                                });
                              },
                            ),

                            // 3. Kiri Bawah
                            _buildHandle(
                              x: renderLeft + _cropLeft * renderW,
                              y: renderTop + _cropBottom * renderH,
                              onDrag: (dx, dy) {
                                setState(() {
                                  _cropLeft = (_cropLeft + dx / renderW)
                                      .clamp(0.0, _cropRight - 0.15);
                                  _cropBottom = (_cropBottom + dy / renderH)
                                      .clamp(_cropTop + 0.15, 1.0);
                                });
                              },
                            ),

                            // 4. Kanan Bawah
                            _buildHandle(
                              x: renderLeft + _cropRight * renderW,
                              y: renderTop + _cropBottom * renderH,
                              onDrag: (dx, dy) {
                                setState(() {
                                  _cropRight = (_cropRight + dx / renderW)
                                      .clamp(_cropLeft + 0.15, 1.0);
                                  _cropBottom = (_cropBottom + dy / renderH)
                                      .clamp(_cropTop + 0.15, 1.0);
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Preset Cepat di Bawah
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: const Color(0xFF0F172A),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPresetButton("Penuh (Reset)", () {
                          setState(() {
                            _cropLeft = 0.02;
                            _cropTop = 0.02;
                            _cropRight = 0.98;
                            _cropBottom = 0.98;
                          });
                        }),
                        _buildPresetButton("Format A4 / Surat", () {
                          setState(() {
                            _cropLeft = 0.12;
                            _cropTop = 0.05;
                            _cropRight = 0.88;
                            _cropBottom = 0.95;
                          });
                        }),
                        _buildPresetButton("Kartu ID / BPJS", () {
                          setState(() {
                            _cropLeft = 0.08;
                            _cropTop = 0.25;
                            _cropRight = 0.92;
                            _cropBottom = 0.75;
                          });
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHandle({
    required double x,
    required double y,
    required Function(double dx, double dy) onDrag,
  }) {
    return Positioned(
      left: x - 20,
      top: y - 20,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: Container(
          width: 40,
          height: 40,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect renderRect;
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  CropOverlayPainter({
    required this.renderRect,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cropX = renderRect.left + cropLeft * renderRect.width;
    final cropY = renderRect.top + cropTop * renderRect.height;
    final cropW = (cropRight - cropLeft) * renderRect.width;
    final cropH = (cropBottom - cropTop) * renderRect.height;
    final cropRect = Rect.fromLTWH(cropX, cropY, cropW, cropH);

    // 1. Gambar layer semi-transparan di luar kotak crop
    final darkPaint = Paint()..color = Colors.black.withOpacity(0.65);

    // Kiri
    canvas.drawRect(
        Rect.fromLTRB(0, 0, cropRect.left, size.height), darkPaint);
    // Kanan
    canvas.drawRect(
        Rect.fromLTRB(cropRect.right, 0, size.width, size.height), darkPaint);
    // Atas
    canvas.drawRect(
        Rect.fromLTRB(cropRect.left, 0, cropRect.right, cropRect.top),
        darkPaint);
    // Bawah
    canvas.drawRect(
        Rect.fromLTRB(cropRect.left, cropRect.bottom, cropRect.right,
            size.height),
        darkPaint);

    // 2. Garis batas kotak crop (Putih & Biru Terang)
    final borderPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(cropRect, borderPaint);

    // 3. Garis grid pembantu (Rule of Thirds)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
        Offset(cropRect.left + cropW / 3, cropRect.top),
        Offset(cropRect.left + cropW / 3, cropRect.bottom),
        gridPaint);
    canvas.drawLine(
        Offset(cropRect.left + 2 * cropW / 3, cropRect.top),
        Offset(cropRect.left + 2 * cropW / 3, cropRect.bottom),
        gridPaint);
    canvas.drawLine(
        Offset(cropRect.left, cropRect.top + cropH / 3),
        Offset(cropRect.right, cropRect.top + cropH / 3),
        gridPaint);
    canvas.drawLine(
        Offset(cropRect.left, cropRect.top + 2 * cropH / 3),
        Offset(cropRect.right, cropRect.top + 2 * cropH / 3),
        gridPaint);
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.cropLeft != cropLeft ||
        oldDelegate.cropTop != cropTop ||
        oldDelegate.cropRight != cropRight ||
        oldDelegate.cropBottom != cropBottom;
  }
}

