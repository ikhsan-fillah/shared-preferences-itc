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
