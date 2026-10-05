import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});
  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  void _home() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const MainShell()));

  Future<void> _verify() async {
    if (!await BiometricService.available()) {
      if (mounted) _home(); // perangkat tanpa biometrik: lanjut saja
      return;
    }
    final ok = await BiometricService.authenticate('Sentuh sensor sidik jari untuk membuka CoinWise');
    if (ok && mounted) _home();
  }

  Future<void> _usePassword() async {
    await AppState.instance.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final u = AppState.instance.user;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              AppCard(
                child: Row(children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.tealSoft,
                    child: Icon(Icons.verified_user, color: AppColors.tealDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u?.name ?? 'Pengguna', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('@${u?.username ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(99)),
                    child: const Text('Akun Aktif',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.successText)),
                  ),
                ]),
              ),
              const Spacer(),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tealSoft,
                  boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.35), blurRadius: 36)],
                ),
                child: const Icon(Icons.fingerprint, size: 72, color: AppColors.tealDark),
              ),
              const SizedBox(height: 28),
              const Text('Verifikasi Identitas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Sentuh sensor sidik jari untuk melanjutkan masuk ke portofolio CoinWise',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              const Text('Data biometrik diproses oleh sistem Android dan tidak disimpan aplikasi.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.hint, fontSize: 11)),
              const Spacer(),
              PrimaryButton(label: 'Coba Lagi', icon: Icons.fingerprint, onPressed: _verify),
              TextButton(onPressed: _usePassword, child: const Text('Gunakan password')),
            ],
          ),
        ),
      ),
    );
  }
}
