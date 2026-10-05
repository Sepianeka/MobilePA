import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'blockchain.dart';

class AppUser {
  final String name, username, email;
  const AppUser(this.name, this.username, this.email);
}

/// State aplikasi + penyimpanan SEMENTARA di SharedPreferences.
///
/// TODO (tahap database): pindahkan penyimpanan di bawah ini ke SQLite
/// (sqflite) dan sinkronkan ke database online. Fungsi-fungsi publik
/// (register, login, trade, dll.) cukup dipertahankan, hanya isinya diganti.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const double initialBalance = 100000000;

  late SharedPreferences _p;
  AppUser? user;
  double balance = initialBalance;
  Map<String, double> holdings = {};
  Set<String> watchlist = {};
  List<Block> chain = [];
  int bestScore = 0;
  bool biometricEnabled = false;
  List<Map<String, dynamic>> feedbacks = [];
  bool tampered = false;

  bool get hasSession => user != null;
  String? get lastUser => _p.getString('last_user');

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final s = _p.getString('session');
    if (s != null && _users().containsKey(s)) _load(s);
  }

  // ---------- Akun & keamanan ----------
  Map<String, dynamic> _users() {
    final raw = _p.getString('users');
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw));
  }

  String _salt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  /// Hash password = SHA-256 diulang 5000x dengan salt acak per pengguna.
  String _hash(String salt, String pw) {
    final d = utf8.encode('$salt$pw');
    var h = sha256.convert(d);
    for (var i = 0; i < 5000; i++) {
      h = sha256.convert([...h.bytes, ...d]);
    }
    return h.toString();
  }

  /// Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> register(String name, String username, String email, String pw) async {
    final users = _users();
    final u = username.trim().toLowerCase();
    final e = email.trim().toLowerCase();
    if (users.containsKey(u)) return 'Username sudah dipakai';
    if (users.values.any((v) => (v['email'] as String) == e)) {
      return 'Email sudah terdaftar';
    }
    final salt = _salt();
    users[u] = {
      'name': name.trim(),
      'email': e,
      'salt': salt,
      'hash': _hash(salt, pw),
    };
    await _p.setString('users', jsonEncode(users));
    return null;
  }

  Future<String?> login(String id, String pw) async {
    final key = id.trim().toLowerCase();
    final users = _users();
    String? uname;
    users.forEach((k, v) {
      if (k == key || (v['email'] as String) == key) uname = k;
    });
    if (uname == null) return 'Akun tidak ditemukan';
    final rec = users[uname] as Map<String, dynamic>;
    if (_hash(rec['salt'] as String, pw) != rec['hash']) return 'Password salah';
    await _startSession(uname!);
    return null;
  }

  Future<void> _startSession(String u) async {
    _load(u);
    await _p.setString('session', u);
    await _p.setString('last_user', u);
    notifyListeners();
  }

  bool biometricEnabledFor(String username) {
    final raw = _p.getString('data_$username');
    if (raw == null) return false;
    return (jsonDecode(raw) as Map)['bio'] == true;
  }

  /// Dipanggil setelah sidik jari berhasil diverifikasi di layar login.
  Future<bool> loginWithBiometricSession() async {
    final u = lastUser;
    if (u == null || !_users().containsKey(u) || !biometricEnabledFor(u)) return false;
    await _startSession(u);
    return true;
  }

  Future<void> logout() async {
    await _p.remove('session');
    user = null;
    notifyListeners();
  }

  // ---------- Muat & simpan data per pengguna ----------
  void _load(String username) {
    final u = _users()[username] as Map<String, dynamic>;
    user = AppUser(u['name'] as String, username, u['email'] as String);
    final raw = _p.getString('data_$username');
    final d = raw == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(raw));
    balance = ((d['balance'] ?? initialBalance) as num).toDouble();
    holdings = ((d['holdings'] as Map?) ?? {})
        .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    watchlist = ((d['watchlist'] as List?) ?? ['BTC', 'ETH', 'SOL']).cast<String>().toSet();
    chain = ((d['chain'] as List?) ?? [])
        .map((e) => Block.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (chain.isEmpty) chain = [Block.genesis()];
    bestScore = (d['best'] ?? 0) as int;
    biometricEnabled = d['bio'] == true;
    feedbacks = ((d['feedbacks'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    tampered = false;
  }

  Future<void> _save() async {
    if (user == null) return;
    await _p.setString(
      'data_${user!.username}',
      jsonEncode({
        'balance': balance,
        'holdings': holdings,
        'watchlist': watchlist.toList(),
        'chain': chain.map((b) => b.toJson()).toList(),
        'best': bestScore,
        'bio': biometricEnabled,
        'feedbacks': feedbacks,
      }),
    );
  }

  // ---------- Fitur ----------
  double totalValue(List<Coin> coins) {
    var total = balance;
    holdings.forEach((sym, qty) {
      final c = coins.where((c) => c.symbol == sym);
      if (c.isNotEmpty) total += qty * c.first.price;
    });
    return total;
  }

  Future<void> toggleWatch(String symbol) async {
    watchlist.contains(symbol) ? watchlist.remove(symbol) : watchlist.add(symbol);
    await _save();
    notifyListeners();
  }

  Future<String?> trade(Coin c, bool buy, double rupiah) async {
    if (rupiah <= 0) return 'Masukkan nominal lebih dari 0';
    if (tampered) _load(user!.username); // pulihkan rantai sebelum transaksi baru
    final qty = rupiah / c.price;
    if (buy) {
      if (rupiah > balance) return 'Saldo virtual tidak cukup';
      balance -= rupiah;
      holdings[c.symbol] = (holdings[c.symbol] ?? 0) + qty;
    } else {
      final have = holdings[c.symbol] ?? 0;
      if (qty > have + 1e-12) return 'Aset ${c.symbol} tidak cukup';
      balance += rupiah;
      holdings[c.symbol] = have - qty;
    }
    chain.add(Block.mine(
      index: chain.length,
      data: jsonEncode({'type': buy ? 'buy' : 'sell', 'symbol': c.symbol, 'qty': qty, 'rupiah': rupiah}),
      prevHash: chain.last.hash,
    ));
    await _save();
    notifyListeners();
    return null;
  }

  Future<void> resetBalance() async {
    balance = initialBalance;
    holdings = {};
    await _save();
    notifyListeners();
  }

  Future<void> setBiometric(bool v) async {
    biometricEnabled = v;
    await _save();
    notifyListeners();
  }

  Future<void> saveScore(int score) async {
    if (score > bestScore) {
      bestScore = score;
      await _save();
      notifyListeners();
    }
  }

  Future<void> addFeedback(int rating, String category, String kesan, String saran) async {
    feedbacks.insert(0, {
      'rating': rating,
      'category': category,
      'kesan': kesan,
      'saran': saran,
      'time': DateTime.now().millisecondsSinceEpoch,
    });
    await _save();
    notifyListeners();
  }

  // ---------- Blockchain ----------
  List<bool> validity() {
    final res = <bool>[];
    for (var i = 0; i < chain.length; i++) {
      final b = chain[i];
      var ok = b.hash == b.computeHash();
      if (i > 0 && b.prevHash != chain[i - 1].hash) ok = false;
      if (res.isNotEmpty && !res.last) ok = false; // blok setelah blok rusak ikut tidak valid
      res.add(ok);
    }
    return res;
  }

  bool get chainValid => validity().every((v) => v);

  /// Untuk demo/pengujian: ubah data satu blok TANPA menghitung ulang hash.
  void tamperChain() {
    if (chain.length < 2) return;
    chain[1].data = chain[1].data.replaceFirst('"rupiah":', '"rupiah":9');
    tampered = true;
    notifyListeners();
  }

  void restoreChain() {
    if (user == null) return;
    _load(user!.username);
    notifyListeners();
  }
}
