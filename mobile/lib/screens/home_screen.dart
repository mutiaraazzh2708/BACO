import 'dart:io';
import 'package:flutter/material.dart';
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
  double _fontScale = 1.0; // 0.9 = Kecil, 1.0 = Normal, 1.15 = Besar
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (picked != null && mounted) {
        Navigator.push(
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
    }
  }

  void _playIntroVoice() {
    if (_selectedBahasa == 'min') {
      _ttsService.speak(
        "Salamaik datang di BACO! Asisten Suara untuak Mambaco Dokumen Layanan Publik. "
        "Takan tombol Foto Dokumen di bawah untuak mamoto surek sanak, nantik ambo bacoan intinyo.",
      );
    } else {
      _ttsService.speak(
        "Selamat datang di BACO! Asisten suara untuk memahami dokumen resmi. "
        "Arahkan kamera ke surat atau dokumen Anda, tekan tombol Foto Dokumen di bawah, "
        "dan BACO akan membacakan rangkumannya dengan suara jernih.",
      );
    }
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: _apiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pengaturan Alamat Server"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan alamat backend FastAPI (contoh: http://10.246.74.45:8000)",
              style: TextStyle(fontSize: 14),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E56A0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.hearing,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "BACO",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E56A0),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  // Toggle Bahasa Pill
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedBahasa = 'id'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedBahasa == 'id'
                                  ? const Color(0xFF1E56A0)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                if (_selectedBahasa == 'id') ...[
                                  const Icon(Icons.pause,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  "Indonesia",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedBahasa == 'id'
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedBahasa = 'min'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedBahasa == 'min'
                                  ? const Color(0xFF1E56A0)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Minang",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedBahasa == 'min'
                                    ? Colors.white
                                    : Colors.grey[700],
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
                  color: const Color(0xFFEEF5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD0E1FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up,
                        size: 20, color: Color(0xFF1E56A0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMinang
                            ? "Mode Aksesibilitas Suara Aktif"
                            : "Mode Aksesibilitas Suara Aktif",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E56A0),
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
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.settings, size: 18, color: Color(0xFF1E56A0)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: "Pengaturan IP Backend",
                      onPressed: _showSettingsDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // --- Ukuran Teks Adjuster ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_fields,
                          size: 18, color: Color(0xFF1E56A0)),
                      const SizedBox(width: 6),
                      Text(
                        "Ukuran: ${_fontScale < 1.0 ? 'Kecil' : _fontScale == 1.0 ? 'Normal' : 'Besar'}",
                        style: TextStyle(
                          fontSize: 13 * _fontScale,
                          color: Colors.grey[700],
                        ),
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
              const SizedBox(height: 16),

              // --- Badge Layanan Terbuka & Gratis ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EDFD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 16, color: Color(0xFF1E56A0)),
                    const SizedBox(width: 6),
                    Text(
                      "Layanan Suara Terbuka & Gratis",
                      style: TextStyle(
                        fontSize: 12 * _fontScale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E56A0),
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
                  color: Colors.black87,
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
                  color: const Color(0xFF1E56A0),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isMinang
                    ? "Arahkan kamera ka surek atau dokumen resmi sanak, BACO ka mambacoan dan manjalaskannyo langsuang lewaik suaro janiah."
                    : "Arahkan kamera ke surat atau dokumen resmi Anda, BACO akan membacakan dan menjelaskannya langsung lewat suara jernih.",
                style: TextStyle(
                  fontSize: 15 * _fontScale,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),

              // --- Card: Panduan Singkat ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
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
                            color: const Color(0xFFEBF3FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.record_voice_over,
                              color: Color(0xFF1E56A0), size: 28),
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
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isMinang
                                    ? "Danga patunjuak 20 datiak"
                                    : "Dengarkan petunjuk 20 detik",
                                style: TextStyle(
                                  fontSize: 13 * _fontScale,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sound wave visualizer icon
                        const Icon(Icons.graphic_eq,
                            color: Color(0xFF1E56A0), size: 30),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _playIntroVoice,
                        icon: const Icon(Icons.play_arrow, size: 22),
                        label: Text(
                          isMinang
                              ? "Danga Panduan Suara 🔊"
                              : "Dengarkan Panduan Suara 🔊",
                          style: TextStyle(
                            fontSize: 14 * _fontScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEBF3FF),
                          foregroundColor: const Color(0xFF1E56A0),
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

              // --- Tombol Utama: Foto Dokumen (Besar, Biru, ada Panah) ---
              InkWell(
                onTap: () => _pickImage(ImageSource.camera),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E56A0),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E56A0).withOpacity(0.35),
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
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "📸 Foto Dokumen",
                                  style: TextStyle(
                                    fontSize: 19 * _fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMinang
                                  ? "Sentuh untuak mamindai surek fisik"
                                  : "Sentuh untuk memindai surat fisik",
                              style: TextStyle(
                                fontSize: 13 * _fontScale,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // --- Tombol Sekunder: Pilih dari Galeri HP ---
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF1E56A0), size: 22),
                label: Text(
                  isMinang ? "🖼️ Piliah dari Galeri HP" : "🖼️ Pilih dari Galeri HP",
                  style: TextStyle(
                    fontSize: 16 * _fontScale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E56A0),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF1E56A0), width: 1.5),
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
                    isMinang
                        ? "Jinih Surek Nan Bisa Dibantu:"
                        : "Jenis Surat Yang Bisa Dibantu:",
                    style: TextStyle(
                      fontSize: 16 * _fontScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "Otomatis & Akurat",
                    style: TextStyle(
                      fontSize: 12 * _fontScale,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E56A0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildSuratCard(
                icon: Icons.shield,
                iconColor: const Color(0xFF1E56A0),
                bgColor: const Color(0xFFEEF5FF),
                title: "📄 Surat BPJS & Kesehatan",
                desc: "Rujukan puskesmas, obat, status aktif iuran",
              ),
              const SizedBox(height: 10),
              _buildSuratCard(
                icon: Icons.bolt,
                iconColor: Colors.amber[800]!,
                bgColor: const Color(0xFFFFF7ED),
                title: "⚡ Tagihan Listrik & Air (PDAM)",
                desc: "Nominal jatuh tempo dibaca jelas tanpa keliru",
              ),
              const SizedBox(height: 10),
              _buildSuratCard(
                icon: Icons.account_balance,
                iconColor: Colors.green[700]!,
                bgColor: const Color(0xFFF0FDF4),
                title: "🏛️ Surat Kelurahan & RT/RW",
                desc: "Undangan bansos, pengantar KTP, himbauan warga",
              ),
              const SizedBox(height: 18),

              // --- Footer Banner: Dirancang Khusus Aksesibilitas ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.accessibility_new,
                        color: Color(0xFF1E56A0), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isMinang
                            ? "Dirancang khusus ramah lansia & tunanetra jo navigasi sederhana dan audio otomatis."
                            : "Dirancang khusus ramah lansia & tunanetra dengan navigasi sederhana dan audio otomatis.",
                        style: TextStyle(
                          fontSize: 13 * _fontScale,
                          color: const Color(0xFF1E56A0),
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
        selectedItemColor: const Color(0xFF1E56A0),
        unselectedItemColor: Colors.grey[500],
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 1) {
            _pickImage(ImageSource.camera);
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AskScreen(
                  bahasa: _selectedBahasa,
                  contextDocument: "Dokumen umum layanan publik BPJS Kesehatan",
                ),
              ),
            );
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

  Widget _buildSuratCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12.5 * _fontScale,
                    color: Colors.grey[600],
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
