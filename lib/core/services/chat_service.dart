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
  static final List<Chat> _chats = [];
  
  static List<ChatMessage> get messages => List.unmodifiable(_messages);
  static List<Chat> get chats => List.unmodifiable(_chats);

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

  /// Escuta mensagens de um chat específico
  Future<void> listenToChat(int chatId) async {
    try {
      if (_pusher == null) {
        await initialize();
      }
      
      // Criar nome do canal conforme nova documentação
      final channelName = 'chat.$chatId';
      
      print('🟡 ChatService - Escutando canal: $channelName');
      
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) {
          print('🟡 ChatService - Evento do canal: ${event.eventName}');
          _handleChatEvent(event);
        },
      );
      
      print('🟢 ChatService - Inscrito no canal de chat: $channelName');
      
    } catch (e) {
      print('🔴 ChatService - Erro ao escutar chat: $e');
      onError?.call('Erro ao escutar chat: $e');
      rethrow;
    }
  }

  /// Cria um chat privado entre dois usuários
  Future<Chat> createPrivateChat({
    required int otherUserId,
    required String otherUserType,
  }) async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Criando chat privado...');
      print('   Other User ID: $otherUserId');
      print('   Other User Type: $otherUserType');
      
      final response = await _httpService!.post(
        '/chat/create-private',
        {
          'other_user_id': otherUserId,
          'other_user_type': otherUserType,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Chat privado criado com sucesso');
      print('   Response: $response');
      
      final chat = Chat.fromApiResponse(response['data']['chat']);
      
      // Adicionar à lista de chats se não existir
      if (!_chats.any((c) => c.id == chat.id)) {
        _chats.add(chat);
      }
      
      return chat;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao criar chat privado: $e');
      onError?.call('Erro ao criar chat privado: $e');
      rethrow;
    }
  }

  /// Cria um chat em grupo
  Future<Chat> createGroupChat({
    required String name,
    required String description,
    required List<ChatParticipant> participants,
  }) async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Criando chat em grupo...');
      print('   Name: $name');
      print('   Description: $description');
      print('   Participants: ${participants.length}');
      
      final response = await _httpService!.post(
        '/chat/create-group',
        {
          'name': name,
          'description': description,
          'participants': participants.map((p) => {
            'user_id': p.userId,
            'user_type': p.userType,
          }).toList(),
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Chat em grupo criado com sucesso');
      print('   Response: $response');
      
      final chat = Chat.fromApiResponse(response['data']['chat']);
      
      // Adicionar à lista de chats se não existir
      if (!_chats.any((c) => c.id == chat.id)) {
        _chats.add(chat);
      }
      
      return chat;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao criar chat em grupo: $e');
      onError?.call('Erro ao criar chat em grupo: $e');
      rethrow;
    }
  }

  /// Envia uma mensagem para outro usuário (cria/usa chat privado)
  Future<ChatMessage> sendMessageToUser({
    required String content,
    required int otherUserId,
    required String otherUserType,
  }) async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Enviando mensagem para usuário...');
      print('   Content: $content');
      print('   Other User ID: $otherUserId');
      print('   Other User Type: $otherUserType');
      
      final response = await _httpService!.post(
        '/chat/send',
        {
          'content': content,
          'other_user_id': otherUserId,
          'other_user_type': otherUserType,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Mensagem enviada com sucesso');
      print('   Response: $response');
      
      final message = ChatMessage.fromApiResponse(response['data']['message']);
      final chat = Chat.fromApiResponse(response['data']['chat']);
      
      // Adicionar mensagem e chat
      _messages.add(message);
      if (!_chats.any((c) => c.id == chat.id)) {
        _chats.add(chat);
      }
      
      return message;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao enviar mensagem: $e');
      onError?.call('Erro ao enviar mensagem: $e');
      rethrow;
    }
  }

  /// Envia uma mensagem para um chat específico
  Future<ChatMessage> sendMessageToChat({
    required int chatId,
    required String content,
  }) async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Enviando mensagem para chat...');
      print('   Chat ID: $chatId');
      print('   Content: $content');
      
      final response = await _httpService!.post(
        '/chat/$chatId/send',
        {
          'content': content,
        },
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Mensagem enviada com sucesso');
      print('   Response: $response');
      
      final message = ChatMessage.fromApiResponse(response['data']['message']);
      _messages.add(message);
      
      return message;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao enviar mensagem para chat: $e');
      onError?.call('Erro ao enviar mensagem para chat: $e');
      rethrow;
    }
  }

  /// Busca conversa privada entre dois usuários
  Future<ChatConversation> getConversation({
    required int otherUserId,
    required String otherUserType,
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
      print('   Other User ID: $otherUserId');
      print('   Other User Type: $otherUserType');
      print('   Page: $page');
      print('   Per Page: $perPage');
      
      final response = await _httpService!.get(
        '/chat/conversation/$otherUserId/$otherUserType?page=$page&per_page=$perPage',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Conversa carregada com sucesso');
      print('   Response: $response');
      
      final chat = Chat.fromApiResponse(response['data']['chat']);
      final messages = (response['data']['messages'] as List)
          .map((msg) => ChatMessage.fromApiResponse(msg))
          .toList();
      
      // Limpar mensagens antigas e adicionar as novas
      _messages.clear();
      _messages.addAll(messages);
      
      // Adicionar chat se não existir
      if (!_chats.any((c) => c.id == chat.id)) {
        _chats.add(chat);
      }
      
      return ChatConversation(
        chat: chat,
        messages: messages,
        pagination: ChatPagination.fromApiResponse(response['data']['pagination']),
      );
      
    } catch (e) {
      print('🔴 ChatService - Erro ao buscar conversa: $e');
      onError?.call('Erro ao buscar conversa: $e');
      rethrow;
    }
  }

  /// Lista todos os chats do usuário
  Future<List<Chat>> getChats({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      if (_httpService == null || _tokenService == null) {
        throw Exception('ChatService não inicializado');
      }
      
      final token = await _tokenService!.getToken();
      if (token == null) {
        throw Exception('Token não encontrado');
      }
      
      print('🟡 ChatService - Buscando chats...');
      print('   Page: $page');
      print('   Per Page: $perPage');
      
      final response = await _httpService!.get(
        '/chat/conversations?page=$page&per_page=$perPage',
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('🟢 ChatService - Chats carregados com sucesso');
      print('   Response: $response');
      
      final chats = (response['data']['chats'] as List)
          .map((chat) => Chat.fromApiResponse(chat))
          .toList();
      
      _chats.clear();
      _chats.addAll(chats);
      
      return chats;
      
    } catch (e) {
      print('🔴 ChatService - Erro ao buscar chats: $e');
      onError?.call('Erro ao buscar chats: $e');
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
      final message = ChatMessage.fromApiResponse(jsonDecode(event.data));
      
      _messages.add(message);
      
      // Notificar listeners
      onMessageReceived?.call(message);
      
      print('🟢 ChatService - Mensagem recebida: ${message.content} no chat ${message.chatId}');
      
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
      _chats.clear();
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

  /// Limpa chats em memória
  void clearChats() {
    _chats.clear();
  }
}

/// Modelo de mensagem de chat
class ChatMessage {
  final int id;
  final int chatId;
  final String content;
  final String senderType;
  final int senderId;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.content,
    required this.senderType,
    required this.senderId,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromApiResponse(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      chatId: json['chat_id'] as int,
      content: json['content'] as String,
      senderType: json['sender_type'] as String,
      senderId: json['sender_id'] as int,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, chatId: $chatId, content: $content, sender: $senderType, createdAt: $createdAt)';
  }
}

/// Modelo de chat
class Chat {
  final int id;
  final String type; // 'private' ou 'group'
  final String name;
  final String description;
  final List<ChatParticipant>? participants;
  final ChatLastMessage? lastMessage;
  final int? unreadCount;

  Chat({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    this.participants,
    this.lastMessage,
    this.unreadCount,
  });

  factory Chat.fromApiResponse(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as int,
      type: json['type'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => ChatParticipant.fromApiResponse(p))
              .toList()
          : null,
      lastMessage: json['last_message'] != null
          ? ChatLastMessage.fromApiResponse(json['last_message'])
          : null,
      unreadCount: json['unread_count'] as int?,
    );
  }

  @override
  String toString() {
    return 'Chat(id: $id, type: $type, name: $name, unreadCount: $unreadCount)';
  }
}

/// Modelo de participante do chat
class ChatParticipant {
  final int userId;
  final String userType;

  ChatParticipant({
    required this.userId,
    required this.userType,
  });

  factory ChatParticipant.fromApiResponse(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['user_id'] as int,
      userType: json['user_type'] as String,
    );
  }

  @override
  String toString() {
    return 'ChatParticipant(userId: $userId, userType: $userType)';
  }
}

/// Modelo de última mensagem do chat
class ChatLastMessage {
  final int id;
  final String content;
  final DateTime createdAt;

  ChatLastMessage({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  factory ChatLastMessage.fromApiResponse(Map<String, dynamic> json) {
    return ChatLastMessage(
      id: json['id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'ChatLastMessage(id: $id, content: $content, createdAt: $createdAt)';
  }
}

/// Modelo de conversa com chat e mensagens
class ChatConversation {
  final Chat chat;
  final List<ChatMessage> messages;
  final ChatPagination pagination;

  ChatConversation({
    required this.chat,
    required this.messages,
    required this.pagination,
  });

  @override
  String toString() {
    return 'ChatConversation(chat: $chat, messages: ${messages.length}, pagination: $pagination)';
  }
}

/// Modelo de paginação
class ChatPagination {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final int from;
  final int to;

  ChatPagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory ChatPagination.fromApiResponse(Map<String, dynamic> json) {
    return ChatPagination(
      currentPage: json['current_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
      lastPage: json['last_page'] as int,
      from: json['from'] as int,
      to: json['to'] as int,
    );
  }

  @override
  String toString() {
    return 'ChatPagination(currentPage: $currentPage, total: $total, lastPage: $lastPage)';
  }
} 