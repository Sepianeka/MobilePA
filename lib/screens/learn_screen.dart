import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'ai_screen.dart';
import 'currency_screen.dart';
import 'game_screen.dart';
import 'money_changer_screen.dart';
import 'time_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _allowance = TextEditingController(text: '2000000');
  int _dcaYears = 1;
  static const _dcaWeekly = 50000;

  @override
  void dispose() {
    _allowance.dispose();
    super.dispose();
  }

  void _open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final allowance = double.tryParse(_allowance.text) ?? 0;
    // Simulasi DCA: asumsi imbal hasil 10%/tahun, setoran mingguan.
    final weeks = _dcaYears * 52;
    const r = 0.10 / 52;
    final invested = weeks * _dcaWeekly.toDouble();
    final fv = _dcaWeekly * ((pow(1 + r, weeks) - 1) / r);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('Akademi CoinWise', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const Text('Kuasai cara atur uang jajan dan simulasi kripto tanpa rugi.', style: TextStyle(color: AppColors.muted)),
          const SectionTitle('Fitur Belajar'),
          _tile(Icons.psychology_alt, 'Mini Game: Tebak Tren', 'Tebak naik/turun, miringkan HP untuk memilih', () => _open(const GameScreen())),
          _tile(Icons.smart_toy, 'Tanya AI', 'Asisten edukasi kripto & keuangan', () => _open(const AiScreen())),
          const SectionTitle('Alat'),
          _tile(Icons.currency_exchange, 'Konversi Mata Uang', 'IDR ke USD, EUR, JPY, SGD', () => _open(const CurrencyScreen())),
          _tile(Icons.schedule, 'Konversi Waktu', 'WIB, WITA, WIT, London', () => _open(const TimeScreen())),
          _tile(Icons.location_on, 'Money Changer Terdekat', 'Peta dan jarak lokasi', () => _open(const MoneyChangerScreen())),
          const SectionTitle('Kalkulator Pintar'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Metode 50/30/20 Pelajar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Masukkan uang saku bulanan, alokasi ideal terhitung otomatis.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: _allowance,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Uang saku bulanan', prefixText: 'Rp '),
              ),
              const SizedBox(height: 12),
              _alloc('Kebutuhan', '50%', allowance * 0.5, 'Makan, kos, transport', AppColors.primary),
              _alloc('Keinginan', '30%', allowance * 0.3, 'Kopi, jajan, hobi', AppColors.teal),
              _alloc('Tabungan', '20%', allowance * 0.2, 'Darurat & investasi', AppColors.success),
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Simulator DCA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Nabung rutin ${rupiah(_dcaWeekly)}/minggu (asumsi imbal hasil 10%/tahun, hanya simulasi).',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final y in [1, 2, 3])
                  ChoiceChip(
                    label: Text('$y Tahun'),
                    selected: _dcaYears == y,
                    onSelected: (_) => setState(() => _dcaYears = y),
                  ),
              ]),
              const SizedBox(height: 12),
              Text(rupiah(fv), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
              Text('Modal disetor: ${rupiah(invested)} (+${((fv - invested) / invested * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData i, String t, String s, VoidCallback f) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppCard(
          onTap: f,
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            IconBubble(i),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(s, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.hint),
          ]),
        ),
      );

  Widget _alloc(String t, String pct, double v, String sub, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(width: 6, height: 38, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$t • $pct', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ]),
          ),
          Text(rupiah(v), style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}
