# CoinWise (Flutter)

Aplikasi edukasi keuangan & kripto untuk tugas akhir Pemrograman Aplikasi Mobile.
Kode ini dibuat dari desain Stitch (`stitch_coinwise_student_crypto_app`).

## Status
| Sudah ada | Menyusul (tahap berikutnya) |
|---|---|
| Semua layar sesuai desain (17 layar) | Database SQLite + sinkron online |
| Register/login hash+salt, session, biometrik | Notifikasi harga |
| Harga kripto (CoinGecko), kurs (Frankfurter) | Ganti foto profil dari kamera/galeri |
| Simulasi beli/jual + blockchain sederhana | Rute di peta money changer |
| Sensor: accelerometer (goyang) + gyroscope (miring) | Data money changer asli |
| Mini game, chatbot AI, konversi waktu, peta (LBS) | |

Penyimpanan SEMENTARA memakai SharedPreferences (lihat `lib/services/app_state.dart`).
Saat database siap, cukup ganti isi fungsi di file itu.

## Cara menjalankan
1. `flutter create --org com.kelompok --project-name coinwise coinwise`
2. Salin ke folder `coinwise` hasil langkah 1: `lib/`, `assets/`, dan `pubspec.yaml` (timpa).
3. Hapus file `test/widget_test.dart` (bawaan, akan error).
4. Tambahkan izin Android dari `android_setup/AndroidManifest_tambahan.xml`.
5. Ganti `MainActivity.kt` mengikuti `android_setup/MainActivity.kt`.
6. `flutter pub get`
7. Sambungkan HP (USB debugging) lalu `flutter run`.

Dengan API key (opsional):
`flutter run --dart-define=GEMINI_KEY=kunci --dart-define=COINGECKO_KEY=kunci`

## Jika error biometrik "Theme.AppCompat"
Di `android/app/src/main/res/values/styles.xml` (dan `values-night/styles.xml`),
ubah `parent` pada `LaunchTheme` dan `NormalTheme` menjadi `Theme.AppCompat.Light.NoTitleBar`.
