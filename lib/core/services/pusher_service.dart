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
  
  // Callbacks específicos para chat
  static Function(ChatMessage message)? onChatMessageReceived;
  static Function(String chatId, String eventType, dynamic data)? onChatEvent;
  
  // Lista de mensagens em memória
  static final List<ChatMessage> _messages = [];
  
  static List<ChatMessage> get messages => List.unmodifiable(_messages);
  
  // Map para armazenar canais de chat ativos
  static final Map<String, PusherChannel> _chatChannels = {};

  static Future<void> initialize({HttpService? httpService}) async {
    try {
      print('🟡 Pusher - Iniciando inicialização...');
      print('🟡 Pusher - AppKey: ${PusherConfig.clientAppKey}');
      print('🟡 Pusher - Cluster: ${PusherConfig.clientCluster}');
      print('🟡 Pusher - Host: ${PusherConfig.clientHost}');
      print('🟡 Pusher - Port: ${PusherConfig.clientPort}');
      print('🟡 Pusher - Scheme: ${PusherConfig.clientScheme}');
      
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
          print('🔴 Pusher - Detalhes do erro: $e');
        },
        onSubscriptionSucceeded: (channelName, data) {
          print('🟢 Pusher - Canal inscrito: $channelName');
          print('🟢 Pusher - Dados da inscrição: $data');
          print('🟢 Pusher - Verificando se é um canal de chat...');
          
          // Verificar se é um canal de chat
          if (channelName.startsWith('chat.')) {
            final chatId = channelName.replaceFirst('chat.', '');
            print('🟢 Pusher - Canal de chat detectado: $channelName (ID: $chatId)');
            
            // Verificar se já está na lista de canais
            if (_chatChannels.containsKey(channelName)) {
              print('🟢 Pusher - Canal já está na lista de canais ativos');
            } else {
              print('🟡 Pusher - Canal não está na lista de canais ativos - pode ser um problema');
            }
          } else {
            print('🟡 Pusher - Canal não é de chat: $channelName');
          }
        },
        onSubscriptionError: (channelName, error) {
          print('🔴 Pusher - Erro na inscrição do canal: $channelName - $error');
        },
        onEvent: (event) {
          print('🟡 Pusher - Evento recebido: ${event.eventName} em ${event.channelName}');
          print('🟡 Pusher - Dados do evento: ${event.data}');
          _handleEvent(event);
        },
      );

      print('🟡 Pusher - Tentando conectar...');
      await _pusher!.connect();
      print('🟢 Pusher - Conectado com sucesso');
      
    } catch (e) {
      print('🔴 Pusher - Erro na inicialização: $e');
      print('🔴 Pusher - Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static Future<void> subscribeToChatChannel(String channelName) async {
    try {
      print("subscribing to chat channel222");
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

  /// Inscreve em um canal de chat específico usando o formato chat.{chatId}
  static Future<void> subscribeToChat(int chatId) async {
    try {
      print('🟡 Pusher - Tentando inscrever no chat $chatId...');
      print('🟡 Pusher - Estado atual do Pusher: ${_pusher?.connectionState}');
      print('🟡 Pusher - Pusher inicializado: ${_pusher != null}');
      print('🟡 Pusher - Canais ativos antes: ${_chatChannels.keys.toList()}');
      
      if (_pusher == null) {
        print('🟡 Pusher - Pusher não inicializado, inicializando...');
        await initialize();
      }
      
      final channelName = 'chat.$chatId';
      print('🟡 Pusher - Nome do canal: $channelName');
      print('🟡 Pusher - Formato esperado: chat.{chatId}');
      print('🟡 Pusher - Chat ID fornecido: $chatId (tipo: ${chatId.runtimeType})');
      
      // Verificar se já está inscrito neste canal
      if (_chatChannels.containsKey(channelName)) {
        print('🟡 Pusher - Já inscrito no canal: $channelName');
        return;
      }
      
      print('🟢 Pusher - Inscrevendo no canal: $channelName');
      print('🟡 Pusher - Estado do Pusher: ${_pusher?.connectionState}');
      print('🟡 Pusher - Tentando subscribe...');
      
      final channel = await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) {
          print('🟡 Pusher - Evento do canal $channelName: ${event.eventName}');
          print('🟡 Pusher - Dados do evento: ${event.data}');
          _handleChatEventWithId(event, chatId);
        },
      );
      
      print('🟢 Pusher - Canal retornado pelo subscribe: ${channel.channelName}');
      _chatChannels[channelName] = channel;
      print('🟢 Pusher - Inscrito com sucesso no canal: $channelName');
      print('🟢 Pusher - Total de canais ativos: ${_chatChannels.length}');
      print('🟢 Pusher - Canais ativos depois: ${_chatChannels.keys.toList()}');
      
    } catch (e) {
      print('🔴 Pusher - Erro ao se inscrever no canal chat.$chatId: $e');
      print('🔴 Pusher - Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Remove inscrição de um canal de chat específico
  static Future<void> unsubscribeFromChat(int chatId) async {
    try {
      final channelName = 'chat.$chatId';
      
      if (_chatChannels.containsKey(channelName)) {
        final channel = _chatChannels[channelName]!;
        await _pusher!.unsubscribe(channelName: channelName);
        _chatChannels.remove(channelName);
        print('🟢 Pusher - Removida inscrição do canal: $channelName');
      }
    } catch (e) {
      print('🔴 Pusher - Erro ao remover inscrição do canal chat.$chatId: $e');
    }
  }

  /// Remove inscrição de todos os canais de chat
  static Future<void> unsubscribeFromAllChats() async {
    try {
      for (final channelName in _chatChannels.keys.toList()) {
        await _pusher!.unsubscribe(channelName: channelName);
        print('🟢 Pusher - Removida inscrição do canal: $channelName');
      }
      _chatChannels.clear();
    } catch (e) {
      print('🔴 Pusher - Erro ao remover inscrições: $e');
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
      print('🟡 Pusher - Processando evento de chat: ${event.eventName}');
        print('aqui');
      
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
        case 'message-sent':
          _handleMessageSent(event);
          break;
        case 'message-read':
          _handleMessageRead(event);
          break;
        default:
          print('🟡 Pusher - Evento de chat não tratado: ${event.eventName}');
      }
    } catch (e) {
      print('🔴 Pusher - Erro ao processar evento de chat: $e');
    }
  }

  /// Versão sobrecarregada para eventos de chat específicos
  static void _handleChatEventWithId(PusherEvent event, int chatId) {
    try {
      print('🟡 Pusher - Processando evento de chat ID: $chatId: ${event.eventName}');
      
      // Notificar listeners específicos de chat
      onChatEvent?.call(chatId.toString(), event.eventName, event.data);
      
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
        case 'message-sent':
          _handleMessageSent(event, chatId: chatId);
          break;
        case 'message-read':
          _handleMessageRead(event, chatId: chatId);
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

  static void _handleMessageSent(PusherEvent event, {int? chatId}) {
    try {
      final data = jsonDecode(event.data);
      final message = data['message'] ?? '';
      final sender = data['sender'] ?? 'Unknown';
      final timestamp = data['timestamp'] ?? DateTime.now().toIso8601String();
      
      print('🟢 Pusher - Mensagem enviada: $message de $sender ${chatId != null ? 'no chat $chatId' : ''}');
      
      // Notificar listeners específicos de chat
      if (chatId != null) {
        // Passar os dados brutos (String JSON) para o callback
        onChatEvent?.call(chatId.toString(), 'message-sent', event.data);
      }
      
    } catch (e) {
      print('🔴 Pusher - Erro ao processar mensagem enviada: $e');
    }
  }

  static void _handleMessageRead(PusherEvent event, {int? chatId}) {
    try {
      final data = jsonDecode(event.data);
      final messageId = data['message_id'] ?? '';
      final reader = data['reader'] ?? 'Unknown';
      final timestamp = data['timestamp'] ?? DateTime.now().toIso8601String();
      
      print('🟢 Pusher - Mensagem lida: ID $messageId por $reader ${chatId != null ? 'no chat $chatId' : ''}');
      
      // Notificar listeners específicos de chat
      if (chatId != null) {
        // Passar os dados brutos (String JSON) para o callback
        onChatEvent?.call(chatId.toString(), 'message-read', event.data);
      }
      
    } catch (e) {
      print('🔴 Pusher - Erro ao processar mensagem lida: $e');
    }
  }

  /// Método de teste para verificar a conexão
  static Future<void> testConnection() async {
    try {
      print('🧪 Pusher - Testando conexão...');
      
      if (_pusher == null) {
        print('🧪 Pusher - Pusher não inicializado, inicializando...');
        await initialize();
      }
      
      print('🧪 Pusher - Estado da conexão: ${_pusher?.connectionState}');
      print('🧪 Pusher - Tentando inscrever em canal de teste...');
      
      // Tentar inscrever em um canal de teste
      print('🧪 Pusher - Chamando subscribe para test-channel...');
      final testChannel = await _pusher!.subscribe(
        channelName: 'test-channel',
        onEvent: (event) {
          print('🧪 Pusher - Evento de teste recebido: ${event.eventName}');
        },
      );
      
      print('🧪 Pusher - Canal de teste inscrito com sucesso: ${testChannel.channelName}');
      print('🧪 Pusher - Aguardando 2 segundos...');
      
      // Aguardar um pouco e depois desinscrever
      await Future.delayed(Duration(seconds: 2));
      print('🧪 Pusher - Desinscrevendo do canal de teste...');
      await _pusher!.unsubscribe(channelName: 'test-channel');
      print('🧪 Pusher - Teste concluído com sucesso');
      
    } catch (e) {
      print('🔴 Pusher - Erro no teste de conexão: $e');
      print('🔴 Pusher - Stack trace: ${StackTrace.current}');
    }
  }

  /// Método de teste para verificar inscrição em canais de chat
  static Future<void> testChatChannelSubscription(int chatId) async {
    try {
      print('🧪 Pusher - Testando inscrição em canal de chat: $chatId');
      
      if (_pusher == null) {
        print('🧪 Pusher - Pusher não inicializado, inicializando...');
        await initialize();
      }
      
      print('🧪 Pusher - Estado da conexão: ${_pusher?.connectionState}');
      print('🧪 Pusher - Canais ativos antes: ${_chatChannels.keys.toList()}');
      
      // Tentar inscrever no canal de chat
      await subscribeToChat(chatId);
      
      print('🧪 Pusher - Teste de inscrição em canal de chat concluído');
      print('🧪 Pusher - Canais ativos depois: ${_chatChannels.keys.toList()}');
      
    } catch (e) {
      print('🔴 Pusher - Erro no teste de canal de chat: $e');
    }
  }

  static Future<void> disconnect() async {
    try {
      // Desinscrever de todos os canais de chat
      await unsubscribeFromAllChats();
      
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

  /// Verifica se o Pusher está funcionando
  static bool get isConnected => _pusher?.connectionState == 'CONNECTED';
  
  /// Verifica se o Pusher está inicializado
  static bool get isInitialized => _pusher != null;
  
  /// Obtém o estado atual da conexão
  static String? get connectionState => _pusher?.connectionState;
  
  /// Obtém a lista de canais ativos
  static List<String> get activeChannels => _chatChannels.keys.toList();
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