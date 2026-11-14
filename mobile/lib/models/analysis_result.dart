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
    this.judul = "Surat Pemberitahuan Tunggakan & Iuran JKN-KIS",
    this.jenisDokumen = "Dokumen Resmi Terverifikasi: BPJS Kesehatan",
    this.nomorPeserta = "0001829381xxx",
    required this.penjelasan,
    required this.tenggat,
    this.tenggatSub = "Bayar sebelum tanggal ini agar kartu aktif kembali.",
    required this.nominal,
    this.nominalSub = "Total tagihan yang harus dibayar",
    this.rincian = "Iuran Pokok & Biaya Administrasi Resmi",
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
      } else {
        langkah = [
          "Kunjungi Indomaret/Alfamart, ATM, atau kantor Pos terdekat.",
          "Sebutkan atau tunjukkan nomor BPJS / dokumen ke kasir/petugas.",
          "Simpan struk / bukti pembayaran sampai status kembali aktif."
        ];
      }
    }

    return AnalysisResult(
      judul: json['judul']?.toString() ?? "Surat Pemberitahuan Dokumen",
      jenisDokumen: json['jenis_dokumen']?.toString() ?? "Dokumen Resmi Terverifikasi: BPJS Kesehatan",
      nomorPeserta: json['nomor_peserta']?.toString() ?? "0001829381xxx",
      penjelasan: json['penjelasan']?.toString() ?? '-',
      tenggat: json['tenggat']?.toString() ?? '-',
      tenggatSub: json['tenggat_sub']?.toString() ?? "Bayar sebelum tanggal ini agar kartu aktif kembali.",
      nominal: json['nominal']?.toString() ?? '-',
      nominalSub: json['nominal_sub']?.toString() ?? "Total tagihan yang harus dibayar",
      rincian: json['rincian']?.toString() ?? "Iuran Pokok & Administrasi",
      tindakan: tindakanText,
      langkahTindakan: langkah,
    );
  }

  String toSpeechText({required String bahasa}) {
    if (bahasa == 'min') {
      return "Inti surek ko: $penjelasan. "
          "Tenggat wakatu: $tenggat. "
          "Nominal nan harus dibayia: $nominal. "
          "Tindakan nan paralu sanak karajoan: $tindakan.";
    }
    return "Inti surat ini: $penjelasan. "
        "Tenggat waktu pembayaran: $tenggat. "
        "Jumlah yang harus dibayar: $nominal. "
        "Tindakan yang harus dilakukan: $tindakan.";
  }
}
