# CaloriMate Mobile App 📱

![Flutter](https://img.shields.io/badge/Flutter-%5E3.11.4-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-SDK-blue?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android-green)

CaloriMate Mobile adalah aplikasi pendamping berbasis **Flutter** untuk platform CaloriMate. Aplikasi ini dirancang khusus untuk mempermudah Client dan Trainer dalam mencatat nutrisi, melakukan latihan olahraga, dan memantau progres kesehatan langsung dari genggaman tangan.

Aplikasi ini terhubung langsung secara real-time dengan [CaloriMate Backend (Laravel)](https://github.com/rojisanmi/CaloriMate) melalui RESTful API.

---

## 🌟 Fitur Utama

### 🏋️‍♂️ Untuk Trainer
- **Dashboard Ringkas:** Pantau aktivitas klien dan metrik kesehatan terbaru.
- **Kelola Database Makanan:** Tambah dan edit daftar makanan beserta kandungan nutrisinya (kalori, protein, lemak, karbohidrat) langsung dari HP.
- **Kelola Program Latihan:** Susun program olahraga yang dipersonalisasi untuk klien, atur tingkat kesulitan, serta tambahkan langkah-langkah gerakannya.
- **Profil Trainer:** Perbarui informasi diri dan unggah sertifikasi keahlian.

### 🏃‍♀️ Untuk Client
- **Buku Harian (Diary) Nutrisi:** Catat konsumsi sarapan, makan siang, makan malam, dan camilan dengan fitur pencarian makanan yang sangat cepat.
- **Program Olahraga (Exercise):** Ikuti program latihan yang dibuat oleh Trainer. Terdapat sistem progres *step-by-step* untuk setiap gerakan.
- **Statistik & Riwayat:** Pantau grafik kalori masuk vs kalori keluar setiap harinya.
- **Sistem Cerdas (Rekomendasi):** Dapatkan saran makanan harian dan program olahraga berdasarkan histori diet dan target BMI Anda.
- **Notifikasi Pengingat:** Pengingat otomatis untuk jadwal makan dan latihan fisik.

---

## 📸 Tampilan Antarmuka (UI)

Aplikasi ini menggunakan desain yang bersih, modern, dan sangat intuitif dengan skema warna **Hijau (Primary)** dan **Oranye (Accent)**.

Fitur UI Unggulan:
- Navigasi mulus menggunakan animasi modern.
- *Background* aplikasi bermotif (*pattern*) untuk estetika visual.
- *Snackbar* responsif untuk *feedback* aksi pengguna.
- Sistem *Upload Image* (Kamera/Galeri) yang terintegrasi.

---

## 🚀 Cara Menjalankan Project (Getting Started)

### Prasyarat
Pastikan Anda sudah menginstal:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Minimum versi 3.11.4)
- Android Studio / VS Code dengan plugin Flutter
- Perangkat Android (Fisik atau Emulator)

### Langkah-langkah Build

1. **Clone repositori ini**
   ```bash
   git clone https://github.com/rojisanmi/CaloriMate_Mobile.git
   cd CaloriMate_Mobile
   ```

2. **Unduh dependencies (Package)**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi URL API Backend**
   Buka file `lib/config/api_config.dart`.
   Pastikan URL mengarah ke server Laravel lokal Anda (jika dites di emulator, gunakan IP komputer Anda, contoh: `192.168.x.x` atau `10.0.2.2`).
   ```dart
   static const String baseUrl = 'http://192.168.X.X:8000/api'; 
   ```

4. **Jalankan Aplikasi**
   Hubungkan HP Anda (USB Debugging) atau nyalakan Emulator, lalu jalankan:
   ```bash
   flutter run
   ```
   *Atau untuk mem-build file APK:*
   ```bash
   flutter build apk
   ```

---

## 📦 Dependensi Utama (Packages)

Aplikasi ini dibangun menggunakan beberapa *package* andalan Flutter:
- `dio`: Untuk HTTP requests (API client) ke server Laravel.
- `provider`: Untuk State Management (Auth, Notifications, dll).
- `shared_preferences`: Untuk penyimpanan token lokal.
- `fl_chart`: Untuk visualisasi data statistik kalori.
- `flutter_local_notifications`: Untuk memunculkan notifikasi terjadwal di perangkat.
- `image_picker` & `file_picker`: Untuk fitur unggah foto profil dan sertifikasi.
- `audioplayers`: Untuk efek suara (contoh: notifikasi latihan selesai).

---

## 🔑 Akun Uji Coba (Testing)

Anda dapat menggunakan akun berikut untuk masuk ke dalam aplikasi (pastikan Backend sudah di-seed):

**Trainer:**
- **Email/Username:** `trainer1`
- **Password:** `password`

**Client:**
- **Email/Username:** `client1`
- **Password:** `password`

---

*Dikembangkan dengan ❤️ untuk gaya hidup yang lebih sehat.*
