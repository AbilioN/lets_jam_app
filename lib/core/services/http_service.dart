import 'package:dio/dio.dart';

class HttpService {
  final Dio _dio;
  final String baseUrl;

  HttpService({
    required this.baseUrl,
    Map<String, String>? headers,
  }) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
    
    // Configurar timeouts
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.sendTimeout = const Duration(seconds: 10);
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<dynamic> delete(String endpoint, [dynamic data]) async {
    try {
      final response = await _dio.delete(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  void _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final errorData = e.response!.data;
      
      switch (statusCode) {
        case 401:
          throw Exception('Credenciais inválidas');
        case 422:
          final errors = errorData['errors'] as Map<String, dynamic>?;
          if (errors != null) {
            final errorMessages = errors.values
                .expand((error) => error as List)
                .join(', ');
            throw Exception('Erro de validação: $errorMessages');
          } else {
            throw Exception(errorData['message'] ?? 'Erro de validação');
          }
        case 500:
          throw Exception('Erro interno do servidor');
        default:
          throw Exception(errorData['message'] ?? 'Erro desconhecido');
      }
    } else {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Timeout de conexão - verifique se a API está rodando');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erro de conexão - verifique a URL da API e se está acessível');
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    }
  }

  // Método para adicionar token de autorização
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Método para remover token de autorização
  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
} 