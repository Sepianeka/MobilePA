class Coin {
  final String id, symbol, name;
  final double price, change, marketCap, volume, high, low;
  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    this.marketCap = 0,
    this.volume = 0,
    this.high = 0,
    this.low = 0,
  });

  factory Coin.fromJson(Map<String, dynamic> j) => Coin(
        id: j['id'] as String,
        symbol: (j['symbol'] as String).toUpperCase(),
        name: j['name'] as String,
        price: (j['current_price'] as num).toDouble(),
        change: ((j['price_change_percentage_24h'] ?? 0) as num).toDouble(),
        marketCap: ((j['market_cap'] ?? 0) as num).toDouble(),
        volume: ((j['total_volume'] ?? 0) as num).toDouble(),
        high: ((j['high_24h'] ?? 0) as num).toDouble(),
        low: ((j['low_24h'] ?? 0) as num).toDouble(),
      );
}

/// Data cadangan saat offline atau kena batas API.
class MockData {
  static const coins = <Coin>[
    Coin(id: 'bitcoin', symbol: 'BTC', name: 'Bitcoin', price: 1045200000, change: 2.4, marketCap: 2.065e16, volume: 4.128e14, high: 1062000000, low: 1018400000),
    Coin(id: 'ethereum', symbol: 'ETH', name: 'Ethereum', price: 54800000, change: -1.2, marketCap: 6.6e15, volume: 2.1e14, high: 55900000, low: 53800000),
    Coin(id: 'solana', symbol: 'SOL', name: 'Solana', price: 2350000, change: 6.7, marketCap: 1.1e15, volume: 5.2e13, high: 2400000, low: 2180000),
    Coin(id: 'binancecoin', symbol: 'BNB', name: 'BNB', price: 9800000, change: 0.9, marketCap: 1.4e15, volume: 4.0e13, high: 9900000, low: 9650000),
    Coin(id: 'ripple', symbol: 'XRP', name: 'XRP', price: 38000, change: -0.4, marketCap: 2.2e15, volume: 6.0e13, high: 38500, low: 37400),
    Coin(id: 'dogecoin', symbol: 'DOGE', name: 'Dogecoin', price: 2600, change: 3.1, marketCap: 3.8e14, volume: 2.5e13, high: 2650, low: 2480),
  ];

  /// Kurs per 1 IDR (perkiraan, hanya cadangan).
  static const rates = <String, double>{
    'USD': 0.0000613,
    'EUR': 0.0000563,
    'JPY': 0.00952,
    'SGD': 0.0000820,
  };
}
