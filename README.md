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
- Menyesuaikan `getUsers()` pada `UserController` agar kompatibel dengan pola state di atas
- Mengganti `FutureBuilder` di `HomeView` menjadi `GetBuilder` agar kartu pengguna terakhir bisa ditampilkan
- Menampilkan indikator loading dan error saat data lokal dimuat

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

Urutan pengerjaannya: siapkan package, buat service lokal, sesuaikan controller yang sudah ada, sambungkan state baru, ganti struktur `HomeView` dari `FutureBuilder` ke `GetBuilder`, lalu tampilkan hasilnya di halaman utama.

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

### Step 3 — Sesuaikan Method getUsers() pada Controller

Sebelum menambahkan state baru untuk Shared Preferences, pastikan dulu `getUsers()` pada `UserController` sudah dalam bentuk yang menyimpan data ke property controller, bukan sekadar mengembalikan `Future` yang dipanggil langsung dari `FutureBuilder` di `HomeView`. Penyesuaian ini diperlukan karena `GetBuilder` dan `update()` yang dipakai pada langkah-langkah berikutnya hanya bekerja jika controller memiliki state sendiri.

Buka file:

```text
lib/controllers/user_controller.dart
```

Jika `getUsers()` di project kamu masih berbentuk seperti ini (dipanggil langsung sebagai `future` pada `FutureBuilder`):

```dart
Future<List<User>> getUsers() {
  return apiService.getUsers();
}
```

ubah menjadi:

```dart
final List<User> users = [];
bool isLoading = false;
String errorMessage = '';

Future<void> getUsers() async {
  try {
    isLoading = true;
    errorMessage = '';
    update();

    users.assignAll(await apiService.getUsers());
  } catch (error) {
    errorMessage = error.toString();
  } finally {
    isLoading = false;
    update();
  }
}
```

Penjelasan penyesuaian:

- `users`, `isLoading`, dan `errorMessage` dijadikan property controller agar nilainya bertahan selama controller aktif, bukan hanya sesaat seperti nilai balik `Future`.
- `update()` dipanggil dua kali: sesaat sebelum request dimulai (agar UI langsung menampilkan status loading) dan sesudah proses selesai di blok `finally` (agar UI menampilkan hasil akhir, baik berhasil maupun gagal).
- `users.assignAll(...)` dipakai, bukan `users = ...`, karena `users` dideklarasikan sebagai `final`. `assignAll()` mengganti isi list tanpa mengganti object list itu sendiri.
- Return type method ini berubah dari `Future<List<User>>` menjadi `Future<void>`, karena hasilnya sekarang disimpan ke `users`, bukan dikembalikan langsung ke pemanggil.
- Perubahan return type ini berdampak langsung ke `HomeView`, karena `FutureBuilder<List<User>>` yang sebelumnya memanggil `future: userController.getUsers()` tidak bisa lagi menerima `Future<void>`. Penyesuaian `HomeView` dijelaskan lengkap pada Step 8.

### Step 4 — Tambahkan State pada Controller

Tambahkan import service lokal pada `lib/controllers/user_controller.dart`:

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

### Step 5 — Baca Data Saat Controller Dibuat

Tambahkan `onInit()` pada `UserController` jika belum ada, lalu panggil `getUsers()` dan `getLastSelectedUser()` di dalamnya:

```dart
@override
void onInit() {
  super.onInit();

  // Memuat daftar pengguna dari API, memakai versi getUsers() hasil Step 3.
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

Sebelumnya, pemanggilan `getUsers()` dilakukan dari `HomeView` melalui `FutureBuilder`. Setelah Step 3, pemanggilan dipindahkan ke `onInit()` supaya data otomatis dimuat begitu controller dibuat, sejalan dengan cara `lastSelectedUser` dimuat.

### Step 6 — Buat Method Memilih Pengguna

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

### Step 7 — Buat Method Menghapus Data

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

### Step 8 — Ganti Struktur HomeView dari FutureBuilder ke GetBuilder

Ini adalah bagian yang paling penting untuk dipahami urutannya, karena struktur `home_view.dart` pada project Networking berbeda jauh dari yang dibutuhkan fitur ini.

Struktur asli `home_view.dart` pada project Networking terlihat seperti berikut:

```dart
body: FutureBuilder<List<User>>(
  future: userController.getUsers(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
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
```

Struktur ini tidak bisa dipakai lagi setelah Step 3, karena dua alasan:

- `future: userController.getUsers()` tidak valid lagi, sebab `getUsers()` sekarang bertipe `Future<void>`, bukan `Future<List<User>>`.
- `FutureBuilder` hanya membaca data sekali saat `future` dipanggil. Ia tidak tahu kapan harus membangun ulang tampilan saat `selectUser()` atau `removeLastSelectedUser()` mengubah `lastSelectedUser`, karena perubahan itu terjadi lewat `update()`, bukan lewat `Future` baru.

Ganti seluruh isi `body` pada `HomeView` menjadi `GetBuilder<UserController>`:

```dart
body: GetBuilder<UserController>(
  builder: (controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.isNotEmpty) {
      return Center(child: Text('Error: ${controller.errorMessage}'));
    }

    if (controller.users.isEmpty) {
      return const Center(child: Text('Tidak ada data user.'));
    }

    return ListView.builder(
      itemCount: controller.users.length + 1,
      itemBuilder: (context, index) {
        // Index 0 dikhususkan untuk kartu pengguna terakhir.
        if (index == 0) {
          return controller.lastSelectedUser != null
              ? _LastSelectedUserCard(
                  user: controller.lastSelectedUser!,
                  onDelete: controller.removeLastSelectedUser,
                )
              : const SizedBox.shrink();
        }

        final user = controller.users[index - 1];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(child: Text(user.id.toString())),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.email),
            trailing: IconButton(
              tooltip: 'Pilih pengguna',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => controller.selectUser(user),
            ),
          ),
        );
      },
    );
  },
),
```

Penjelasan bagian ini:

- `GetBuilder<UserController>` menggantikan `FutureBuilder` sepenuhnya. `builder` di sini dipanggil ulang setiap kali `update()` dipanggil di controller, baik dari `getUsers()`, `getLastSelectedUser()`, `selectUser()`, maupun `removeLastSelectedUser()`.
- Kondisi `controller.isLoading`, `controller.errorMessage.isNotEmpty`, dan `controller.users.isEmpty` menggantikan tiga pengecekan `snapshot` pada `FutureBuilder` sebelumnya (`ConnectionState.waiting`, `snapshot.hasError`, `!snapshot.hasData || snapshot.data!.isEmpty`).
- `ListView.builder` tetap dipakai seperti versi asli, tetapi `itemCount` ditambah satu (`controller.users.length + 1`) untuk menyediakan satu slot khusus di `index == 0` bagi kartu pengguna terakhir.
- Ketika `index == 0` dan `lastSelectedUser` masih `null`, dikembalikan `SizedBox.shrink()` agar tidak ada ruang kosong yang aneh pada daftar.
- Item pengguna dari `index - 1` tetap ditampilkan dengan `Card` dan `ListTile` seperti struktur asli, hanya ditambah `trailing: IconButton` sebagai tombol pilih.

Tambahkan widget berikut di bagian bawah file `home_view.dart`, di luar class `HomeView`:

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

### Step 9 — Jalankan dan Tes

Jalankan aplikasi:

```bash
flutter run
```

Yang perlu dites:

1. Daftar pengguna dari project Networking sebelumnya tetap tampil, sekarang lewat `GetBuilder`, bukan `FutureBuilder`.
2. Tekan ikon bookmark pada salah satu pengguna.
3. Kartu **Pengguna Terakhir Dipilih** muncul di bagian paling atas daftar.
4. Tutup aplikasi sepenuhnya, bukan hanya hot reload.
5. Jalankan aplikasi lagi.
6. Pastikan kartu masih menunjukkan pengguna yang sama.
7. Tekan ikon hapus pada kartu.
8. Pastikan kartu menghilang.
9. Tutup dan buka kembali aplikasi untuk memastikan data sudah benar-benar terhapus.

## Step Tambahan — Indikator Loading dan Error

Bagian ini sifatnya penjelasan tambahan, bukan kode baru yang perlu ditulis ulang, karena indikator loading dan error sudah otomatis tercakup dalam `GetBuilder` pada Step 8 lewat kondisi `controller.isLoading` dan `controller.errorMessage.isNotEmpty`.

Yang perlu dipahami dari kedua kondisi tersebut:

- `controller.isLoading` bernilai `true` sesaat setelah `getUsers()` dipanggil di `onInit()`, sehingga `CircularProgressIndicator` akan langsung terlihat ketika aplikasi baru dibuka, sebelum data API selesai dimuat.
- `controller.errorMessage.isNotEmpty` hanya terisi jika `apiService.getUsers()` melempar error di dalam blok `try-catch` pada Step 3. Selama tidak ada error, kondisi ini tetap `false` dan bagian ini dilewati.
- Karena kedua kondisi diperiksa sebelum `ListView.builder` dibangun, kartu pengguna terakhir dan daftar pengguna tidak akan pernah tampil bersamaan dengan indikator loading atau pesan error.

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

### HomeView masih memakai FutureBuilder

Jika `home_view.dart` masih memanggil `future: userController.getUsers()` setelah Step 3 dilakukan, Dart akan menampilkan error tipe data karena `getUsers()` sudah bertipe `Future<void>`, bukan `Future<List<User>>` lagi. Pastikan seluruh struktur `FutureBuilder` pada `body` sudah diganti mengikuti Step 8, termasuk `itemCount`, `itemBuilder`, dan penambahan `_LastSelectedUserCard`.

## Eksperimen Lanjutan

Setelah fitur utama berhasil, coba beberapa pengembangan berikut:

1. Tambahkan data pengguna lain dari API, misalnya nomor telepon atau website.
2. Tambahkan `SnackBar` atau `Get.snackbar()` setelah pengguna berhasil dipilih.
3. Tampilkan dialog konfirmasi sebelum data pengguna terakhir dihapus.
4. Tambahkan fitur menyimpan tema terang/gelap menggunakan `setBool()` dan `getBool()`.

> Prinsip yang perlu diingat: Shared Preferences digunakan untuk data kecil dan sederhana. Ia menyimpan setiap value secara mandiri berdasarkan key. Jangan gunakan Shared Preferences untuk kata sandi atau data sensitif
