# Shared Preferences ITC — Tutorial Penyimpanan Lokal dengan Flutter

Aplikasi daftar pengguna sederhana untuk belajar **Shared Preferences**: menyimpan pengguna terakhir yang dipilih secara lokal agar datanya tetap tersedia ketika aplikasi ditutup lalu dibuka kembali. Proyek ini melanjutkan materi Networking, sehingga data pengguna tetap diambil dari API terlebih dahulu.

Dibuat sebagai materi praktikum. Fokusnya bukan pada tampilan UI, tetapi pada alur data: **API → Controller → Shared Preferences → UI**.

Setelah mengikuti repo ini, kamu akan paham:

- Mengambil data pengguna dari API dengan package `http`
- Memahami pemisahan `ApiService` dan `LocalStorageService`
- Menyimpan data sederhana menggunakan `setInt()` dan `setString()`
- Membaca data lokal menggunakan `getInt()` dan `getString()`
- Menghapus data lokal menggunakan `remove()`
- Menangani data yang belum tersedia dengan `null`
- Menggunakan `GetxController`, `GetBuilder`, dan `Binding` untuk menghubungkan logika dengan UI

## Struktur Project

```text
lib/
 ├─ main.dart                              ← gerbang utama aplikasi
 ├─ bindings/
 │   └─ user_binding.dart                  ← pendaftar ApiService dan UserController
 ├─ controllers/
 │   └─ user_controller.dart               ← otak: data API + pengguna terakhir dipilih
 ├─ models/
 │   └─ user.dart                          ← bentuk data pengguna
 ├─ services/
 │   ├─ api_service.dart                   ← mengambil daftar pengguna dari API
 │   └─ local_storage_service.dart         ← simpan, baca, dan hapus data lokal
 └─ views/
     └─ home_view.dart                     ← daftar pengguna + kartu data tersimpan
```

## Cara Menjalankan

```bash
git clone https://github.com/ikhsan-fillah/shared-preferences-itc.git
cd shared-preferences-itc
flutter pub add shared_preferences
flutter pub get
flutter run
```

> Jika package `get` dan `http` belum tersedia pada project baru, tambahkan juga dengan `flutter pub add get http`.

## Konsep Latihan

Aplikasi mengambil daftar pengguna dari API `jsonplaceholder`. Ketika salah satu pengguna dipilih, aplikasi menyimpan tiga data sederhana di Shared Preferences.

| Key               | Tipe Data | Isi                             |
| ----------------- | --------- | ------------------------------- |
| `last_user_id`    | `int`     | ID pengguna terakhir dipilih    |
| `last_user_name`  | `String`  | Nama pengguna terakhir dipilih  |
| `last_user_email` | `String`  | Email pengguna terakhir dipilih |

Alurnya:

```text
Daftar pengguna diambil dari API
            ↓
Pengguna menekan ikon bookmark
            ↓
ID, nama, dan email disimpan dengan Shared Preferences
            ↓
Aplikasi ditutup
            ↓
Aplikasi dibuka kembali
            ↓
Data pengguna terakhir dibaca dan ditampilkan kembali
```

## Langkah Membangun dari Awal

Urutan pengerjaannya dari data ke tampilan: buat bentuk data, ambil data dari API, buat penyimpanan lokal, sambungkan ke controller, lalu tampilkan pada halaman. Setiap step memakai hasil dari step sebelumnya.

### Step 1 — Siapkan Project dan Package

Buat project Flutter baru, lalu tambahkan package yang dibutuhkan.

```bash
flutter create shared_preferences_itc
cd shared_preferences_itc
flutter pub add get
flutter pub add http
flutter pub add shared_preferences
```

Kegunaan package:

| Package              | Kegunaan                                  |
| -------------------- | ----------------------------------------- |
| `get`                | State management dan dependency injection |
| `http`               | Mengambil data dari API                   |
| `shared_preferences` | Menyimpan data sederhana secara lokal     |

### Step 2 — Buat Bentuk Data: `models/user.dart`

Kelas `User` adalah cetakan data pengguna. Data JSON dari API akan diubah menjadi object Dart melalui `User.fromJson()`.

```dart
class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}
```

Model ini dipakai oleh dua bagian aplikasi:

- `ApiService`, untuk mengubah respons API menjadi object `User`
- `LocalStorageService`, untuk membuat ulang object `User` dari data lokal

### Step 3 — Buat Pengambil Data API: `services/api_service.dart`

File ini hanya bertugas melakukan request HTTP dan mengubah respons JSON menjadi `List<User>`. Ia tidak mengatur UI dan tidak menyimpan data lokal.

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';

class ApiService {
  final String _baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      return data.map((json) => User.fromJson(json)).toList();
    }

    throw Exception('Gagal memuat data pengguna dari API');
  }
}
```

> Penting: tulis `Uri.parse('$_baseUrl/users')` tanpa karakter `\` sebelum `$`. Jika ditulis `\$_baseUrl`, aplikasi tidak melakukan interpolasi variabel dan respons yang diterima dapat berupa HTML, bukan JSON.

### Step 4 — Buat Penyimpanan Lokal: `services/local_storage_service.dart`

Inilah bagian utama materi Shared Preferences. File ini bertugas menyimpan, membaca, dan menghapus pengguna terakhir yang dipilih.

```dart
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class LocalStorageService {
  static const _keyUserId = 'last_user_id';
  static const _keyUserName = 'last_user_name';
  static const _keyUserEmail = 'last_user_email';

  Future<void> saveLastSelectedUser(User user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.name);
    await prefs.setString(_keyUserEmail, user.email);
  }

  Future<User?> getLastSelectedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getInt(_keyUserId);
    final name = prefs.getString(_keyUserName);
    final email = prefs.getString(_keyUserEmail);

    if (id == null || name == null || email == null) {
      return null;
    }

    return User(id: id, name: name, email: email);
  }

  Future<void> removeLastSelectedUser() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
  }
}
```

Penjelasan method:

- `SharedPreferences.getInstance()` membuka akses ke penyimpanan lokal aplikasi.
- `setInt()` dan `setString()` menyimpan value berdasarkan key.
- `getInt()` dan `getString()` membaca value dari key yang sama.
- Nilai hasil `get...()` dapat berupa `null` apabila data belum pernah disimpan.
- `remove()` menghapus satu data berdasarkan key.

### Step 5 — Buat Otaknya: `controllers/user_controller.dart`

Controller menjadi penghubung antara service dan tampilan. Controller memuat daftar pengguna dari API serta pengguna terakhir dari Shared Preferences.

```dart
import 'package:get/get.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class UserController extends GetxController {
  final ApiService apiService;
  final LocalStorageService _localStorageService = LocalStorageService();

  UserController({required this.apiService});

  List<User> users = [];
  bool isLoading = false;
  String errorMessage = '';
  User? lastSelectedUser;

  @override
  void onInit() {
    super.onInit();
    getUsers();
    getLastSelectedUser();
  }

  Future<void> getUsers() async {
    try {
      isLoading = true;
      errorMessage = '';
      update();

      users = await apiService.getUsers();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> getLastSelectedUser() async {
    lastSelectedUser = await _localStorageService.getLastSelectedUser();
    update();
  }

  Future<void> selectUser(User user) async {
    await _localStorageService.saveLastSelectedUser(user);
    lastSelectedUser = user;
    update();
  }

  Future<void> removeLastSelectedUser() async {
    await _localStorageService.removeLastSelectedUser();
    lastSelectedUser = null;
    update();
  }
}
```

Alur `selectUser()`:

```text
Tombol bookmark ditekan
        ↓
selectUser(user) dipanggil
        ↓
saveLastSelectedUser(user) menyimpan data ke Shared Preferences
        ↓
lastSelectedUser diperbarui
        ↓
update() memberi tahu GetBuilder untuk membangun ulang UI
```

### Step 6 — Daftarkan Dependency: `bindings/user_binding.dart`

Binding adalah tempat mendaftarkan object yang diperlukan oleh halaman. `ApiService` dibuat terlebih dahulu, lalu dimasukkan ke constructor `UserController`.

```dart
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../services/api_service.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiService>(() => ApiService());

    Get.lazyPut<UserController>(
      () => UserController(apiService: Get.find<ApiService>()),
    );
  }
}
```

`Get.lazyPut()` berarti GetX baru membuat object saat object tersebut pertama kali dibutuhkan.

### Step 7 — Buat Wajah Aplikasi: `views/home_view.dart`

Halaman utama melakukan tiga hal:

1. Menampilkan loading saat data API diambil.
2. Menampilkan kartu pengguna terakhir apabila data lokal tersedia.
3. Menampilkan daftar pengguna dari API dengan tombol bookmark.

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_controller.dart';
import '../models/user.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pengguna')),
      body: GetBuilder<UserController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.isNotEmpty) {
            return Center(child: Text(controller.errorMessage));
          }

          return ListView(
            children: [
              if (controller.lastSelectedUser != null)
                _LastSelectedUserCard(
                  user: controller.lastSelectedUser!,
                  onDelete: controller.removeLastSelectedUser,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Daftar Pengguna dari API',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...controller.users.map(
                (user) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(user.name[0])),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: IconButton(
                      tooltip: 'Pilih pengguna',
                      icon: const Icon(Icons.bookmark_add_outlined),
                      onPressed: () => controller.selectUser(user),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LastSelectedUserCard extends StatelessWidget {
  final User user;
  final VoidCallback onDelete;

  const _LastSelectedUserCard({
    required this.user,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: CircleAvatar(child: Text(user.name[0])),
        title: const Text('Pengguna Terakhir Dipilih'),
        subtitle: Text('${user.name}\n${user.email}'),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Hapus data lokal',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
```

Bagian penting pada tampilan:

```dart
if (controller.lastSelectedUser != null)
```

Kartu hanya muncul ketika Shared Preferences sudah memiliki data pengguna.

```dart
onPressed: () => controller.selectUser(user)
```

Tombol bookmark mengirim object `User` yang dipilih ke controller untuk disimpan.

```dart
onPressed: controller.removeLastSelectedUser
```

Tombol hapus menghapus data lokal dan membuat kartu menghilang.

### Step 8 — Nyalakan Aplikasi: `main.dart`

`GetMaterialApp` digunakan sebagai root aplikasi agar GetX dapat menjalankan binding dan `GetBuilder`.

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings/user_binding.dart';
import 'views/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: UserBinding(),
      home: const HomeView(),
    );
  }
}
```

### Step 9 — Jalankan dan Tes

```bash
flutter run
```

Yang perlu dites:

1. Daftar pengguna dari API tampil pada halaman utama.
2. Tekan ikon bookmark pada salah satu pengguna.
3. Kartu **Pengguna Terakhir Dipilih** muncul di bagian atas.
4. Tutup aplikasi sepenuhnya, lalu jalankan kembali.
5. Kartu masih menampilkan pengguna yang sama.
6. Tekan ikon hapus pada kartu.
7. Pastikan kartu menghilang, lalu buka ulang aplikasi untuk memastikan datanya telah terhapus.

## Eksperimen Lanjutan

Coba beberapa perubahan kecil berikut agar konsep Shared Preferences lebih mudah dipahami:

1. **Simpan data tambahan**: tambahkan key `last_user_company` atau `last_user_phone` dari respons API, kemudian tampilkan pada kartu pengguna terakhir.
2. **Ganti satu key saat membaca**: simpan dengan key `last_user_name`, tetapi baca dengan key `lastUserName`. Nilai akan menjadi `null` karena key harus sama persis.
3. **Hapus satu data saja**: pada `removeLastSelectedUser()`, hapus hanya `_keyUserName`. Saat aplikasi dibuka kembali, `getLastSelectedUser()` tetap mengembalikan `null` karena satu bagian data tidak lengkap.
4. **Tambahkan dialog konfirmasi** sebelum menghapus pengguna terakhir.

> Prinsip yang perlu diingat: Shared Preferences cocok untuk data kecil dan sederhana. Setiap key menyimpan satu value secara mandiri. Untuk data tabel yang besar atau saling berelasi, gunakan database lokal seperti SQLite.
