import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../models/user.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Mencari controller yang sudah di-inject oleh UserBinding
    final UserController userController = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Networking App with GetX DI'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<User>>(
        // Memanggil method fetchUsers()
        future: userController.fetchUsers(),
        builder: (context, snapshot) {
          // Jika proses sedang berlangsung (loading)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // Jika terjadi error
          else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } 
          // Jika tidak ada data
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data user.'));
          } 
          // Jika berhasil dan data tersedia
          else {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(user.id.toString()),
                    ),
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
