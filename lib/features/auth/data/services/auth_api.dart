import '../../../../core/config/api_config.dart';
import '../../../../core/services/http_service.dart';

class AuthApi {
  late final HttpService _httpService;
  String? _authToken;

  AuthApi() {
    _httpService = HttpService(baseUrl: ApiConfig.baseUrl);
  }

  void setAuthToken(String token) {
    _authToken = token;
    _httpService.setAuthToken(token);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _httpService.post(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
    );

    if (response['success'] == true) {
      return {
        'user': response['user'],
        'token': response['token'],
      };
    } else {
      throw Exception(response['message'] ?? 'Erro no login');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _httpService.post(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    if (response['success'] == true) {
      return {
        'user': response['user'],
        'token': response['token'],
      };
    } else {
      throw Exception(response['message'] ?? 'Erro no registro');
    }
  }

  Future<void> logout() async {
    await _httpService.post('/auth/logout', {});
  }

  void removeAuthToken() {
    _authToken = null;
    _httpService.removeAuthToken();
  }
} 