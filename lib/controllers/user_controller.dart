import 'package:get/get.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class UserController extends GetxController {
  final ApiService apiService;
  final LocalStorageService _localStorageService = LocalStorageService();

  UserController({required this.apiService});

  final List<User> users = [];
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
      users.assignAll(await apiService.getUsers());
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
