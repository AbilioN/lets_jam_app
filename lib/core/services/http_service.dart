import 'package:dio/dio.dart';
import 'dart:convert';

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
      'Accept': 'application/json',
      if (headers != null) ...headers,
    };
    
    // Configurar timeouts
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.sendTimeout = const Duration(seconds: 10);
    
    // Adicionar interceptor para garantir headers
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🔵 Interceptor - Headers sendo enviados: ${options.headers}');
        // Garantir que os headers estejam presentes
        options.headers['Content-Type'] = 'application/json';
        options.headers['Accept'] = 'application/json';
        handler.next(options);
      },
    ));
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      print('🔵 HttpService - Enviando GET para: ${_dio.options.baseUrl}$endpoint');
      print('🔵 HttpService - Custom Headers: $headers');
      
      // Combinar headers padrão com headers customizados
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (headers != null) ...headers,
      };
      
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: requestHeaders,
        ),
      );
      
      print('🔵 HttpService - Resposta recebida:');
      print('   Status Code: ${response.statusCode}');
      print('   Data: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      print('🔵 HttpService - Enviando POST para: ${_dio.options.baseUrl}$endpoint');
      print('🔵 HttpService - Headers: ${_dio.options.headers}');
      print('🔵 HttpService - Custom Headers: $headers');
      print('🔵 HttpService - Data: $data');
      
      // Combinar headers padrão com headers customizados
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (headers != null) ...headers,
      };
      
      final response = await _dio.post(
        endpoint, 
        data: data,
        options: Options(
          headers: requestHeaders,
        ),
      );
      
      print('🔵 HttpService - Resposta recebida:');
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Data: ${response.data}');
      print('   Data type: ${response.data.runtimeType}');
      
      return response.data;
    } on DioException catch (e) {
      print('🔴 HttpService - DioException capturada:');
      print('   Type: ${e.type}');
      print('   Message: ${e.message}');
      print('   Error: ${e.error}');
      _handleDioError(e);
    } catch (e) {
      print('🔴 HttpService - Erro inesperado: $e');
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
      dynamic errorData = e.response!.data;
      print('🔴 DioError status: $statusCode');
      print('🔴 DioError data: $errorData (${errorData.runtimeType})');
      // Se errorData vier como String, tenta decodificar
      if (errorData is String) {
        try {
          errorData = json.decode(errorData);
        } catch (_) {
          // Se não for JSON, mantém como string
        }
      }
      
      switch (statusCode) {
        case 401:
          throw Exception('Credenciais inválidas');
        case 422:
          // Extrair mensagem do campo "message" primeiro
          String errorMessage = 'Erro de validação';
          
          if (errorData is Map<String, dynamic>) {
            // Tentar extrair a mensagem principal
            if (errorData.containsKey('message')) {
              errorMessage = errorData['message'] as String;
            }
            
            // Se há erros específicos, adicionar os detalhes
            if (errorData.containsKey('errors') && errorData['errors'] is Map<String, dynamic>) {
              final errors = errorData['errors'] as Map<String, dynamic>;
              final errorDetails = errors.values
                  .expand((error) => error is List ? error : [error])
                  .whereType<String>()
                  .join(', ');
              
              if (errorDetails.isNotEmpty) {
                errorMessage = '$errorMessage: $errorDetails';
              }
            }
          } else if (errorData is String) {
            errorMessage = errorData;
          }
          
          throw Exception(errorMessage);
        case 500:
          throw Exception('Erro interno do servidor');
        default:
          // Para outros códigos de erro, tentar extrair a mensagem
          String errorMessage = 'Erro desconhecido';
          if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
            errorMessage = errorData['message'] as String;
          } else if (errorData is String) {
            errorMessage = errorData;
          }
          throw Exception(errorMessage);
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