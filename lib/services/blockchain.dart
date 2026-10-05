import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Blockchain sederhana: tiap blok menyimpan hash blok sebelumnya.
class Block {
  final int index;
  String data; // tidak final supaya bisa disimulasikan "dimanipulasi" untuk uji
  final int timestamp;
  final String prevHash;
  final int nonce;
  final String hash;

  Block({
    required this.index,
    required this.data,
    required this.timestamp,
    required this.prevHash,
    required this.nonce,
    required this.hash,
  });

  static String _h(int i, String d, int t, String p, int n) =>
      sha256.convert(utf8.encode('$i|$d|$t|$p|$n')).toString();

  String computeHash() => _h(index, data, timestamp, prevHash, nonce);

  /// "Mining" sederhana: cari nonce sampai hash diawali "00".
  static Block mine({
    required int index,
    required String data,
    required String prevHash,
  }) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    var n = 0;
    while (true) {
      final h = _h(index, data, ts, prevHash, n);
      if (h.startsWith('00')) {
        return Block(index: index, data: data, timestamp: ts, prevHash: prevHash, nonce: n, hash: h);
      }
      n++;
    }
  }

  static Block genesis() =>
      mine(index: 0, data: 'Genesis', prevHash: '0' * 64);

  Map<String, dynamic> toJson() => {
        'index': index,
        'data': data,
        'timestamp': timestamp,
        'prevHash': prevHash,
        'nonce': nonce,
        'hash': hash,
      };

  factory Block.fromJson(Map<String, dynamic> j) => Block(
        index: j['index'] as int,
        data: j['data'] as String,
        timestamp: j['timestamp'] as int,
        prevHash: j['prevHash'] as String,
        nonce: j['nonce'] as int,
        hash: j['hash'] as String,
      );
}
