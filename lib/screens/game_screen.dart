import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class Candle {
  final double o, h, l, c;
  const Candle(this.o, this.h, this.l, this.c);
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _totalRounds = 10;
  final _rng = Random();
  List<Candle> _candles = [];
  late bool _nextUp;
  int _round = 1, _score = 0, _streak = 0, _secs = 15;
  bool _revealed = false, _correct = false;
  Timer? _timer;
  StreamSubscription<GyroscopeEvent>? _gyro;

  @override
  void initState() {
    super.initState();
    _newRound();
    // SENSOR 2: Gyroscope. Miringkan HP ke kiri/kanan untuk memilih jawaban.
    _gyro = gyroscopeEventStream().listen((e) {
      if (_revealed) return;
      if (e.y > 2.5) {
        _answer(true);
      } else if (e.y < -2.5) {
        _answer(false);
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gyro?.cancel();
    super.dispose();
  }

  List<Candle> _gen(int n) {
    final list = <Candle>[];
    var price = 100.0;
    for (var i = 0; i < n; i++) {
      final o = price;
      final c = o + (_rng.nextDouble() - 0.5) * 8;
      final h = max(o, c) + _rng.nextDouble() * 3;
      final l = min(o, c) - _rng.nextDouble() * 3;
      list.add(Candle(o, h, l, c));
      price = c;
    }
    return list;
  }

  void _newRound() {
    _timer?.cancel();
    _candles = _gen(9);
    final last = _candles.last;
    // Sedikit kecenderungan berbalik arah supaya pola bisa "dibaca".
    _nextUp = _rng.nextDouble() < (last.c < last.o ? 0.62 : 0.4);
    _secs = 15;
    _revealed = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secs--);
      if (_secs <= 0) _answer(null);
    });
    setState(() {});
  }

  /// [up] null = waktu habis.
  void _answer(bool? up) {
    if (_revealed) return;
    _timer?.cancel();
    final last = _candles.last;
    final d = 1 + _rng.nextDouble() * 5;
    final c = _nextUp ? last.c + d : last.c - d;
    _candles = [..._candles, Candle(last.c, max(last.c, c) + 1, min(last.c, c) - 1, c)];
    _correct = up != null && up == _nextUp;
    if (_correct) {
      _score += 10;
      _streak++;
    } else {
      _streak = 0;
    }
    setState(() => _revealed = true);
  }

  Future<void> _next() async {
    if (_round >= _totalRounds) {
      await AppState.instance.saveScore(_score);
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Permainan Selesai 🎉'),
          content: Text('Skor akhir: $_score dari ${_totalRounds * 10}\nSkor terbaik: ${max(_score, AppState.instance.bestScore)}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _round = 1;
                  _score = 0;
                  _streak = 0;
                });
                _newRound();
              },
              child: const Text('Main Lagi'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _round++);
    _newRound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tebak Tren')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _chip(Icons.stars, 'Skor $_score'),
            const SizedBox(width: 8),
            _chip(Icons.local_fire_department, 'Streak $_streak'),
            const Spacer(),
            _chip(Icons.timer, '${_secs.clamp(0, 15)}s'),
          ]),
          const SizedBox(height: 8),
          Text('Ronde $_round dari $_totalRounds', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          AppCard(
            child: Column(children: [
              const Row(children: [
                CoinAvatar('BTC', size: 32),
                SizedBox(width: 10),
                Text('BTC / IDR • Candlestick dasar', style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CustomPaint(painter: CandlePainter(_candles, _revealed)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('Harga selanjutnya akan naik atau turun?',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Analisis candle sebelumnya dan tentukan prediksimu dalam 15 detik.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 16),
          if (!_revealed)
            Row(children: [
              Expanded(child: PrimaryButton(label: 'Naik (+10)', icon: Icons.arrow_circle_up, color: AppColors.success, onPressed: () => _answer(true))),
              const SizedBox(width: 12),
              Expanded(child: PrimaryButton(label: 'Turun (+10)', icon: Icons.arrow_circle_down, color: AppColors.danger, onPressed: () => _answer(false))),
            ])
          else
            AppCard(
              color: _correct ? AppColors.successBg : AppColors.dangerBg,
              child: Column(children: [
                Text(_correct ? 'Analisis tepat! +10 poin' : 'Belum tepat, harga bergerak ${_nextUp ? 'naik' : 'turun'}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: _correct ? AppColors.successText : AppColors.dangerText)),
                const SizedBox(height: 10),
                PrimaryButton(label: _round >= _totalRounds ? 'Lihat Hasil' : 'Lanjut', onPressed: _next),
              ]),
            ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.screen_rotation, size: 18, color: AppColors.tealDark),
            SizedBox(width: 6),
            Flexible(
              child: Text('Atau miringkan HP ke kiri/kanan untuk memilih (sensor gyroscope)',
                  style: TextStyle(fontSize: 11, color: AppColors.tealDark)),
            ),
          ]),
          const SizedBox(height: 6),
          const Center(
            child: Text('Simulasi edukasi membaca aksi harga tanpa risiko modal riil.',
                style: TextStyle(fontSize: 11, color: AppColors.hint)),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(99)),
        child: Row(children: [
          Icon(i, size: 16, color: AppColors.tealDark),
          const SizedBox(width: 4),
          Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tealDark, fontSize: 12)),
        ]),
      );
}

class CandlePainter extends CustomPainter {
  final List<Candle> candles;
  final bool revealed;
  CandlePainter(this.candles, this.revealed);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    final lo = candles.map((c) => c.l).reduce(min) - 2;
    final hi = candles.map((c) => c.h).reduce(max) + 2;
    final slots = candles.length + (revealed ? 0 : 1);
    final w = size.width / slots;
    double y(double v) => size.height - (v - lo) / (hi - lo) * size.height;

    for (var i = 0; i < candles.length; i++) {
      final c = candles[i];
      final color = c.c >= c.o ? AppColors.success : AppColors.danger;
      final x = w * i + w / 2;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2;
      canvas.drawLine(Offset(x, y(c.h)), Offset(x, y(c.l)), paint);
      final top = y(max(c.o, c.c)), bottom = y(min(c.o, c.c));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - w * 0.3, top, x + w * 0.3, max(bottom, top + 2)),
          const Radius.circular(2),
        ),
        paint,
      );
    }
    if (!revealed) {
      final x = w * candles.length + w / 2;
      final r = Rect.fromLTRB(x - w * 0.35, 8, x + w * 0.35, size.height - 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()
          ..color = AppColors.hint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      final tp = TextPainter(
        text: const TextSpan(text: '?', style: TextStyle(fontSize: 24, color: AppColors.muted, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height / 2 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CandlePainter old) => true;
}
