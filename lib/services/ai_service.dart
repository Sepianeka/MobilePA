import 'dart:convert';
import 'package:http/http.dart' as http;

/// Chatbot edukasi memakai Gemini API.
/// Jalankan dengan: flutter run --dart-define=GEMINI_KEY=kunci_kamu
/// Tanpa key, aplikasi memakai jawaban contoh supaya demo tetap jalan.
class AiService {
  // Cek nama model terbaru di dokumentasi Google AI Studio bila error 404.
  static const _model = 'gemini-2.5-flash';
  static const _key = String.fromEnvironment('GEMINI_KEY');
  static bool get hasKey => _key.isNotEmpty;

  static const _system =
      'Kamu CoinWise Tutor, asisten edukasi keuangan dan kripto untuk pelajar '
      'dan mahasiswa Indonesia. Jawab dalam bahasa Indonesia yang ringkas, '
      'pakai analogi sederhana, maksimal 120 kata. Jangan memberi saran '
      'investasi pribadi; ingatkan bahwa ini bersifat edukasi.';

  static Future<String> ask(String question) async {
    if (!hasKey) {
      return 'Mode contoh (belum ada GEMINI_KEY). Blockchain adalah buku catatan '
          'digital yang disalin ke banyak komputer. Tiap halaman (blok) terkunci '
          'dengan hash ke halaman sebelumnya, jadi mengubah satu catatan akan '
          'ketahuan. Ini hanya edukasi, bukan saran investasi.';
    }
    try {
      final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_key');
      final r = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': _system}
                ]
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': question}
                  ]
                }
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return 'Maaf, AI sedang tidak tersedia (kode ${r.statusCode}).';
      final j = jsonDecode(r.body);
      return (j['candidates'][0]['content']['parts'][0]['text'] as String).trim();
    } catch (_) {
      return 'Maaf, tidak bisa terhubung ke AI. Periksa koneksi internetmu.';
    }
  }
}
