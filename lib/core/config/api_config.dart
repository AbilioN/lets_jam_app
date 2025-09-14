import 'package:flutter/foundation.dart';

class ApiConfig {
  // URLs base para diferentes ambientes
  static const String _localhost = 'http://10.0.2.2:8006/api';
  static const String _androidEmulator = 'http://10.0.2.2:8006/api';
  static const String _iosSimulator = 'http://localhost:8006/api';
  
  // Para dispositivo físico, você precisa usar o IP da sua máquina na rede local
  // Exemplo: 'http://192.168.1.100:8006/api'
  static const String _physicalDevice = 'http://localhost:8006/api'; // IP da sua máquina
  
  static String get baseUrl {
    if (kDebugMode) {
      // Em modo debug, detectar automaticamente o ambiente
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _androidEmulator;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return _iosSimulator;
      } else {
        return _localhost;
      }
    } else {
      // Em produção, usar URL de produção
      return _physicalDevice;
    }
  }
  
  // Método para forçar uma URL específica (útil para testes)
  static String getUrlForEnvironment(String environment) {
    switch (environment.toLowerCase()) {
      case 'android':
        return _androidEmulator;
      case 'ios':
        return _iosSimulator;
      case 'localhost':
        return _localhost;
      case 'physical':
        return _physicalDevice;
      default:
        return baseUrl;
    }
  }
  
  // Configurações de timeout
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);
} 