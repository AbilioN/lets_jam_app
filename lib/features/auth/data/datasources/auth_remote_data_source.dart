import 'package:dio/dio.dart';

import '../../../../core/services/token_service.dart';
import '../../../../core/services/http_service.dart';
import '../models/user_model.dart';
import '../services/auth_api.dart';
import 'dart:convert';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password, String passwordConfirmation);
  Future<Map<String, String>> verifyEmail(String email, String code);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthApi authApi;
  final TokenService tokenService;

  AuthRemoteDataSourceImpl(this.tokenService, this.authApi);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      print('🟡 AuthRemoteDataSource - Iniciando login...');
      print('   Email: $email');
      print('   Password: $password');
      
      final result = await authApi.login(email, password);
      
      print('🟡 AuthRemoteDataSource - Resultado da API:');
      print('   Result: $result');
      print('   Keys disponíveis: ${result.keys.toList()}');
      
      final user = UserModel.fromApiResponse(result);
      final token = result['token'] as String;
      
      print('🟡 AuthRemoteDataSource - Dados extraídos:');
      print('   User: $user');
      print('   Token: ${token.substring(0, 20)}...');
      
      // Salvar o token
      await tokenService.saveToken(token);
      print('🟢 AuthRemoteDataSource - Token salvo com sucesso');
      
      return user;
    } catch (e) {
      print('🔴 AuthRemoteDataSource - Erro no login: $e');
      print('🔴 AuthRemoteDataSource - Tipo do erro: ${e.runtimeType}');
      if (e is DioException) {
        _handleDioError(e);
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      print('🟡 AuthRemoteDataSource - Iniciando registro...');
      
      final result = await authApi.register(name, email, password, passwordConfirmation);
      
      print('🟡 AuthRemoteDataSource - Resultado da API:');
      print('   Result: $result');
      print('   Keys disponíveis: ${result.keys.toList()}');
      
      // Extrair o usuário da resposta usando o método estático
      final user = UserModel.fromApiResponse(result);
      
      print('🟡 AuthRemoteDataSource - Usuário extraído:');
      print('   User ID: ${user.id}');
      print('   User Name: ${user.name}');
      print('   User Email: ${user.email}');
      
      // Para registro, não há token na resposta inicial
      // O usuário precisa verificar o email primeiro
      
      return user;
    } catch (e) {
      print('🔴 AuthRemoteDataSource - Erro no registro: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Adicionar token de autorização se disponível
      // final token = await tokenService.getToken();
      // if (token != null) {
      //   authApi.setAuthToken(token);
      // }
      
      await authApi.logout();
      
      // Limpar token após logout
      await tokenService.clearToken();
    } catch (e) {
      throw Exception('Erro no logout: $e');
    }
  }

  @override
  Future<Map<String, String>> verifyEmail(String email, String code) async {
    try {
      final result = await authApi.verifyEmail(email, code);
      
      return {
        'message': result['message'] as String,
        'email': result['email'] as String,
      };
    } catch (e) {
      throw Exception('Erro na verificação de email: $e');
    }
  }

  void _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final errorData = e.response!.data;
      print('🔴 DioError status: $statusCode');
      print('🔴 DioError data: $errorData (${errorData.runtimeType})');
      // ... resto do código
    }
  }
} 