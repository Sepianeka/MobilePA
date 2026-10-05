import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'blockchain_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _toggleBio(BuildContext context, bool v) async {
    final app = AppState.instance;
    if (v) {
      if (!await BiometricService.available()) {
        if (context.mounted) showSnack(context, 'Biometrik tidak tersedia / belum didaftarkan di HP', error: true);
        return;
      }
      final ok = await BiometricService.authenticate('Verifikasi untuk mengaktifkan login biometrik');
      if (!ok) return;
    }
    await app.setBiometric(v);
  }

  String _lastTx(AppState app) {
    if (app.chain.length < 2) return 'Belum ada transaksi';
    final b = app.chain.last;
    final d = jsonDecode(b.data) as Map<String, dynamic>;
    return '${d['type'] == 'buy' ? 'Beli' : 'Jual'} ${(d['qty'] as num).toStringAsFixed(4)} ${d['symbol']} • Blok #${b.index}';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: app,
        builder: (_, __) {
          final pl = app.balance - AppState.initialBalance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Center(
                child: Stack(children: [
                  const CircleAvatar(radius: 52, backgroundImage: AssetImage('assets/images/profile.png')),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => showSnack(context, 'Ganti foto: ditambahkan di tahap berikutnya'),
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.photo_camera, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Center(child: Text(app.user?.name ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              Center(child: Text('@${app.user?.username ?? ''} • ${app.user?.email ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12))),
              const SizedBox(height: 16),
              Row(children: [
                _stat('Skor Game', '${app.bestScore}'),
                const SizedBox(width: 10),
                _stat('Transaksi', '${app.chain.length - 1}'),
                const SizedBox(width: 10),
                _stat('Watchlist', '${app.watchlist.length}'),
              ]),
              const SizedBox(height: 16),
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Saldo Virtual', style: TextStyle(color: AppColors.muted)),
                  Text(rupiah(app.balance), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  Text('Modal awal ${rupiah(AppState.initialBalance)} • selisih kas ${pl >= 0 ? '+' : ''}${rupiah(pl)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    app.holdings.entries.where((e) => e.value > 0).map((e) => '${e.key} ${e.value.toStringAsFixed(4)}').join('  •  ').ifEmpty('Belum punya aset'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final yes = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Reset saldo?'),
                            content: const Text('Saldo kembali ke modal awal dan semua aset simulasi dihapus. Riwayat blockchain tetap ada.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
                            ],
                          ),
                        );
                        if (yes == true) await app.resetBalance();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset'),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const IconBubble(Icons.fingerprint),
                  title: const Text('Pengaturan Biometrik', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Masuk dengan sidik jari / Face ID', style: TextStyle(fontSize: 12)),
                  value: app.biometricEnabled,
                  activeColor: AppColors.teal,
                  onChanged: (v) => _toggleBio(context, v),
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockchainScreen())),
                child: Row(children: [
                  const IconBubble(Icons.token),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Riwayat Transaksi (Blockchain)', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(_lastTx(app), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.hint),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String t, String v) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
            Text(t, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
      );
}

extension _Empty on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
