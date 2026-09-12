# Flutter Networking App (Dengan API Service & Dependency Injection)

Aplikasi sederhana ini menunjukkan cara melakukan HTTP request (networking) di Flutter menggunakan package `http`, mengelola response asinkron menggunakan `Future` dan `FutureBuilder`, serta menggunakan **Dependency Injection (DI)** dengan state management `GetX` untuk pemisahan logika (Separation of Concerns).

API yang digunakan adalah API dummy dari [JSONPlaceholder](https://jsonplaceholder.typicode.com/users).

## Konsep yang Diterapkan
1. **API Service**: Memisahkan logika request HTTP ke dalam kelas khusus agar kode lebih rapi dan dapat digunakan ulang (reusable).
2. **Dependency Injection**: Memasukkan (injecting) `ApiService` ke dalam `UserController` menggunakan fitur `Bindings` dari GetX.

---

## Langkah-langkah Pembuatan Aplikasi (Dari Awal)

### 1. Buat Project Flutter Baru
Buka terminal (atau command prompt) dan jalankan perintah berikut:
```bash
flutter create networking_app
cd networking_app
```

### 2. Install Package yang Dibutuhkan
Kita membutuhkan package `http` dan `get`.
```bash
flutter pub add http get
```

### 3. Tambahkan Perizinan Internet di Android
Karena aplikasi ini membutuhkan koneksi internet untuk mengakses API, pastikan Anda menambahkan *permission* internet pada file Android Manifest.
Buka file `android/app/src/main/AndroidManifest.xml` lalu tambahkan baris `<uses-permission android:name="android.permission.INTERNET" />` di atas tag `<application>`. Contohnya:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        ...
```

### 4. Buat Struktur Folder
Untuk arsitektur berbasis API Service & DI, buat struktur folder seperti berikut di dalam folder `lib/`:
```text
lib/
├── bindings/
│   └── user_binding.dart
├── controllers/
│   └── user_controller.dart
├── models/
│   └── user.dart
├── services/
│   └── api_service.dart
├── views/
│   └── home_view.dart
└── main.dart
```

### 5. Buat Model (`lib/models/user.dart`)
Kelas ini berfungsi memetakan (parsing) data JSON dari API menjadi objek Dart.
```dart
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}
```

### 6. Buat API Service (`lib/services/api_service.dart`)
Kelas khusus yang tugasnya **hanya** untuk melakukan panggilan HTTP.
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  final String _baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('\$_baseUrl/users'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data users dari API');
    }
  }
}
```

### 7. Buat Controller (`lib/controllers/user_controller.dart`)
Controller ini menerima `ApiService` melalui *Constructor* (Inilah yang disebut **Dependency Injection** tingkat kelas).
```dart
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserController extends GetxController {
  final ApiService apiService; // Ketergantungan pada ApiService

  // Menerima ApiService via constructor
  UserController({required this.apiService});

  Future<List<User>> fetchUsers() {
    return apiService.getUsers();
  }
}
```

### 8. Buat Binding untuk GetX DI (`lib/bindings/user_binding.dart`)
Binding bertugas sebagai tempat mendaftarkan semua *dependency* (ketergantungan) kelas sebelum aplikasi menampilkannya di memori.
```dart
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../services/api_service.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    // Inject ApiService
    Get.lazyPut<ApiService>(() => ApiService());
    
    // Inject UserController dan masukkan (inject) ApiService ke dalamnya dengan Get.find()
    Get.lazyPut<UserController>(() => UserController(apiService: Get.find<ApiService>()));
  }
}
```

### 9. Buat View dengan FutureBuilder (`lib/views/home_view.dart`)
Panggil Controller cukup dengan `Get.find<UserController>()` karena sudah disediakan oleh Binding.
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../models/user.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil controller yang sudah di-inject
    final UserController userController = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Networking App with GetX DI'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<User>>(
        future: userController.fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data user.'));
          } else {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(user.id.toString())),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.email),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
```

### 10. Atur Entry Point di `main.dart`
Ubah file `lib/main.dart` dan tambahkan `initialBinding: UserBinding()`.
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
      title: 'Flutter Networking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Mendaftarkan UserBinding
      initialBinding: UserBinding(),
      home: const HomeView(),
    );
  }
}
```

### 11. Jalankan Aplikasi
Jalankan emulator atau hubungkan perangkat, lalu jalankan perintah ini di terminal:
```bash
flutter run
```
Aplikasi sekarang berjalan dengan struktur arsitektur yang lebih *clean* dengan pemisahan antara View, Controller, dan Services!
