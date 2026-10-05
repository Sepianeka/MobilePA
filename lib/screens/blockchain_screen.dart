import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class BlockchainScreen extends StatelessWidget {
  const BlockchainScreen({super.key});

  String _short(String h) => '0x${h.substring(0, 8)}...${h.substring(h.length - 5)}';

  String _title(String data) {
    try {
      final d = jsonDecode(data) as Map<String, dynamic>;
      return '${d['type'] == 'buy' ? 'Beli' : 'Jual'} ${(d['qty'] as num).toStringAsFixed(4)} ${d['symbol']}';
    } catch (_) {
      return data;
    }
  }

  String _amount(String data) {
    try {
      final d = jsonDecode(data) as Map<String, dynamic>;
      return 'Nominal: ${rupiah(d['rupiah'] as num)}';
    } catch (_) {
      return 'Blok awal rantai';
    }
  }

  String _time(int ms) {
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Blockchain')),
      body: ListenableBuilder(
        listenable: app,
        builder: (_, __) {
          final valid = app.validity();
          final allOk = valid.every((v) => v);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ledger Simulasi Terbuka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text(
                    'Setiap transaksi simulasi disegel dalam blok. Blok saling terkunci lewat hash, jadi mengubah satu data akan merusak seluruh rantai setelahnya.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(allOk ? Icons.verified_user : Icons.gpp_bad, color: allOk ? AppColors.success : AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(allOk ? 'Rantai valid • ${app.chain.length} blok' : 'Rantai TIDAK valid: ada blok yang diubah',
                          style: TextStyle(fontWeight: FontWeight.w700, color: allOk ? AppColors.successText : AppColors.dangerText)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Verifikasi Integritas Rantai',
                    icon: Icons.fact_check,
                    onPressed: () => showSnack(context, app.chainValid ? 'Semua blok valid' : 'Ditemukan blok yang tidak valid', error: !app.chainValid),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: app.chain.length < 2 ? null : app.tamperChain,
                        child: const Text('Uji manipulasi', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: app.tampered ? app.restoreChain : null,
                        child: const Text('Pulihkan', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ]),
                ]),
              ),
              const SectionTitle('Rantai Blok (terbaru ke awal)'),
              for (var i = app.chain.length - 1; i >= 0; i--)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('Blok #${app.chain[i].index}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: valid[i] ? AppColors.successBg : AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(valid[i] ? 'Valid' : 'Tidak valid',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: valid[i] ? AppColors.successText : AppColors.dangerText)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(_time(app.chain[i].timestamp), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(_title(app.chain[i].data), style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(_amount(app.chain[i].data), style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: Text('Hash: ${_short(app.chain[i].hash)}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: app.chain[i].hash));
                            showSnack(context, 'Hash disalin');
                          },
                          child: const Icon(Icons.copy, size: 16, color: AppColors.muted),
                        ),
                      ]),
                      Text('Prev: ${_short(app.chain[i].prevHash)}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.muted)),
                      Text('Nonce: ${app.chain[i].nonce}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.muted)),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
