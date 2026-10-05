import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/market_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CoinDetailScreen extends StatefulWidget {
  final Coin coin;
  const CoinDetailScreen({super.key, required this.coin});
  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  final app = AppState.instance;
  static const _labels = ['1J', '1H', '1M', '1B', '1T'];
  static const _days = [1, 1, 7, 30, 365];
  int _tf = 1;
  late Future<List<double>> _chart = _load();

  Future<List<double>> _load() async {
    final data = await MarketService.fetchChart(widget.coin, _days[_tf]);
    if (_tf == 0 && data.length > 12) return data.sublist(data.length - 12); // 1 jam terakhir
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coin;
    final up = c.change >= 0;
    final color = up ? AppColors.success : AppColors.danger;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          ListenableBuilder(
            listenable: app,
            builder: (_, __) => IconButton(
              onPressed: () => app.toggleWatch(c.symbol),
              icon: Icon(app.watchlist.contains(c.symbol) ? Icons.star : Icons.star_border,
                  color: app.watchlist.contains(c.symbol) ? Colors.amber : null),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            CoinAvatar(c.symbol, size: 48),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${c.name} (${c.symbol})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Text('Aset kripto', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 16),
          const Text('Harga Pasar Saat Ini', style: TextStyle(color: AppColors.muted)),
          Text(rupiah(c.price), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(children: [DeltaBadge(c.change), const SizedBox(width: 8), const Text('24 jam terakhir', style: TextStyle(color: AppColors.muted, fontSize: 12))]),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < _labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_labels[i]),
                    selected: _tf == i,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: _tf == i ? Colors.white : AppColors.text, fontWeight: FontWeight.w600),
                    shape: const StadiumBorder(),
                    onSelected: (_) => setState(() {
                      _tf = i;
                      _chart = _load();
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: FutureBuilder<List<double>>(
              future: _chart,
              builder: (_, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final d = snap.data!;
                return LineChart(LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map((s) => LineTooltipItem(rupiahShort(s.y), const TextStyle(color: Colors.white, fontSize: 11)))
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (var i = 0; i < d.length; i++) FlSpot(i.toDouble(), d[i])],
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
                    ),
                  ],
                ));
              },
            ),
          ),
          const SectionTitle('Statistik Pasar'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.1,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _stat(Icons.pie_chart, 'Kapitalisasi Pasar', rupiahShort(c.marketCap)),
              _stat(Icons.bar_chart, 'Volume 24 Jam', rupiahShort(c.volume)),
              _stat(Icons.arrow_upward, 'Tertinggi 24j', rupiahShort(c.high)),
              _stat(Icons.arrow_downward, 'Terendah 24j', rupiahShort(c.low)),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            color: AppColors.tealSoft.withOpacity(0.5),
            child: const Text(
              'Catatan edukasi: harga kripto sangat fluktuatif. Di sini kamu berlatih dengan saldo virtual, tanpa risiko uang sungguhan.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: app,
            builder: (_, __) => AppCard(
              child: Row(children: [
                const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Saldo Simulasi Belajar', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    Text(rupiah(app.balance), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Punya ${(app.holdings[c.symbol] ?? 0).toStringAsFixed(6)} ${c.symbol}',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: PrimaryButton(label: 'Beli (Simulasi)', icon: Icons.shopping_bag, color: AppColors.success, onPressed: () => _sheet(true))),
            const SizedBox(width: 12),
            Expanded(child: PrimaryButton(label: 'Jual (Simulasi)', icon: Icons.sell, color: AppColors.danger, onPressed: () => _sheet(false))),
          ]),
        ],
      ),
    );
  }

  Widget _stat(IconData i, String t, String v) => AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [Icon(i, size: 14, color: AppColors.muted), const SizedBox(width: 4), Text(t, style: const TextStyle(fontSize: 11, color: AppColors.muted))]),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );

  void _sheet(bool buy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TradeSheet(coin: widget.coin, buy: buy),
    );
  }
}

class _TradeSheet extends StatefulWidget {
  final Coin coin;
  final bool buy;
  const _TradeSheet({required this.coin, required this.buy});
  @override
  State<_TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<_TradeSheet> {
  final _amount = TextEditingController();
  bool _loading = false;

  double get _value => double.tryParse(_amount.text) ?? 0;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    // Mining blok bisa memakan waktu singkat; beri UI kesempatan menggambar.
    await Future.delayed(const Duration(milliseconds: 50));
    final err = await AppState.instance.trade(widget.coin, widget.buy, _value);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      showSnack(context, err, error: true);
      return;
    }
    Navigator.pop(context);
    showSnack(context, 'Order simulasi berhasil dieksekusi dan dicatat di blockchain');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final c = widget.coin;
    final qty = c.price == 0 ? 0 : _value / c.price;
    final color = widget.buy ? AppColors.success : AppColors.danger;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${widget.buy ? 'Beli' : 'Jual'} ${c.name} (Simulasi)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
        Text('${c.symbol}/IDR • Pasar spot simulasi', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 12),
        Text(
          widget.buy
              ? 'Saldo virtual: ${rupiah(app.balance)}'
              : 'Aset dimiliki: ${(app.holdings[c.symbol] ?? 0).toStringAsFixed(6)} ${c.symbol}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Nominal (Rp)', prefixText: 'Rp '),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final v in [100000, 500000, 1000000, 5000000])
            ActionChip(
              label: Text(rupiahShort(v)),
              onPressed: () => setState(() => _amount.text = '$v'),
            ),
        ]),
        const SizedBox(height: 8),
        Text('Estimasi: ${qty.toStringAsFixed(6)} ${c.symbol} @ ${rupiah(c.price)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Konfirmasi', color: color, loading: _loading, onPressed: _confirm),
        const SizedBox(height: 8),
        const Center(
          child: Text('Transaksi hanya simulasi edukatif tanpa uang sungguhan',
              style: TextStyle(fontSize: 11, color: AppColors.hint)),
        ),
      ]),
    );
  }
}
