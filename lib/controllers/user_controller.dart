import 'package:get/get.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserController extends GetxController {
  // Dependency Injection: Menerima ApiService melalui constructor
  final ApiService apiService;

  UserController({required this.apiService});

  // Method untuk mengambil data dari API Service
  Future<List<User>> fetchUsers() {
    return apiService.getUsers();
  }
}
