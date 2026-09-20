# Shared Preferences ITC — Menyimpan Pengguna Terakhir Dipilih

Latihan ini melanjutkan project Networking yang sudah tersedia. Kita **tidak membahas ulang** cara mengambil data dari API, model `User`, `ApiService`, maupun struktur awal GetX.

Fokus praktikum ini hanya pada **Shared Preferences**: menyimpan pengguna terakhir yang dipilih secara lokal, membaca kembali data tersebut saat aplikasi dibuka, dan menghapusnya.

Setelah mengikuti bagian ini, kamu akan paham:

- Menambahkan package `shared_preferences`
- Membuat key untuk data lokal
- Menyimpan data dengan `setInt()` dan `setString()`
- Membaca data dengan `getInt()` dan `getString()`
- Menangani data yang belum tersedia (`null`)
- Menghapus data dengan `remove()`
- Menampilkan data lokal kembali melalui `UserController` dan `GetBuilder`

## Hasil Akhir

Aplikasi yang sebelumnya sudah menampilkan daftar pengguna dari API akan memiliki fitur tambahan:

1. Setiap pengguna memiliki tombol/ikon bookmark untuk dipilih.
2. Ketika bookmark ditekan, ID, nama, dan email pengguna disimpan ke Shared Preferences.
3. Kartu **Pengguna Terakhir Dipilih** muncul di atas daftar pengguna.
4. Setelah aplikasi ditutup dan dibuka kembali, kartu tersebut tetap menampilkan data terakhir.
5. Pengguna dapat menghapus data tersimpan melalui tombol hapus.

## Data yang Disimpan

Shared Preferences menyimpan data dalam format **key-value**.

| Key               | Tipe Data | Isi                             |
| ----------------- | --------- | ------------------------------- |
| `last_user_id`    | `int`     | ID pengguna terakhir dipilih    |
| `last_user_name`  | `String`  | Nama pengguna terakhir dipilih  |
| `last_user_email` | `String`  | Email pengguna terakhir dipilih |

Alur datanya:

```text
Pengguna memilih salah satu data dari daftar
            ↓
Controller menerima object User
            ↓
LocalStorageService menyimpan tiap property dengan key-value
            ↓
Shared Preferences menyimpan data pada perangkat
            ↓
Aplikasi dibuka kembali
            ↓
Controller membaca data dan UI menampilkan kartu pengguna terakhir
```

## Langkah Implementasi

Urutan pengerjaannya: siapkan package, buat service lokal, sambungkan ke controller, lalu tampilkan hasilnya di halaman utama.

### Step 1 — Tambahkan Package

Di terminal pada folder project, jalankan:

```bash
flutter pub add shared_preferences
```

Setelah itu jalankan:

```bash
flutter pub get
```

Package `shared_preferences` menyediakan class `SharedPreferences` agar Flutter dapat menyimpan data key-value secara lokal.

### Step 2 — Buat Service Lokal

Buat file baru:

```text
lib/services/local_storage_service.dart
```

Semua kode yang berhubungan dengan Shared Preferences diletakkan di file ini. Dengan begitu, controller tidak perlu mengetahui detail key maupun cara menyimpan data.

```dart
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class LocalStorageService {
  // Key harus konsisten saat data disimpan dan dibaca.
  static const _keyUserId = 'last_user_id';
  static const _keyUserName = 'last_user_name';
  static const _keyUserEmail = 'last_user_email';

  Future<void> saveLastSelectedUser(User user) async {
    final prefs = await SharedPreferences.getInstance();

    // Menyimpan property User sebagai data sederhana.
    await prefs.setInt(_keyUserId, user.id);
    await prefs.setString(_keyUserName, user.name);
    await prefs.setString(_keyUserEmail, user.email);
  }

  Future<User?> getLastSelectedUser() async {
    final prefs = await SharedPreferences.getInstance();

    // Membaca data berdasarkan key yang sama.
    final id = prefs.getInt(_keyUserId);
    final name = prefs.getString(_keyUserName);
    final email = prefs.getString(_keyUserEmail);

    // Data belum ada atau tidak lengkap.
    if (id == null || name == null || email == null) {
      return null;
    }

    // Membuat ulang object User dari data lokal.
    return User(id: id, name: name, email: email);
  }

  Future<void> removeLastSelectedUser() async {
    final prefs = await SharedPreferences.getInstance();

    // Menghapus setiap data berdasarkan key-nya.
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
  }
}
```

### Penjelasan Service

#### Key sebagai identitas data

```dart
static const _keyUserName = 'last_user_name';
```

`last_user_name` adalah key. Shared Preferences memakai key ini untuk menemukan value yang tepat. Karena key digunakan berkali-kali, kita menyimpannya sebagai konstanta agar tidak salah ketik.

#### Menyimpan data

```dart
await prefs.setInt(_keyUserId, user.id);
await prefs.setString(_keyUserName, user.name);
```

- `setInt()` dipakai untuk `id` karena `id` bertipe `int`.
- `setString()` dipakai untuk `name` dan `email` karena keduanya bertipe `String`.
- `await` dipakai karena proses penyimpanan bersifat asinkron.

#### Membaca data

```dart
final name = prefs.getString(_keyUserName);
```

Method `getString()` dapat mengembalikan `null` jika data belum pernah disimpan atau key tidak sesuai. Karena itu, semua data diperiksa terlebih dahulu sebelum object `User` dibuat kembali.

#### Menghapus data

```dart
await prefs.remove(_keyUserName);
```

`remove()` hanya menghapus satu data berdasarkan key. Pada latihan ini, tiga key dihapus agar informasi pengguna terakhir benar-benar hilang.

### Step 3 — Tambahkan State pada Controller

Buka file berikut:

```text
lib/controllers/user_controller.dart
```

Tambahkan import service lokal:

```dart
import '../services/local_storage_service.dart';
```

Di dalam class `UserController`, tambahkan property berikut:

```dart
final LocalStorageService _localStorageService = LocalStorageService();

// Data pengguna terakhir yang akan ditampilkan pada UI.
User? lastSelectedUser;
```

`lastSelectedUser` menggunakan `User?` karena saat aplikasi pertama kali dijalankan, belum tentu ada pengguna yang sudah disimpan.

### Step 4 — Baca Data Saat Controller Dibuat

Pada method `onInit()`, tambahkan pemanggilan `getLastSelectedUser()`.

```dart
@override
void onInit() {
  super.onInit();

  // Method pemuatan data API yang sudah ada pada project sebelumnya.
  getUsers();

  // Membaca pengguna terakhir dari Shared Preferences.
  getLastSelectedUser();
}
```

Kemudian tambahkan method berikut di dalam `UserController`:

```dart
Future<void> getLastSelectedUser() async {
  lastSelectedUser = await _localStorageService.getLastSelectedUser();

  // Memberi tahu GetBuilder agar UI dibangun ulang.
  update();
}
```

Saat aplikasi dibuka, controller langsung meminta data lokal. Jika data tersedia, `lastSelectedUser` berisi object `User`; jika belum tersedia, nilainya `null`.

### Step 5 — Buat Method Memilih Pengguna

Tambahkan method berikut ke dalam `UserController`:

```dart
Future<void> selectUser(User user) async {
  // Menyimpan pengguna yang dipilih ke Shared Preferences.
  await _localStorageService.saveLastSelectedUser(user);

  // Memperbarui state agar hasilnya langsung terlihat.
  lastSelectedUser = user;
  update();
}
```

Method ini menerima object `User` dari item daftar. Object tersebut disimpan sebagai tiga value sederhana, lalu UI diperbarui tanpa perlu menutup aplikasi.

### Step 6 — Buat Method Menghapus Data

Tambahkan method berikut ke dalam `UserController`:

```dart
Future<void> removeLastSelectedUser() async {
  // Menghapus data dari Shared Preferences.
  await _localStorageService.removeLastSelectedUser();

  // Mengosongkan state agar kartu hilang dari UI.
  lastSelectedUser = null;
  update();
}
```

Setelah `lastSelectedUser` menjadi `null`, kondisi pada tampilan akan membuat kartu pengguna terakhir tidak lagi ditampilkan.

### Step 7 — Tambahkan Kartu Pengguna Terakhir

Buka file:

```text
lib/views/home_view.dart
```

Pada `ListView` yang sudah menampilkan daftar pengguna, tambahkan kode berikut **di bagian paling atas** dari `children`:

```dart
if (controller.lastSelectedUser != null)
  _LastSelectedUserCard(
    user: controller.lastSelectedUser!,
    onDelete: controller.removeLastSelectedUser,
  ),
```

Kondisi tersebut berarti: kartu hanya ditampilkan jika terdapat data pengguna yang sudah disimpan.

Kemudian tambahkan widget berikut di bagian bawah file `home_view.dart`:

```dart
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
        leading: CircleAvatar(
          child: Text(user.name[0]),
        ),
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

Widget ini menerima:

- `user`: data pengguna yang dibaca dari controller.
- `onDelete`: function untuk menghapus data lokal ketika tombol ikon hapus ditekan.

### Step 8 — Tambahkan Tombol Pilih pada Daftar Pengguna

Pada widget item pengguna yang sudah ada, tambahkan tombol atau `IconButton` berikut:

```dart
IconButton(
  tooltip: 'Pilih pengguna',
  icon: const Icon(Icons.bookmark_add_outlined),
  onPressed: () => controller.selectUser(user),
)
```

Saat ikon bookmark ditekan, object `user` dari daftar dikirim ke `selectUser(user)`. Controller kemudian menyimpan property pengguna ke Shared Preferences.

Contoh jika item pengguna memakai `ListTile`:

```dart
ListTile(
  leading: CircleAvatar(child: Text(user.name[0])),
  title: Text(user.name),
  subtitle: Text(user.email),
  trailing: IconButton(
    tooltip: 'Pilih pengguna',
    icon: const Icon(Icons.bookmark_add_outlined),
    onPressed: () => controller.selectUser(user),
  ),
)
```

### Step 9 — Jalankan dan Tes

Jalankan aplikasi:

```bash
flutter run
```

Yang perlu dites:

1. Daftar pengguna dari project Networking sebelumnya tetap tampil.
2. Tekan ikon bookmark pada salah satu pengguna.
3. Kartu **Pengguna Terakhir Dipilih** muncul di bagian atas.
4. Tutup aplikasi sepenuhnya, bukan hanya hot reload.
5. Jalankan aplikasi lagi.
6. Pastikan kartu masih menunjukkan pengguna yang sama.
7. Tekan ikon hapus pada kartu.
8. Pastikan kartu menghilang.
9. Tutup dan buka kembali aplikasi untuk memastikan data sudah benar-benar terhapus.

## Kesalahan yang Sering Terjadi

### Package belum ditambahkan

Jika muncul error seperti berikut:

```text
Target of URI doesn't exist: package:shared_preferences/shared_preferences.dart
```

jalankan:

```bash
flutter pub add shared_preferences
flutter pub get
```

### Key saat simpan dan baca berbeda

Kode berikut tidak akan bekerja karena key berbeda:

```dart
await prefs.setString('last_user_name', user.name);
final name = prefs.getString('lastUserName');
```

Gunakan key yang sama persis. Karena itu, latihan ini memakai konstanta seperti `_keyUserName`.

### Data bernilai null

Ini normal jika belum ada pengguna yang dipilih. Pastikan data diperiksa sebelum digunakan:

```dart
if (controller.lastSelectedUser != null) {
  // Tampilkan kartu pengguna terakhir.
}
```

### Tidak memakai await

Operasi `set...()` dan `remove()` bersifat asinkron. Gunakan `await` agar proses penyimpanan atau penghapusan selesai sebelum state diperbarui.

```dart
await _localStorageService.saveLastSelectedUser(user);
```

## Eksperimen Lanjutan

Setelah fitur utama berhasil, coba beberapa pengembangan berikut:

1. Tambahkan data pengguna lain dari API, misalnya nomor telepon atau website.
2. Tambahkan `SnackBar` atau `Get.snackbar()` setelah pengguna berhasil dipilih.
3. Tampilkan dialog konfirmasi sebelum data pengguna terakhir dihapus.
4. Tambahkan fitur menyimpan tema terang/gelap menggunakan `setBool()` dan `getBool()`.

> Prinsip yang perlu diingat: Shared Preferences digunakan untuk data kecil dan sederhana. Ia menyimpan setiap value secara mandiri berdasarkan key. Jangan gunakan Shared Preferences untuk kata sandi atau data sensitif.
