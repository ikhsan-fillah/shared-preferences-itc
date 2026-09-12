import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../services/api_service.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    // Inject ApiService
    Get.lazyPut<ApiService>(() => ApiService());
    
    // Inject UserController dan masukkan (inject) ApiService ke dalamnya
    Get.lazyPut<UserController>(() => UserController(apiService: Get.find<ApiService>()));
  }
}
