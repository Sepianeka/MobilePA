import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final app = AppState.instance;
  final _kesan = TextEditingController();
  final _saran = TextEditingController();
  int _rating = 5;
  String _cat = 'Materi Finansial';
  static const _cats = ['Materi Finansial', 'Simulator Kripto', 'Tampilan Aplikasi', 'Usulan Fitur Baru'];

  @override
  void dispose() {
    _kesan.dispose();
    _saran.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_kesan.text.trim().isEmpty || _saran.text.trim().isEmpty) {
      showSnack(context, 'Isi kesan dan saran dulu', error: true);
      return;
    }
    await app.addFeedback(_rating, _cat, _kesan.text.trim(), _saran.text.trim());
    _kesan.clear();
    _saran.clear();
    if (mounted) showSnack(context, 'Terima kasih! Aspirasimu berhasil disimpan.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Saran & Kesan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const Text('Mata Kuliah Pemrograman Aplikasi Mobile', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pengalaman Belajarmu', style: TextStyle(fontWeight: FontWeight.w700)),
              Row(children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(i <= _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 30),
                  ),
              ]),
              const SizedBox(height: 4),
              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final c in _cats)
                  ChoiceChip(
                    label: Text(c),
                    selected: _cat == c,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: _cat == c ? Colors.white : AppColors.text, fontSize: 12),
                    onSelected: (_) => setState(() => _cat = c),
                  ),
              ]),
              const SizedBox(height: 14),
              TextField(controller: _kesan, maxLines: 3, decoration: const InputDecoration(labelText: 'Kesan')),
              const SizedBox(height: 12),
              TextField(controller: _saran, maxLines: 3, decoration: const InputDecoration(labelText: 'Saran')),
              const SizedBox(height: 14),
              PrimaryButton(label: 'Kirim Saran & Kesan', icon: Icons.send, onPressed: _send),
            ]),
          ),
          const SectionTitle('Riwayat Masukanmu'),
          ListenableBuilder(
            listenable: app,
            builder: (_, __) {
              if (app.feedbacks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Belum ada masukan', style: TextStyle(color: AppColors.muted))),
                );
              }
              return Column(children: [
                for (final f in app.feedbacks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(f['category'] as String, style: const TextStyle(fontSize: 11, color: AppColors.tealDark, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          for (var i = 0; i < (f['rating'] as int); i++) const Icon(Icons.star, size: 14, color: Colors.amber),
                        ]),
                        const SizedBox(height: 6),
                        Text('Kesan: ${f['kesan']}'),
                        const SizedBox(height: 4),
                        Text('Saran: ${f['saran']}'),
                      ]),
                    ),
                  ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}
