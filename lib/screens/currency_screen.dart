import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/currency_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});
  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final _amount = TextEditingController(text: '100000');
  late Future<RatesResult> _rates = CurrencyService.fetchRates();

  static const _info = {
    'USD': ('Dollar Amerika Serikat', r'$', 2),
    'EUR': ('Euro Uni Eropa', '€', 2),
    'JPY': ('Yen Jepang', '¥', 0),
    'SGD': ('Dollar Singapura', r'S$', 2),
  };

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amount.text) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Konversi Mata Uang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dari (mata uang dasar)', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('🇮🇩 IDR • Rupiah Indonesia', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Nominal ditukarkan', prefixText: 'Rp '),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final v in [100000, 500000, 1000000, 10000000])
                  ActionChip(label: Text(rupiahShort(v)), onPressed: () => setState(() => _amount.text = '$v')),
              ]),
            ]),
          ),
          const SectionTitle('Hasil Konversi'),
          FutureBuilder<RatesResult>(
            future: _rates,
            builder: (_, snap) {
              if (!snap.hasData) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
              final res = snap.data!;
              return Column(children: [
                for (final code in CurrencyService.symbols)
                  if (res.perIdr.containsKey(code)) _row(code, amount, res.perIdr[code]!),
                const SizedBox(height: 8),
                Text(res.live ? 'Kurs live dari Frankfurter' : 'Kurs contoh (offline / API gagal)',
                    style: const TextStyle(fontSize: 11, color: AppColors.hint)),
              ]);
            },
          ),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.tealSoft.withOpacity(0.5),
            child: const Text('💡 Kurs valas fluktuatif. Cek spread beli-jual sebelum menukar uang saku studi!', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _row(String code, double amount, double rate) {
    final info = _info[code]!;
    final value = amount * rate;
    final f = NumberFormat(info.$3 == 0 ? '#,##0' : '#,##0.00', 'en_US');
    final text = '${info.$2} ${f.format(value)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$code • ${info.$1}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text('1 $code = ${rupiah(1 / rate)}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              showSnack(context, 'Disalin: $text');
            },
          ),
        ]),
      ),
    );
  }
}
