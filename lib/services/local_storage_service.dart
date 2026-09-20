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

    if (id == null || name == null || email == null) return null;
    return User(id: id, name: name, email: email);
  }

  Future<void> removeLastSelectedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
  }
}
