import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _user = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _hide = true, _agree = false, _loading = false;

  int get _strength {
    final p = _pw.text;
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  @override
  void dispose() {
    for (final c in [_name, _user, _email, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    String? err;
    if (_name.text.trim().isEmpty || _user.text.trim().isEmpty) {
      err = 'Nama dan username wajib diisi';
    } else if (!RegExp(r'^[a-zA-Z0-9_.]{3,}$').hasMatch(_user.text.trim())) {
      err = 'Username minimal 3 karakter (huruf, angka, _ atau .)';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      err = 'Format email tidak valid';
    } else if (_pw.text.length < 8) {
      err = 'Password minimal 8 karakter';
    } else if (_pw.text != _pw2.text) {
      err = 'Konfirmasi password tidak sama';
    } else if (!_agree) {
      err = 'Setujui syarat & ketentuan dulu';
    }
    if (err != null) {
      showSnack(context, err, error: true);
      return;
    }
    setState(() => _loading = true);
    err = await AppState.instance.register(_name.text, _user.text, _email.text, _pw.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      showSnack(context, err, error: true);
      return;
    }
    showSnack(context, 'Akun berhasil dibuat. Silakan masuk.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Lemah', 'Cukup', 'Baik', 'Kuat'];
    final colors = [AppColors.danger, Colors.orange, AppColors.teal, AppColors.success];
    final s = _pw.text.isEmpty ? 0 : _strength + 1;
    Widget field(TextEditingController c, String label, IconData icon, {TextInputType? type}) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextField(
            controller: c,
            keyboardType: type,
            decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Mulai perjalanan literasi keuangan & simulasi kripto tanpa risiko.',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            field(_name, 'Nama Lengkap', Icons.person_outline),
            field(_user, 'Username', Icons.alternate_email),
            field(_email, 'Email', Icons.mail_outline, type: TextInputType.emailAddress),
            TextField(
              controller: _pw,
              obscureText: _hide,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
            ),
            if (_pw.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: s / 4,
                      minHeight: 6,
                      backgroundColor: AppColors.recessed,
                      color: colors[s - 1],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(labels[s - 1], style: TextStyle(fontWeight: FontWeight.w700, color: colors[s - 1])),
              ]),
              const Text('8+ karakter, huruf, angka & simbol', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _pw2,
              obscureText: _hide,
              decoration: const InputDecoration(labelText: 'Konfirmasi Password', prefixIcon: Icon(Icons.lock_reset)),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              title: const Text('Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi CoinWise.',
                  style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Daftar Akun Baru', icon: Icons.arrow_forward, onPressed: _register, loading: _loading),
          ],
        ),
      ),
    );
  }
}
