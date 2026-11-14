import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // IP Wi-Fi laptop agar HP bisa akses (port 8000)
  // Bisa diganti langsung lewat tombol pengaturan di aplikasi
  String baseUrl = "http://10.246.74.45:8000";

  /// Kompresi foto agar lebar ±1280px sesuai alur sistem BACO
  Future<File> compressImage(File file) async {
    try {
      final tempDir = Directory.systemTemp;
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: 1280,
        minHeight: 1280,
        quality: 85,
      );

      if (result != null) {
        return File(result.path);
      }
    } catch (e) {
      // Jika kompresi gagal, gunakan file asli
    }
    return file;
  }

  /// POST /api/analyze : form-data "foto" + "bahasa" (id / min)
  Future<AnalysisResult> analyzeDocument({
    required File imageFile,
    required String bahasa,
  }) async {
    try {
      final compressed = await compressImage(imageFile);
      final uri = Uri.parse('$baseUrl/api/analyze');

      final request = http.MultipartRequest('POST', uri);
      request.fields['bahasa'] = bahasa;
      request.files.add(
        await http.MultipartFile.fromPath('foto', compressed.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return AnalysisResult.fromJson(data);
      } else {
        String errorMsg = "Gagal memproses dokumen (Status: ${response.statusCode})";
        try {
          final errData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errData['detail'] != null) {
            errorMsg = errData['detail'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } on SocketException {
      throw Exception(
        "Tidak dapat terhubung ke server backend ($baseUrl).\n"
        "Pastikan backend berjalan di laptop dan HP berada di jaringan Wi-Fi/hotspot yang sama.",
      );
    } catch (e) {
      if (e.toString().contains("Exception:")) {
        rethrow;
      }
      throw Exception("Terjadi kendala: $e");
    }
  }

  /// POST /api/stt : form-data "audio" -> {"teks"}
  Future<String> speechToText(File audioFile) async {
    try {
      final uri = Uri.parse('$baseUrl/api/stt');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFile.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['teks']?.toString() ?? "";
      } else {
        String errorMsg = "Gagal transkrip suara (Status: ${response.statusCode})";
        try {
          final errData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errData['detail'] != null) {
            errorMsg = errData['detail'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception("Gagal mengirim suara: $e");
    }
  }

  /// POST /api/translate : JSON {hasil, bahasa} -> hasil dalam Minang
  Future<AnalysisResult> translateToMinang(AnalysisResult original) async {
    try {
      final uri = Uri.parse('$baseUrl/api/translate');
      // Konversi AnalysisResult ke Map untuk dikirim ke backend
      final Map<String, dynamic> payload = {
        'hasil': {
          'judul': original.judul,
          'jenis_dokumen': original.jenisDokumen.replaceFirst('Dokumen: ', ''),
          'penjelasan': original.penjelasan,
          'tenggat': original.tenggat,
          'tenggat_sub': original.tenggatSub,
          'nominal': original.nominal,
          'nominal_sub': original.nominalSub,
          'tindakan': original.tindakan,
          'saran_pertanyaan': original.saranPertanyaan,
        },
        'bahasa': 'min',
      };
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return AnalysisResult.fromJson(data);
      } else {
        throw Exception('Gagal terjemah ke Minang (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Gagal terjemah: $e');
    }
  }

  /// POST /api/ask : JSON {"pertanyaan","konteks","bahasa"} -> {"jawaban"}
  Future<String> askQuestion({
    required String pertanyaan,
    required String konteks,
    required String bahasa,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/ask');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'pertanyaan': pertanyaan,
              'konteks': konteks,
              'bahasa': bahasa,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['jawaban']?.toString() ?? "Tidak ada jawaban.";
      } else {
        String errorMsg = "Gagal menjawab pertanyaan (Status: ${response.statusCode})";
        try {
          final errData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errData['detail'] != null) {
            errorMsg = errData['detail'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception("Gagal mengirim pertanyaan: $e");
    }
  }
}

