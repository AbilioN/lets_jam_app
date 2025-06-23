import '../../../../core/services/token_service.dart';
import '../models/user_model.dart';
import '../services/auth_api.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthApi authApi;
  final TokenService tokenService;

  AuthRemoteDataSourceImpl(this.tokenService)
      : authApi = AuthApi();

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final result = await authApi.login(email, password);
      
      final user = result['user'] as UserModel;
      final token = result['token'] as String;
      
      // Salvar o token
      await tokenService.saveToken(token);
      
      return user;
    } catch (e) {
      throw Exception('Erro no login: $e');
    }
  }

  @override
  Future<UserModel> register(String email, String password, String name) async {
    try {
      final result = await authApi.register(name, email, password);
      
      final user = result['user'] as UserModel;
      
      // Salvar token se fornecido
      if (result.containsKey('token')) {
        final token = result['token'] as String;
        await tokenService.saveToken(token);
      }
      
      return user;
    } catch (e) {
      throw Exception('Erro no registro: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Adicionar token de autorização se disponível
      final token = await tokenService.getToken();
      if (token != null) {
        authApi.setAuthToken(token);
      }
      
      await authApi.logout();
      
      // Limpar token após logout
      await tokenService.clearToken();
    } catch (e) {
      throw Exception('Erro no logout: $e');
    }
  }
} 