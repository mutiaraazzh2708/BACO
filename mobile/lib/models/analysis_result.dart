class AnalysisResult {
  final String judul;
  final String jenisDokumen;
  final String nomorPeserta;
  final String penjelasan;
  final String tenggat;
  final String tenggatSub;
  final String nominal;
  final String nominalSub;
  final String rincian;
  final String tindakan;
  final List<String> langkahTindakan;
  final List<String> saranPertanyaan;

  AnalysisResult({
    this.judul = "Dokumen Fisik",
    this.jenisDokumen = "Dokumen Terverifikasi",
    this.nomorPeserta = "",
    required this.penjelasan,
    required this.tenggat,
    this.tenggatSub = "Perhatikan informasi penting di atas.",
    required this.nominal,
    this.nominalSub = "Rincian biaya atau informasi terkait",
    this.rincian = "Rincian Dokumen",
    required this.tindakan,
    this.langkahTindakan = const [],
    this.saranPertanyaan = const [],
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final tindakanText = json['tindakan']?.toString() ?? '-';
    
    // Pecah tindakan menjadi langkah jika format teks panjang atau poin
    List<String> langkah = [];
    if (json['langkah_tindakan'] is List) {
      langkah = List<String>.from(json['langkah_tindakan']);
    } else {
      if (tindakanText.contains(";")) {
        langkah = tindakanText.split(";").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (tindakanText.contains(".")) {
        langkah = tindakanText.split(".").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (tindakanText.isNotEmpty && tindakanText != '-') {
        langkah = [tindakanText];
      } else {
        langkah = [
          "Simpan dan bawa berkas ini saat menghadiri acara atau mengurus keperluan terkait.",
          "Perhatikan instruksi atau informasi penting yang tertera pada berkas."
        ];
      }
    }

    final judulParsed = json['judul']?.toString();
    final jenisParsed = json['jenis_dokumen']?.toString();
    final tenggatText = json['tenggat']?.toString() ?? 'Tidak ada';
    final nominalText = json['nominal']?.toString() ?? 'Tidak ada';
    final penjelasanText = json['penjelasan']?.toString() ?? '-';

    // Subtitle tenggat yang dinamis
    String dynamicTenggatSub = json['tenggat_sub']?.toString() ?? '';
    if (dynamicTenggatSub.isEmpty || dynamicTenggatSub == '-') {
      if (tenggatText == 'Tidak ada' || tenggatText.isEmpty) {
        dynamicTenggatSub = "Tidak ada batas waktu penting pada dokumen ini.";
      } else {
        dynamicTenggatSub = "Jadwal atau tanggal penting pada dokumen.";
      }
    }

    // Subtitle nominal yang dinamis
    String dynamicNominalSub = json['nominal_sub']?.toString() ?? '';
    if (dynamicNominalSub.isEmpty || dynamicNominalSub == '-') {
      if (nominalText == 'Tidak ada' || nominalText.isEmpty) {
        dynamicNominalSub = "Tidak ada informasi biaya pada dokumen ini.";
      } else if (nominalText.toLowerCase().contains('gratis')) {
        dynamicNominalSub = "Layanan atau kegiatan ini tidak dipungut biaya (Gratis).";
      } else {
        dynamicNominalSub = "Total biaya atau nominal yang tertera.";
      }
    }

    // Saran pertanyaan dinamis dari AI atau fallback cerdas sesuai konteks berkas
    List<String> saran = [];
    if (json['saran_pertanyaan'] is List) {
      saran = List<String>.from(
        (json['saran_pertanyaan'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty),
      );
    }

    if (saran.isEmpty) {
      final p = "$judulParsed $jenisParsed $penjelasanText".toLowerCase();
      final nom = nominalText.toLowerCase();
      final hasMoney = nom != 'tidak ada' && nom != '-' && !nom.contains('gratis');

      if (hasMoney) {
        saran = [
          "Bisa bayar di mana saja?",
          "Kapan batas akhir pembayaran?",
          "Apa rincian biayanya?"
        ];
      } else if (p.contains("lomba") ||
          p.contains("hackathon") ||
          p.contains("peserta") ||
          p.contains("acara") ||
          p.contains("kegiatan")) {
        saran = [
          "Siapa penyelenggara acara ini?",
          "Kapan jadwal pelaksanaannya?",
          "Apa yang harus disiapkan peserta?"
        ];
      } else if (p.contains("ktp") ||
          p.contains("kartu keluarga") ||
          p.contains("kk") ||
          p.contains("identitas")) {
        saran = [
          "Apa fungsi dari dokumen identitas ini?",
          "Berapa lama masa berlakunya?",
          "Di mana tempat pengurusannya?"
        ];
      } else {
        saran = [
          "Apa maksud dan tujuan dokumen ini?",
          "Siapa pihak atau instansi terkait?",
          "Apa tindakan yang harus saya lakukan?"
        ];
      }
    }

    return AnalysisResult(
      judul: (judulParsed != null && judulParsed.isNotEmpty && judulParsed != "Tidak ada")
          ? judulParsed
          : "Dokumen Fisik",
      jenisDokumen: (jenisParsed != null && jenisParsed.isNotEmpty && jenisParsed != "Tidak ada")
          ? "Dokumen: $jenisParsed"
          : "Dokumen Terverifikasi",
      nomorPeserta: json['nomor_peserta']?.toString() ?? "",
      penjelasan: penjelasanText,
      tenggat: tenggatText,
      tenggatSub: dynamicTenggatSub,
      nominal: nominalText,
      nominalSub: dynamicNominalSub,
      rincian: json['rincian']?.toString() ?? "Rincian Dokumen",
      tindakan: tindakanText,
      langkahTindakan: langkah,
      saranPertanyaan: saran,
    );
  }

  String toSpeechText({required String bahasa}) {
    if (bahasa == 'min') {
      return "Judul dokumen: $judul. "
          "Inti isi: $penjelasan. "
          "Tenggat atau jadwal: $tenggat. "
          "Nominal: $nominal. "
          "Tindakan nan paralu sanak karajoan: $tindakan.";
    }
    return "Judul dokumen: $judul. "
        "Inti dokumen ini: $penjelasan. "
        "Tenggat atau jadwal: $tenggat. "
        "Jumlah atau biaya: $nominal. "
        "Tindakan yang harus dilakukan: $tindakan.";
  }
}
