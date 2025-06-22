import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> cacheUser(UserModel user) async {
    await sharedPreferences.setString('CACHED_USER', user.toJson().toString());
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString('CACHED_USER');
    if (jsonString != null) {
      // Parse JSON string back to Map and create UserModel
      // This is a simplified version - in real app you'd use proper JSON parsing
      return null; // Placeholder
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove('CACHED_USER');
  }
} 