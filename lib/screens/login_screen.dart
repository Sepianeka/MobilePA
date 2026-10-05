import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _hide = true, _loading = false;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _toHome() => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const MainShell()));

  Future<void> _login() async {
    if (_id.text.trim().isEmpty || _pw.text.isEmpty) {
      showSnack(context, 'Isi username/email dan password', error: true);
      return;
    }
    setState(() => _loading = true);
    final err = await AppState.instance.login(_id.text, _pw.text);
    if (!mounted) return;
    setState(() => _loading = false);
    err == null ? _toHome() : showSnack(context, err, error: true);
  }

  Future<void> _biometric() async {
    final app = AppState.instance;
    if (!await BiometricService.available()) {
      if (mounted) showSnack(context, 'Biometrik tidak tersedia di perangkat ini', error: true);
      return;
    }
    final u = app.lastUser;
    if (u == null || !app.biometricEnabledFor(u)) {
      if (mounted) {
        showSnack(context, 'Masuk dengan password dulu, lalu aktifkan biometrik di menu Profil', error: true);
      }
      return;
    }
    final ok = await BiometricService.authenticate('Verifikasi sidik jari untuk masuk ke CoinWise');
    if (!ok || !mounted) return;
    if (await app.loginWithBiometricSession()) _toHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.school, color: AppColors.primary),
                SizedBox(width: 8),
                Text('CoinWise', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Masuk', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Selamat datang kembali! Yuk lanjut asah literasi finansialmu hari ini.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 24),
            TextField(
              controller: _id,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Username atau Email',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _pw,
              obscureText: _hide,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Masuk', icon: Icons.arrow_forward, onPressed: _login, loading: _loading),
            const SizedBox(height: 22),
            Row(children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('atau masuk lebih cepat', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),
            OutlineTealButton(label: 'Masuk dengan Biometrik', icon: Icons.fingerprint, onPressed: _biometric),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum punya akun? ', style: TextStyle(color: AppColors.muted)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Daftar Sekarang',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('Password disimpan sebagai hash + salt, bukan teks asli',
                  style: TextStyle(color: AppColors.hint, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
