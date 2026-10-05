import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class TimeScreen extends StatefulWidget {
  const TimeScreen({super.key});
  @override
  State<TimeScreen> createState() => _TimeScreenState();
}

class _TimeScreenState extends State<TimeScreen> {
  // Jam acuan selalu dianggap WIB (UTC+7).
  late TimeOfDay _wib = _nowWib();

  static TimeOfDay _nowWib() {
    final t = DateTime.now().toUtc().add(const Duration(hours: 7));
    return TimeOfDay(hour: t.hour, minute: t.minute);
  }

  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  DateTime _lastSunday(int y, int m) {
    var d = DateTime.utc(y, m + 1, 0, 1); // hari terakhir bulan m, pukul 01:00 UTC
    while (d.weekday != DateTime.sunday) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  /// London memakai BST (UTC+1) dari Minggu terakhir Maret sampai Minggu terakhir Oktober.
  bool _isBst(DateTime utc) {
    final s = _lastSunday(utc.year, 3), e = _lastSunday(utc.year, 10);
    return !utc.isBefore(s) && utc.isBefore(e);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final baseUtc = DateTime.utc(nowWib.year, nowWib.month, nowWib.day, _wib.hour, _wib.minute)
        .subtract(const Duration(hours: 7));
    final bst = _isBst(baseUtc);
    final zones = <(String, String, int)>[
      ('WIB', 'Jakarta / Surabaya', 7),
      ('WITA', 'Bali / Makassar', 8),
      ('WIT', 'Jayapura / Maluku', 9),
      (bst ? 'London (BST)' : 'London (GMT)', 'Inggris', bst ? 1 : 0),
    ];

    String dayLabel(DateTime local) {
      final a = DateTime.utc(local.year, local.month, local.day);
      final b = DateTime.utc(nowWib.year, nowWib.month, nowWib.day);
      final diff = a.difference(b).inDays;
      final tag = diff == 0 ? 'Hari ini' : (diff > 0 ? 'Besok' : 'Kemarin');
      return '$tag, ${_days[local.weekday - 1]} ${local.day} ${_months[local.month - 1]}';
    }

    void preset(int h, int m) => setState(() => _wib = TimeOfDay(hour: h, minute: m));

    return Scaffold(
      appBar: AppBar(title: const Text('Konversi Waktu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Waktu acuan (WIB, UTC+7)', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                Text('${_two(_wib.hour)}:${_two(_wib.minute)}',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary, shape: const StadiumBorder()),
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _wib,
                      builder: (c, w) => MediaQuery(
                        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
                        child: w!,
                      ),
                    );
                    if (t != null) setState(() => _wib = t);
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Ubah jam'),
                ),
              ]),
              const SizedBox(height: 10),
              const Text('Preset waktu buka pasar:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                ActionChip(label: const Text('⚡ Sekarang'), onPressed: () => setState(() => _wib = _nowWib())),
                ActionChip(label: const Text('🇺🇸 Wall St (20:30)'), onPressed: () => preset(20, 30)),
                ActionChip(label: const Text('🇬🇧 London (14:00)'), onPressed: () => preset(14, 0)),
                ActionChip(label: const Text('🇯🇵 Tokyo (07:00)'), onPressed: () => preset(7, 0)),
              ]),
            ]),
          ),
          const SectionTitle('Daftar Zona Waktu'),
          for (final z in zones)
            Builder(builder: (_) {
              final local = baseUtc.add(Duration(hours: z.$3));
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(z.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('${z.$2} • UTC${z.$3 >= 0 ? '+' : ''}${z.$3}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(dayLabel(local), style: const TextStyle(fontSize: 12)),
                      ]),
                    ),
                    Text('${_two(local.hour)}:${_two(local.minute)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  ]),
                ),
              );
            }),
          const Text('Pasar kripto buka 24/7. Konversi ini membantu memantau jam buka bursa dunia.',
              style: TextStyle(fontSize: 11, color: AppColors.hint)),
        ],
      ),
    );
  }
}
