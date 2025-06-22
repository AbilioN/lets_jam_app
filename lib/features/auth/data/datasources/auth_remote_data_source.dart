import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception('Login failed: ${e.message}');
    }
  }

  @override
  Future<UserModel> register(String email, String password, String name) async {
    try {
      final response = await dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } on DioException catch (e) {
      throw Exception('Logout failed: ${e.message}');
    }
  }
} 