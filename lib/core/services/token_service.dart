import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenService {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<bool> hasToken();
}

class TokenServiceImpl implements TokenService {
  static const String _tokenKey = 'auth_token';
  final SharedPreferences _prefs;

  TokenServiceImpl(this._prefs);

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  @override
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
} 