import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'biometric_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final app = AppState.instance;
    final Widget next = !app.hasSession
        ? const LoginScreen()
        : (app.biometricEnabled ? const BiometricScreen() : const MainShell());
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    Widget pill(IconData i, String t) => Column(
          children: [
            Icon(i, color: AppColors.tealSoft),
            const SizedBox(height: 6),
            Text(t, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        );
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00236F), AppColors.primary, Color(0xFF264191)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.school, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('CoinWise',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8)),
              const SizedBox(height: 8),
              const Text('Belajar keuangan & kripto dengan aman',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  pill(Icons.verified_user, 'Simulasi Riil'),
                  const SizedBox(width: 28),
                  pill(Icons.savings, 'Tanpa Modal'),
                  const SizedBox(width: 28),
                  pill(Icons.military_tech, 'Sertifikat'),
                ],
              ),
              const Spacer(flex: 2),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.teal),
              ),
              const SizedBox(height: 14),
              const Text('Versi 1.0.0 • Terenkripsi & Bebas Risiko',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
