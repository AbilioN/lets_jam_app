import 'dart:convert';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../config/api_config.dart';
import '../config/pusher_config.dart';
import 'http_service.dart';
import 'token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  static ChatService? _instance;
  static PusherChannelsFlutter? _pusher;
  static HttpService? _httpService;
  static TokenService? _tokenService;
  
  // Callbacks para eventos de chat
  static Function(ChatMessage message)? onMessageReceived;
  static Function(String error)? onError;
  
  // Lista de mensagens em memória
  static final List<ChatMessage> _messages = [];
  static final List<ChatConversation> _conversations = [];
  
  static List<ChatMessage> get messages => List.unmodifiable(_messages);
  static List<ChatConversation> get conversations => List.unmodifiable(_conversations);

  // Singleton pattern
  static ChatService get instance {
    _instance ??= ChatService._internal();
    return _instance!;
  }

  ChatService._internal();

  /// Inicializa o serviço de chat
  Future<void> initialize() async {
    try {
      print('🟡 ChatService - Inicializando...');
      
      // Inicializar serviços
      _httpService = HttpService(baseUrl: ApiConfig.baseUrl);
      
      // Inicializar TokenService com SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _tokenService = TokenServiceImpl(prefs);
      
      // Inicializar Pusher
      _pusher = PusherChannelsFlutter.getInstance();
      
      await _pusher!.init(
        apiKey: PusherConfig.clientAppKey,
        cluster: PusherConfig.clientCluster,
        onConnectionStateChange: (previousCurrent, current) {
          print('🟢 ChatService - Estado da conexão: $previousCurrent -> $current');
        },
        onError: (error, code, e) {
          print('🔴 ChatService - Erro do Pusher: $error (código: $code)');
          onError?.call('Erro do Pusher: $error');
        },
        onSubscriptionSucceeded: (channelName, data) {
          print('🟢 ChatService - Canal inscrito: $channelName');
        },
        onSubscriptionError: (channelName, error) {
          print('🔴 ChatService - Erro na inscrição do canal: $channelName - $error');
          onError?.call('Erro na inscrição do canal: $error');
        },
        onEvent: (event) {
          print('🟡 ChatService - Evento recebido: ${event.eventName} em ${event.channelName}');
          _handleEvent(event);
        },
      );

      await _pusher!.connect();
      print('🟢 ChatService - Inicializado com sucesso');
      
    } catch (e) {
      print('🔴 ChatService - Erro na inicialização: $e');
      onError?.call('Erro na inicialização: $e');
      rethrow;
    }
  }

  /// Escuta mensagens de uma conversa específica
  Future<void> listenToConversation(int currentUserId, int otherUserId) async {
    try {
      if (_pusher == null) {
        await initialize();
      }
      
      // Criar nome do canal conforme documentação
      final channelName = 'chat.${currentUserId < otherUserId ? currentUserId : otherUserId}-${currentUserId < otherUserId ? otherUserId : currentUserId}';
      
      print('🟡 ChatService - Escutando canal: $channelName');
      
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) {
          print('🟡 ChatService - Evento do canal: ${event.eventName}');
          _handleChatEvent(event);
        },
      );
      
      print('🟢 ChatService - Inscrito no canal de conversa: $channelName');
      
    } catch (e) {
      print('🔴 ChatService - Erro ao escutar conversa: $e');
      onError?.call('Erro ao escutar conversa: $e');
      rethrow;
    }
  }

  /// Envia uma mensagem
  Future<ChatMessage> sendMessage({
    required String content,
    required String receiverType,
    required int receiverId,
  }) async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Enviando mensagem...');
      print('   Content: $content');
      print('   Receiver Type: $receiverType');
      print('   Receiver ID: $receiverId');
      
      final response = await _httpService!.post(
        '/chat/send',
        {
          'content': content,
          'receiver_type': receiverType,
          'receiver_id': receiverId,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Mensagem enviada com sucesso');
      print('   Response: $response');
      
      final message = ChatMessage.fromApiResponse(response['message']);
      _messages.add(message);
      
      return message;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao enviar mensagem: $e');
      onError?.call('Erro ao enviar mensagem: $e');
      rethrow;
    }
  }

  /// Busca conversa com outro usuário
  Future<List<ChatMessage>> getConversation({
    required String otherUserType,
    required int otherUserId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Buscando conversa...');
      print('   Other User Type: $otherUserType');
      print('   Other User ID: $otherUserId');
      print('   Page: $page');
      print('   Per Page: $perPage');
      
      final response = await _httpService!.get(
        '/chat/conversation?other_user_type=$otherUserType&other_user_id=$otherUserId&page=$page&per_page=$perPage',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Conversa carregada com sucesso');
      print('   Response: $response');
      
      final messages = (response['messages'] as List)
          .map((msg) => ChatMessage.fromApiResponse(msg))
          .toList();
      
      // Limpar mensagens antigas e adicionar as novas
      _messages.clear();
      _messages.addAll(messages);
      
      return messages;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao buscar conversa: $e');
      onError?.call('Erro ao buscar conversa: $e');
      rethrow;
    }
  }

  /// Lista todas as conversas
  Future<List<ChatConversation>> getConversations() async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Buscando conversas...');
      
      final response = await _httpService!.get(
        '/chat/conversations',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Conversas carregadas com sucesso');
      print('   Response: $response');
      
      final conversations = (response['conversations'] as List)
          .map((conv) => ChatConversation.fromApiResponse(conv))
          .toList();
      
      _conversations.clear();
      _conversations.addAll(conversations);
      
      return conversations;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao buscar conversas: $e');
      onError?.call('Erro ao buscar conversas: $e');
      rethrow;
    }
  }

  /// Admin: Envia mensagem para usuário
  Future<ChatMessage> adminSendMessage({
    required String content,
    required int userId,
  }) async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Admin enviando mensagem...');
      print('   Content: $content');
      print('   User ID: $userId');
      
      final response = await _httpService!.post(
        '/admin/chat/send',
        {
          'content': content,
          'user_id': userId,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Mensagem de admin enviada com sucesso');
      print('   Response: $response');
      
      final message = ChatMessage.fromApiResponse(response['message']);
      _messages.add(message);
      
      return message;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao enviar mensagem de admin: $e');
      onError?.call('Erro ao enviar mensagem de admin: $e');
      rethrow;
    }
  }

  /// Admin: Busca conversa com usuário
  Future<List<ChatMessage>> adminGetConversation({
    required int userId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Admin buscando conversa...');
      print('   User ID: $userId');
      print('   Page: $page');
      print('   Per Page: $perPage');
      
      final response = await _httpService!.get(
        '/admin/chat/conversation?user_id=$userId&page=$page&per_page=$perPage',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Conversa de admin carregada com sucesso');
      print('   Response: $response');
      
      final messages = (response['messages'] as List)
          .map((msg) => ChatMessage.fromApiResponse(msg))
          .toList();
      
      _messages.clear();
      _messages.addAll(messages);
      
      return messages;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao buscar conversa de admin: $e');
      onError?.call('Erro ao buscar conversa de admin: $e');
      rethrow;
    }
  }

  /// Admin: Lista conversas
  Future<List<ChatConversation>> adminGetConversations() async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Admin buscando conversas...');
      
      final response = await _httpService!.get(
        '/admin/chat/conversations',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Conversas de admin carregadas com sucesso');
      print('   Response: $response');
      
      final conversations = (response['conversations'] as List)
          .map((conv) => ChatConversation.fromApiResponse(conv))
          .toList();
      
      _conversations.clear();
      _conversations.addAll(conversations);
      
      return conversations;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao buscar conversas de admin: $e');
      onError?.call('Erro ao buscar conversas de admin: $e');
      rethrow;
    }
  }

  void _handleEvent(PusherEvent event) {
    // Eventos gerais do Pusher
    print('🟡 ChatService - Evento geral: ${event.eventName}');
  }

  void _handleChatEvent(PusherEvent event) {
    try {
      switch (event.eventName) {
        case 'MessageSent':
          _handleMessageSent(event);
          break;
        default:
          print('🟡 ChatService - Evento de chat não tratado: ${event.eventName}');
      }
    } catch (e) {
      print('🔴 ChatService - Erro ao processar evento de chat: $e');
      onError?.call('Erro ao processar evento de chat: $e');
    }
  }

  void _handleMessageSent(PusherEvent event) {
    try {
      final data = jsonDecode(event.data);
      final message = ChatMessage.fromApiResponse(data['message']);
      
      _messages.add(message);
      
      // Notificar listeners
      onMessageReceived?.call(message);
      
      print('🟢 ChatService - Mensagem recebida: ${message.content} de ${message.senderName}');
      
    } catch (e) {
      print('🔴 ChatService - Erro ao processar mensagem: $e');
      onError?.call('Erro ao processar mensagem: $e');
    }
  }

  /// Desconecta do chat
  Future<void> disconnect() async {
    try {
      if (_pusher != null) {
        await _pusher!.disconnect();
        _pusher = null;
      }
      
      _messages.clear();
      _conversations.clear();
      print('🟢 ChatService - Desconectado com sucesso');
      
    } catch (e) {
      print('🔴 ChatService - Erro ao desconectar: $e');
      onError?.call('Erro ao desconectar: $e');
    }
  }

  /// Limpa mensagens em memória
  void clearMessages() {
    _messages.clear();
  }

  /// Limpa conversas em memória
  void clearConversations() {
    _conversations.clear();
  }
}

/// Modelo de mensagem de chat
class ChatMessage {
  final int id;
  final String content;
  final String senderType;
  final int senderId;
  final String senderName;
  final String receiverType;
  final int receiverId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderType,
    required this.senderId,
    required this.senderName,
    required this.receiverType,
    required this.receiverId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromApiResponse(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      content: json['content'] as String,
      senderType: json['sender_type'] as String,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String,
      receiverType: json['receiver_type'] as String,
      receiverId: json['receiver_id'] as int,
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, sender: $senderName, createdAt: $createdAt)';
  }
}

/// Modelo de conversa
class ChatConversation {
  final int otherUserId;
  final String otherUserType;
  final DateTime? lastMessageAt;
  final int messageCount;
  final int unreadCount;

  ChatConversation({
    required this.otherUserId,
    required this.otherUserType,
    this.lastMessageAt,
    required this.messageCount,
    required this.unreadCount,
  });

  factory ChatConversation.fromApiResponse(Map<String, dynamic> json) {
    return ChatConversation(
      otherUserId: json['other_user_id'] as int,
      otherUserType: json['other_user_type'] as String,
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at'] as String) 
          : null,
      messageCount: json['message_count'] as int,
      unreadCount: json['unread_count'] as int,
    );
  }

  @override
  String toString() {
    return 'ChatConversation(otherUserId: $otherUserId, otherUserType: $otherUserType, messageCount: $messageCount, unreadCount: $unreadCount)';
  }
} 