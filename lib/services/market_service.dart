import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class MarketResult {
  final List<Coin> coins;
  final bool live;
  const MarketResult(this.coins, this.live);
}

/// Data kripto dari CoinGecko. Jika gagal, otomatis pakai data cadangan.
/// API key (opsional): flutter run --dart-define=COINGECKO_KEY=xxxx
class MarketService {
  static const _ids = 'bitcoin,ethereum,solana,binancecoin,ripple,dogecoin';
  static List<Coin>? _cache;

  static Map<String, String> get _headers {
    const k = String.fromEnvironment('COINGECKO_KEY');
    return k.isEmpty ? {} : {'x-cg-demo-api-key': k};
  }

  static List<Coin> get cached => _cache ?? MockData.coins;

  static Future<MarketResult> fetchCoins() async {
    try {
      final uri = Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=idr&ids=$_ids&order=market_cap_desc');
      final r = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final list = (jsonDecode(r.body) as List)
          .map((e) => Coin.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (list.isEmpty) throw Exception('kosong');
      _cache = list;
      return MarketResult(list, true);
    } catch (_) {
      return MarketResult(cached, false);
    }
  }

  /// Daftar harga untuk grafik. [days] = rentang hari.
  static Future<List<double>> fetchChart(Coin coin, int days) async {
    try {
      final uri = Uri.parse(
          'https://api.coingecko.com/api/v3/coins/${coin.id}/market_chart?vs_currency=idr&days=$days');
      final r = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final prices = (jsonDecode(r.body)['prices'] as List)
          .map<double>((e) => (e[1] as num).toDouble())
          .toList();
      if (prices.length < 2) throw Exception('data kurang');
      return prices;
    } catch (_) {
      // Grafik contoh (acak tetap per koin) agar tampilan tetap hidup saat offline.
      final rnd = Random(coin.id.hashCode + days);
      var v = coin.price * 0.97;
      return List.generate(48, (i) {
        v += coin.price * (rnd.nextDouble() - 0.46) * 0.01;
        return v;
      });
    }
  }
}
