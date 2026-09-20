# Latihan Shared Preferences Flutter

Proyek ini melanjutkan latihan Networking Flutter. Aplikasi mengambil daftar pengguna dari API lalu menyimpan pengguna terakhir yang dipilih menggunakan Shared Preferences.

## Tujuan Pembelajaran

- Memahami penyimpanan lokal berformat key-value.
- Menyimpan data dengan `setInt()` dan `setString()`.
- Membaca data dengan `getInt()` dan `getString()`.
- Menghapus data dengan `remove()`.
- Menghubungkan data lokal dengan GetX dan antarmuka Flutter.

## Fitur

- Mengambil serta menampilkan daftar pengguna dari API.
- Memilih satu pengguna dari daftar.
- Menyimpan ID, nama, dan email pengguna terakhir secara lokal.
- Menampilkan kartu **Pengguna Terakhir Dipilih** setelah aplikasi dibuka kembali.
- Menghapus data pengguna terakhir dari penyimpanan lokal.

## Dependency Tambahan

Jalankan perintah berikut sebelum menjalankan aplikasi:

```bash
flutter pub add shared_preferences
flutter pub get
```

## Key yang Disimpan

| Key | Tipe | Keterangan |
|---|---|---|
| `last_user_id` | `int` | ID pengguna terakhir dipilih |
| `last_user_name` | `String` | Nama pengguna terakhir dipilih |
| `last_user_email` | `String` | Email pengguna terakhir dipilih |

## Struktur Tambahan

```text
lib/
├── controllers/
│   └── user_controller.dart
├── services/
│   └── local_storage_service.dart
└── views/
    └── home_view.dart
```

## Alur Aplikasi

```text
Daftar pengguna diambil dari API
            ↓
Pengguna menekan ikon bookmark
            ↓
ID, nama, dan email disimpan ke Shared Preferences
            ↓
Aplikasi ditutup dan dibuka kembali
            ↓
Kartu pengguna terakhir tetap ditampilkan
```

## Cara Menjalankan

```bash
git clone https://github.com/ikhsan-fillah/shared-preferences-itc.git
cd shared-preferences-itc
flutter pub add shared_preferences
flutter run
```

## Catatan

Shared Preferences cocok untuk data sederhana seperti pengaturan aplikasi, status login sederhana, atau pengguna terakhir dipilih. Jangan gunakan Shared Preferences untuk kata sandi atau data sensitif.
