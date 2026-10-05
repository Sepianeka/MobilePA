import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'ai_screen.dart';
import 'coin_detail_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final app = AppState.instance;
  late Future<MarketResult> _future = MarketService.fetchCoins();
  String _query = '';
  StreamSubscription<AccelerometerEvent>? _acc;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    // SENSOR 1: Accelerometer. Goyang HP untuk memperbarui harga.
    _acc = accelerometerEventStream().listen((e) {
      final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (g > 25 && DateTime.now().difference(_lastShake).inSeconds > 2) {
        _lastShake = DateTime.now();
        _refresh(shake: true);
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _acc?.cancel();
    super.dispose();
  }

  void _refresh({bool shake = false}) {
    setState(() => _future = MarketService.fetchCoins());
    if (shake && mounted) showSnack(context, 'HP digoyang: harga diperbarui');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(children: [
              const Icon(Icons.school, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('CoinWise', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
              IconButton(
                onPressed: () => showSnack(context, 'Notifikasi harga akan ditambahkan di tahap berikutnya'),
                icon: const Icon(Icons.notifications_none),
              ),
            ]),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: app,
              builder: (_, __) => Text('Halo, ${app.user?.name ?? ''}! 👋',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            const Text('Siap menambah literasi finansial hari ini?', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            FutureBuilder<MarketResult>(
              future: _future,
              builder: (context, snap) {
                final coins = snap.data?.coins ?? MarketService.cached;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _balanceCard(coins),
                  const SizedBox(height: 16),
                  _quickActions(coins),
                  _learningCard(),
                  SectionTitle('Harga Pasar & Kripto',
                      trailing: snap.connectionState == ConnectionState.waiting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(snap.data?.live == true ? '● Live' : '○ Data contoh',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: snap.data?.live == true ? AppColors.success : AppColors.muted))),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Cari aset kripto...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _watchlistRow(coins),
                  _coinList(coins),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text('Goyang HP untuk memperbarui harga',
                        style: TextStyle(fontSize: 11, color: AppColors.hint)),
                  ),
                  _missionCard(),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(List<Coin> coins) {
    return ListenableBuilder(
      listenable: app,
      builder: (_, __) {
        final total = app.totalValue(coins);
        final pl = total - AppState.initialBalance;
        final pct = pl / AppState.initialBalance * 100;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFF00236F), AppColors.primary]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Portofolio Simulasi Belajar', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(rupiah(total),
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Row(children: [
              DeltaBadge(pct),
              const SizedBox(width: 8),
              Text('(${pl >= 0 ? '+' : ''}${rupiah(pl)})', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            const Text('Uang simulasi edukasi (bukan uang riil)',
                style: TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        );
      },
    );
  }

  Widget _quickActions(List<Coin> coins) {
    Widget item(IconData i, String t, VoidCallback f) => Expanded(
          child: GestureDetector(
            onTap: f,
            child: Column(children: [
              IconBubble(i),
              const SizedBox(height: 6),
              Text(t, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    return Row(children: [
      item(Icons.query_stats, 'Simulasi\nInvestasi', () => open(CoinDetailScreen(coin: coins.first))),
      item(Icons.receipt_long, 'Catat\nPengeluaran', () => showSnack(context, 'Fitur ini menyusul')),
      item(Icons.psychology_alt, 'Kuis\nFinansial', () => open(const GameScreen())),
      item(Icons.smart_toy, 'Tanya\nAI', () => open(const AiScreen())),
    ]);
  }

  Widget _learningCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Text('Lanjutkan Belajar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(99)),
              child: const Text('⭐ 150 Poin XP', style: TextStyle(fontSize: 11, color: AppColors.tealDark, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          const Text('Dasar Manajemen Uang Saku • Modul 3/8', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(value: 0.65, minHeight: 8, color: AppColors.teal, backgroundColor: AppColors.recessed),
          ),
          const SizedBox(height: 4),
          const Text('65% selesai', style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      ),
    );
  }

  Widget _watchlistRow(List<Coin> coins) {
    return ListenableBuilder(
      listenable: app,
      builder: (_, __) {
        final w = coins.where((c) => app.watchlist.contains(c.symbol)).toList();
        if (w.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Watchlist Saya', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: w.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 150,
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => CoinDetailScreen(coin: w[i]))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w[i].symbol, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(rupiahShort(w[i].price), style: const TextStyle(fontSize: 12)),
                    DeltaBadge(w[i].change),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ]);
      },
    );
  }

  Widget _coinList(List<Coin> coins) {
    final q = _query.trim().toLowerCase();
    final list = coins.where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.symbol.toLowerCase().contains(q)).toList();
    if (list.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Koin tidak ditemukan')));
    }
    return ListenableBuilder(
      listenable: app,
      builder: (_, __) => Column(
        children: [
          for (final c in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CoinDetailScreen(coin: c))),
                child: Row(children: [
                  CoinAvatar(c.symbol),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(c.symbol, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(rupiah(c.price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    DeltaBadge(c.change),
                  ]),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => app.toggleWatch(c.symbol),
                    icon: Icon(
                      app.watchlist.contains(c.symbol) ? Icons.star : Icons.star_border,
                      color: app.watchlist.contains(c.symbol) ? Colors.amber : AppColors.hint,
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _missionCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppCard(
        color: AppColors.tealSoft.withOpacity(0.5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Misi Mingguan • +300 Poin', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Tantangan 7 Hari: Masak Sendiri', style: TextStyle(fontWeight: FontWeight.w600)),
          Text('Hemat Rp 100rb dari makan di luar minggu ini', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          SizedBox(height: 8),
          Text('4 dari 7 hari berhasil', style: TextStyle(fontSize: 11, color: AppColors.tealDark)),
        ]),
      ),
    );
  }
}
