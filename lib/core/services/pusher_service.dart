import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../config/pusher_config.dart';
import '../config/api_config.dart';
import 'http_service.dart';
import '../di/injection.dart';
import 'token_service.dart';

class PusherService {
  static PusherChannelsFlutter? _pusher;
  static PusherChannel? _chatChannel;
  static HttpService? _httpService;
  
  // Callbacks para eventos de chat
  static Function(String message, String sender, String timestamp)? onMessageReceived;
  static Function(String user, String action)? onUserJoined;
  static Function(String user, String action)? onUserLeft;
  
  // Lista de mensagens em memória
  static final List<ChatMessage> _messages = [];
  
  static List<ChatMessage> get messages => List.unmodifiable(_messages);

  static Future<void> initialize({HttpService? httpService}) async {
    try {
      _pusher = PusherChannelsFlutter.getInstance();
      _httpService = httpService ?? HttpService(
        baseUrl: ApiConfig.baseUrl,
        tokenService: getIt<TokenService>(),
      );
      
      await _pusher!.init(
        apiKey: PusherConfig.clientAppKey,
        cluster: PusherConfig.clientCluster,
        onConnectionStateChange: (previousCurrent, current) {
          print('🟢 Pusher - Estado da conexão: $previousCurrent -> $current');
        },
        onError: (error, code, e) {
          print('🔴 Pusher - Erro: $error (código: $code)');
        },
        onSubscriptionSucceeded: (channelName, data) {
          print('🟢 Pusher - Canal inscrito: $channelName');
        },
        onSubscriptionError: (channelName, error) {
          print('🔴 Pusher - Erro na inscrição do canal: $channelName - $error');
        },
        onEvent: (event) {
          print('🟡 Pusher - Evento recebido: ${event.eventName} em ${event.channelName}');
          _handleEvent(event);
        },
      );

      await _pusher!.connect();
      print('🟢 Pusher - Conectado com sucesso');
      
    } catch (e) {
      print('🔴 Pusher - Erro na inicialização: $e');
      rethrow;
    }
  }

  static Future<void> subscribeToChatChannel(String channelName) async {
    try {
      if (_pusher == null) {
        await initialize();
      }
      
      _chatChannel = await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) {
          print('🟡 Pusher - Evento do canal de chat: ${event.eventName}');
          _handleChatEvent(event);
        },
      );
      
      print('🟢 Pusher - Inscrito no canal de chat: $channelName');
      
    } catch (e) {
      print('🔴 Pusher - Erro ao se inscrever no canal: $e');
      rethrow;
    }
  }

  static Future<void> sendMessage(String channelName, String message, String sender) async {
    try {
      if (_httpService == null) {
        throw Exception('Serviço HTTP não inicializado');
      }
      
      // Enviar mensagem via API Laravel
      final response = await _httpService!.post(
        '/chat/send',
        {
          'message': message,
          'sender': sender,
          'channel': channelName,
        },
      );
      
      print('🟢 Pusher - Mensagem enviada via API: $message');
      print('   Response: $response');
      
      // A mensagem será recebida via WebSocket do Pusher
      // e processada pelo callback onMessageReceived
      
    } catch (e) {
      print('🔴 Pusher - Erro ao enviar mensagem: $e');
      
      // Fallback: simular mensagem localmente se a API falhar
      _handleChatMessage(PusherEvent(
        channelName: channelName,
        eventName: 'chat-message',
        data: jsonEncode({
          'message': message,
          'sender': sender,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        userId: sender,
      ));
    }
  }

  static Future<void> joinChannel(String channelName, String user) async {
    try {
      if (_httpService == null) {
        throw Exception('Serviço HTTP não inicializado');
      }
      
      await _httpService!.post(
        '/chat/join',
        {
          'user': user,
          'channel': channelName,
        },
      );
      
      print('🟢 Pusher - Usuário entrou no canal: $user');
      
    } catch (e) {
      print('🔴 Pusher - Erro ao entrar no canal: $e');
    }
  }

  static Future<void> leaveChannel(String channelName, String user) async {
    try {
      if (_httpService == null) {
        throw Exception('Serviço HTTP não inicializado');
      }
      
      await _httpService!.post(
        '/chat/leave',
        {
          'user': user,
          'channel': channelName,
        },
      );
      
      print('🟢 Pusher - Usuário saiu do canal: $user');
      
    } catch (e) {
      print('🔴 Pusher - Erro ao sair do canal: $e');
    }
  }

  static void _handleEvent(PusherEvent event) {
    // Eventos gerais do Pusher
    print('🟡 Pusher - Evento geral: ${event.eventName}');
  }

  static void _handleChatEvent(PusherEvent event) {
    try {
      switch (event.eventName) {
        case 'chat-message':
          _handleChatMessage(event);
          break;
        case 'user-joined':
          _handleUserJoined(event);
          break;
        case 'user-left':
          _handleUserLeft(event);
          break;
        default:
          print('🟡 Pusher - Evento de chat não tratado: ${event.eventName}');
      }
    } catch (e) {
      print('🔴 Pusher - Erro ao processar evento de chat: $e');
    }
  }

  static void _handleChatMessage(PusherEvent event) {
    try {
      final data = jsonDecode(event.data);
      final message = ChatMessage(
        message: data['message'] ?? '',
        sender: data['sender'] ?? 'Unknown',
        timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
      );
      
      _messages.add(message);
      
      // Notificar listeners
      onMessageReceived?.call(
        message.message,
        message.sender,
        message.timestamp,
      );
      
      print('🟢 Pusher - Mensagem processada: ${message.message} de ${message.sender}');
      
    } catch (e) {
      print('🔴 Pusher - Erro ao processar mensagem: $e');
    }
  }

  static void _handleUserJoined(PusherEvent event) {
    try {
      final data = jsonDecode(event.data);
      final user = data['user'] ?? 'Unknown';
      
      onUserJoined?.call(user, 'joined');
      print('🟢 Pusher - Usuário entrou: $user');
      
    } catch (e) {
      print('🔴 Pusher - Erro ao processar usuário entrou: $e');
    }
  }

  static void _handleUserLeft(PusherEvent event) {
    try {
      final data = jsonDecode(event.data);
      final user = data['user'] ?? 'Unknown';
      
      onUserLeft?.call(user, 'left');
      print('🟢 Pusher - Usuário saiu: $user');
      
    } catch (e) {
      print('🔴 Pusher - Erro ao processar usuário saiu: $e');
    }
  }

  static Future<void> disconnect() async {
    try {
      if (_chatChannel != null) {
        await _pusher!.unsubscribe(channelName: _chatChannel!.channelName);
        _chatChannel = null;
      }
      
      if (_pusher != null) {
        await _pusher!.disconnect();
        _pusher = null;
      }
      
      _messages.clear();
      print('🟢 Pusher - Desconectado com sucesso');
      
    } catch (e) {
      print('🔴 Pusher - Erro ao desconectar: $e');
    }
  }

  static void clearMessages() {
    _messages.clear();
  }
}

class ChatMessage {
  final String message;
  final String sender;
  final String timestamp;

  ChatMessage({
    required this.message,
    required this.sender,
    required this.timestamp,
  });

  DateTime get dateTime => DateTime.parse(timestamp);

  @override
  String toString() {
    return 'ChatMessage(message: $message, sender: $sender, timestamp: $timestamp)';
  }
} 