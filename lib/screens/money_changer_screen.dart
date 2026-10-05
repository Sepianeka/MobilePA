import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class _Place {
  final String name, address, hours;
  final double dLat, dLng, rating;
  final String usd;
  const _Place(this.name, this.address, this.hours, this.rating, this.usd, this.dLat, this.dLng);
}

class MoneyChangerScreen extends StatefulWidget {
  const MoneyChangerScreen({super.key});
  @override
  State<MoneyChangerScreen> createState() => _MoneyChangerScreenState();
}

class _MoneyChangerScreenState extends State<MoneyChangerScreen> {
  // Titik awal bila GPS ditolak: Plaza Senayan, Jakarta.
  LatLng _center = const LatLng(-6.2255, 106.8018);
  bool _gps = false;

  // DATA CONTOH. Letaknya dihitung relatif terhadap posisi pengguna
  // supaya demo selalu muncul di dekatmu. Bisa diganti data asli (OSM Overpass API / database).
  static const _places = [
    _Place('Dua Sisi Money Changer', 'Pusat perbelanjaan terdekat', 'Buka • Tutup 21.00', 4.8, 'Rp 16.310', 0.004, 0.003),
    _Place('VIP Money Changer', 'Jl. Raya Utama No. 23', 'Buka • Tutup 19.30', 4.9, 'Rp 16.300', -0.008, 0.006),
    _Place('BMP Money Changer', 'Area Mall, Lantai 1', 'Buka • Tutup 20.00', 4.6, 'Rp 16.320', 0.011, -0.009),
    _Place('Sinar Valas', 'Dekat stasiun', 'Buka • Tutup 18.00', 4.5, 'Rp 16.295', -0.014, -0.012),
  ];

  @override
  void initState() {
    super.initState();
    _locate();
  }

  Future<void> _locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _gps = true;
      });
    } catch (_) {}
  }

  LatLng _pos(_Place p) => LatLng(_center.latitude + p.dLat, _center.longitude + p.dLng);

  double _dist(_Place p) {
    final q = _pos(p);
    return Geolocator.distanceBetween(_center.latitude, _center.longitude, q.latitude, q.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final list = [..._places]..sort((a, b) => _dist(a).compareTo(_dist(b)));
    return Scaffold(
      appBar: AppBar(title: const Text('Money Changer Terdekat')),
      body: Column(children: [
        Expanded(
          flex: 5,
          child: FlutterMap(
            key: ValueKey('${_center.latitude}_${_center.longitude}'),
            options: MapOptions(initialCenter: _center, initialZoom: 14.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.coinwise',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _center,
                  width: 28,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
                for (final p in list)
                  Marker(
                    point: _pos(p),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppColors.danger, size: 40),
                  ),
              ]),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${list.length} Money Changer di Sekitar', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(_gps ? 'Berdasarkan lokasi GPS kamu' : 'GPS belum aktif: memakai lokasi contoh. Data tempat adalah contoh.',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 10),
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(' ${p.rating}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ]),
                      Text(p.address, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.directions_walk, size: 16, color: AppColors.tealDark),
                        Text(' ${(_dist(p)).round()} m • ${p.hours}', style: const TextStyle(fontSize: 12)),
                      ]),
                      Text('Kurs USD: ${p.usd}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
