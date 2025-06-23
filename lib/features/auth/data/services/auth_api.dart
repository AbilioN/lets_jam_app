import '../../../../core/services/http_service.dart';
import '../../../../core/config/api_config.dart';
import '../models/user_model.dart';

class AuthApi {
  final HttpService httpService;

  AuthApi({Map<String, String>? headers})
      : httpService = HttpService(
          baseUrl: ApiConfig.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            if (headers != null) ...headers,
          },
        );

  // Método para login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = {
      'email': email,
      'password': password,
    };
    
    try {
      final response = await httpService.post('/login', data);
      
      // Extrair usuário e token da resposta
      final userData = response['user'] as Map<String, dynamic>;
      final token = response['token'] as String;
      
      return {
        'user': UserModel.fromJson(userData),
        'token': token,
      };
    } catch (e) {
      throw Exception('Erro no login: $e');
    }
  }

  // Método para registro
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final data = {
      'name': name,
      'email': email,
      'password': password,
    };
    
    try {
      final response = await httpService.post('/register', data);
      
      // Extrair usuário e token da resposta (se disponível)
      final userData = response['user'] as Map<String, dynamic>;
      final token = response['token'] as String?;
      
      return {
        'user': UserModel.fromJson(userData),
        if (token != null) 'token': token,
      };
    } catch (e) {
      throw Exception('Erro no registro: $e');
    }
  }

  // Método para logout
  Future<void> logout() async {
    try {
      await httpService.post('/logout', {});
    } catch (e) {
      throw Exception('Erro no logout: $e');
    }
  }

  // Método para definir token de autorização
  void setAuthToken(String token) {
    httpService.setAuthToken(token);
  }

  // Método para remover token de autorização
  void removeAuthToken() {
    httpService.removeAuthToken();
  }
} 