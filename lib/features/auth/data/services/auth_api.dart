import '../../../../core/config/api_config.dart';
import '../../../../core/services/http_service.dart';

class AuthApi {
  late final HttpService _httpService;

  AuthApi() {
    _httpService = HttpService(baseUrl: ApiConfig.baseUrl);
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

  Future<Map<String, dynamic>> register(String name, String email, String password, String passwordConfirmation) async {
    final response = await _httpService.post(
      '/register',
      {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    // A API retorna 201 para sucesso no registro
    // Não há campo 'success' na resposta, apenas 'message' e 'user'
    return response;
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final response = await _httpService.post(
      '/verify-email',
      {
        'email': email,
        'code': code,
      },
    );

    return response;
  }

  Future<void> logout() async {
    await _httpService.post('/auth/logout', {});
  }
} 