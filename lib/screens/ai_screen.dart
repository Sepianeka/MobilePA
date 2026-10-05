import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class _Msg {
  final String text;
  final bool user;
  _Msg(this.text, this.user);
}

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _loading = false;
  static const _suggestions = ['Apa itu blockchain?', 'Bedanya Bitcoin dan Ethereum?', 'Cara membaca grafik untuk pemula'];

  @override
  void initState() {
    super.initState();
    final name = AppState.instance.user?.name.split(' ').first ?? '';
    _msgs.add(_Msg(
        'Halo $name! 👋 Saya asisten virtual CoinWise. Mau belajar konsep kripto apa hari ini? Kamu bisa tanya istilah teknis atau pilih topik cepat di bawah.',
        false));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _loading) return;
    _input.clear();
    setState(() {
      _msgs.add(_Msg(q, true));
      _loading = true;
    });
    _toBottom();
    final a = await AiService.ask(q);
    if (!mounted) return;
    setState(() {
      _msgs.add(_Msg(a, false));
      _loading = false;
    });
    _toBottom();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const CircleAvatar(radius: 16, backgroundColor: AppColors.tealSoft, child: Icon(Icons.smart_toy, size: 18, color: AppColors.tealDark)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Asisten CoinWise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(AiService.hasKey ? 'Online • Gemini' : 'Mode contoh (tanpa API key)',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            children: [
              for (final m in _msgs) _bubble(m),
              if (_msgs.length == 1)
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in _suggestions)
                    ActionChip(label: Text(s), onPressed: () => _send(s)),
                ]),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text('Bukan saran investasi', style: TextStyle(fontSize: 11, color: AppColors.hint)),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: _send,
                  decoration: const InputDecoration(hintText: 'Tanya seputar kripto & keuangan...'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => _send(_input.text),
                icon: const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _bubble(_Msg m) => Align(
        alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: m.user ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: m.user ? null : Border.all(color: AppColors.border),
          ),
          child: Text(m.text, style: TextStyle(color: m.user ? Colors.white : AppColors.text, height: 1.4)),
        ),
      );
}
