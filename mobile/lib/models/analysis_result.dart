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

    return AnalysisResult(
      judul: (judulParsed != null && judulParsed.isNotEmpty && judulParsed != "Tidak ada")
          ? judulParsed
          : "Dokumen Fisik",
      jenisDokumen: (jenisParsed != null && jenisParsed.isNotEmpty && jenisParsed != "Tidak ada")
          ? "Dokumen: $jenisParsed"
          : "Dokumen Terverifikasi",
      nomorPeserta: json['nomor_peserta']?.toString() ?? "",
      penjelasan: json['penjelasan']?.toString() ?? '-',
      tenggat: tenggatText,
      tenggatSub: dynamicTenggatSub,
      nominal: nominalText,
      nominalSub: dynamicNominalSub,
      rincian: json['rincian']?.toString() ?? "Rincian Dokumen",
      tindakan: tindakanText,
      langkahTindakan: langkah,
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
