import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class RatesResult {
  final Map<String, double> perIdr; // nilai 1 IDR dalam mata uang lain
  final bool live;
  const RatesResult(this.perIdr, this.live);
}

/// Kurs dari Frankfurter (gratis, tanpa API key).
class CurrencyService {
  static const symbols = ['USD', 'EUR', 'JPY', 'SGD'];

  static Future<RatesResult> fetchRates() async {
    try {
      final uri = Uri.parse(
          'https://api.frankfurter.dev/v1/latest?base=IDR&symbols=${symbols.join(',')}');
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final rates = (jsonDecode(r.body)['rates'] as Map)
          .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
      if (rates.isEmpty) throw Exception('kosong');
      return RatesResult(rates, true);
    } catch (_) {
      return const RatesResult(MockData.rates, false);
    }
  }
}
