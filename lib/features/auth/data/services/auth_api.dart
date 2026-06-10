import '../../../../core/services/http_service.dart';

class AuthApi {
  final HttpService _httpService;

  AuthApi(this._httpService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🟡 AuthApi - Iniciando login...');
      print('   Email: $email');
      print('   Password: $password');
      print('   Endpoint: /login');
      
      final response = await _httpService.post(
        '/login',
        {
          'email': email,
          'password': password,
        },
      );

      print('🟡 AuthApi - Resposta recebida:');
      print('   Response: $response');
      print('   Response type: ${response.runtimeType}');
      print('   Response keys: ${response is Map ? response.keys.toList() : 'N/A'}');

      // A API Laravel retorna diretamente os dados sem campo 'success'
      // Verificar se temos user e token na resposta
      if (response is Map<String, dynamic> && 
          response.containsKey('user') && 
          response.containsKey('token')) {
        print('🟢 AuthApi - Login bem-sucedido');
        print('   User: ${response['user']}');
        print('   Token: ${response['token']}');
        return {
          'user': response['user'],
          'token': response['token'],
        };
      } else {
        print('🔴 AuthApi - Login falhou - formato de resposta inválido');
        String errorMessage = 'Erro no login';
        
        if (response is Map<String, dynamic>) {
          if (response.containsKey('message')) {
            errorMessage = response['message'] as String;
          } else if (response.containsKey('error')) {
            errorMessage = response['error'] as String;
          }
        } else if (response is String) {
          errorMessage = response;
        }
        
        print('   Error message: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('🔴 AuthApi - Erro no login: $e');
      print('🔴 AuthApi - Tipo do erro: ${e.runtimeType}');
      rethrow;
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

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _httpService.post('/forgot-password', {'email': email});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _httpService.post('/reset-password', {
      'token': token,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _httpService.get('/user/me');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(String name) async {
    final response = await _httpService.patch('/user/me', {'name': name});
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await _httpService.patch('/user/password', {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPasswordConfirmation,
    });
    return response as Map<String, dynamic>;
  }
} 