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

  // Generic message callbacks (legacy)
  static Function(String message, String sender, String timestamp)? onMessageReceived;
  static Function(String user, String action)? onUserJoined;
  static Function(String user, String action)? onUserLeft;

  // Chat-specific callbacks
  static Function(ChatMessage message)? onChatMessageReceived;
  static Function(String chatId, String eventType, dynamic data)? onChatEvent;
  static Function(int chatId, int userId, bool isTyping)? onTypingReceived;

  static final List<ChatMessage> _messages = [];
  static List<ChatMessage> get messages => List.unmodifiable(_messages);

  // Active per-chat channels (for typing indicators)
  static final Map<String, PusherChannel> _chatChannels = {};

  // Personal channel — receives all MessageSent events across all chats
  static PusherChannel? _personalChannel;
  static String? _personalChannelName;

  static Future<void> initialize({HttpService? httpService}) async {
    try {
      print('🟡 Pusher - Iniciando inicialização...');

      _pusher = PusherChannelsFlutter.getInstance();
      _httpService = httpService ?? HttpService(
        baseUrl: ApiConfig.baseUrl,
        tokenService: getIt<TokenService>(),
      );

      await _pusher!.init(
        apiKey: PusherConfig.clientAppKey,
        cluster: PusherConfig.clientCluster,
        onAuthorizer: (channelName, socketId, options) async {
          try {
            final token = await getIt<TokenService>().getToken();
            final response = await _httpService!.post(
              '/broadcasting/auth',
              {'socket_id': socketId, 'channel_name': channelName},
              headers: {'Authorization': 'Bearer ${token ?? ''}'},
            );
            // pusher_channels_flutter expects a Map or JSON string
            if (response is Map) return response;
            return <String, dynamic>{};
          } catch (e) {
            print('🔴 Pusher - Auth error for $channelName: $e');
            return <String, dynamic>{};
          }
        },
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
          print('🟡 Pusher - Evento: ${event.eventName} em ${event.channelName}');
          _handleEvent(event);
        },
      );

      print('🟡 Pusher - Conectando...');
      await _pusher!.connect();
      print('🟢 Pusher - Conectado');
    } catch (e) {
      print('🔴 Pusher - Erro na inicialização: $e');
      rethrow;
    }
  }

  // ── Personal channel ──────────────────────────────────────────────────────

  /// Subscribe to personal channel e.g. "private-user.user.42"
  /// Receives MessageSent events from ALL chats the user participates in.
  static Future<void> subscribeToPersonalChannel(String channelName) async {
    if (_pusher == null) await initialize();
    if (_personalChannelName == channelName) return;

    // Unsubscribe from previous personal channel if any
    if (_personalChannelName != null && _personalChannelName != channelName) {
      await unsubscribeFromPersonalChannel();
    }

    print('🟡 Pusher - Subscribing to personal channel: $channelName');
    _personalChannelName = channelName;

    _personalChannel = await _pusher!.subscribe(
      channelName: channelName,
      onEvent: (event) {
        print('🟡 Pusher - Personal channel event: ${event.eventName}');
        if (event.eventName == 'MessageSent') {
          final msg = _parseMessageEvent(event);
          if (msg != null) {
            onChatMessageReceived?.call(msg);
            onChatEvent?.call(msg.chatId.toString(), 'MessageSent', event.data);
          }
        }
      },
    );

    print('🟢 Pusher - Personal channel subscribed: $channelName');
  }

  static Future<void> unsubscribeFromPersonalChannel() async {
    if (_personalChannelName != null && _pusher != null) {
      await _pusher!.unsubscribe(channelName: _personalChannelName!);
      _personalChannel = null;
      _personalChannelName = null;
      print('🟢 Pusher - Personal channel unsubscribed');
    }
  }

  // ── Per-chat private channel (typing indicators) ─────────────────────────

  /// Subscribe to private-chat.{chatId} for typing indicators only.
  static Future<void> subscribeToChat(int chatId) async {
    if (_pusher == null) await initialize();

    final channelName = 'private-chat.$chatId';
    if (_chatChannels.containsKey(channelName)) return;

    print('🟡 Pusher - Subscribing to chat channel: $channelName');

    final channel = await _pusher!.subscribe(
      channelName: channelName,
      onEvent: (event) {
        print('🟡 Pusher - Chat channel event: ${event.eventName} on $channelName');
        _handleChatEventWithId(event, chatId);
      },
    );

    _chatChannels[channelName] = channel;
    print('🟢 Pusher - Chat channel subscribed: $channelName');
  }

  static Future<void> unsubscribeFromChat(int chatId) async {
    final channelName = 'private-chat.$chatId';
    if (_chatChannels.containsKey(channelName)) {
      await _pusher!.unsubscribe(channelName: channelName);
      _chatChannels.remove(channelName);
      print('🟢 Pusher - Unsubscribed from: $channelName');
    }
  }

  static Future<void> unsubscribeFromAllChats() async {
    for (final channelName in _chatChannels.keys.toList()) {
      await _pusher!.unsubscribe(channelName: channelName);
      print('🟢 Pusher - Unsubscribed from: $channelName');
    }
    _chatChannels.clear();
  }

  // ── Typing indicators via client events ──────────────────────────────────

  static Future<void> triggerTyping(int chatId, int userId, bool isTyping) async {
    final channelName = 'private-chat.$chatId';
    if (!_chatChannels.containsKey(channelName) || _pusher == null) return;

    final eventName = isTyping ? 'client-typing' : 'client-stop-typing';
    try {
      await _pusher!.trigger(PusherEvent(
        channelName: channelName,
        eventName: eventName,
        data: jsonEncode({'user_id': userId, 'chat_id': chatId}),
      ));
    } catch (e) {
      print('🔴 Pusher - Typing trigger error: $e');
    }
  }

  // ── Event handlers ────────────────────────────────────────────────────────

  static void _handleEvent(PusherEvent event) {
    // General Pusher events — currently handled per-channel via onEvent callbacks
  }

  static void _handleChatEventWithId(PusherEvent event, int chatId) {
    try {
      // Per-chat channel is used ONLY for typing indicators (client events).
      // MessageSent events arrive here too (backend broadcasts on both personal
      // and per-chat channels) but we skip them — the personal channel handles
      // all MessageSent delivery to avoid duplicate processing.
      switch (event.eventName) {
        case 'client-typing':
          final data = event.data is String ? jsonDecode(event.data as String) : event.data;
          final userId = (data as Map)['user_id'];
          if (userId != null) onTypingReceived?.call(chatId, userId as int, true);
          break;
        case 'client-stop-typing':
          final data = event.data is String ? jsonDecode(event.data as String) : event.data;
          final userId = (data as Map)['user_id'];
          if (userId != null) onTypingReceived?.call(chatId, userId as int, false);
          break;
        default:
          // Silently ignore other events on per-chat channel (incl. MessageSent duplicate)
          break;
      }
    } catch (e) {
      print('🔴 Pusher - Error handling event ${event.eventName}: $e');
    }
  }

  // ── Legacy event handlers (kept for backward compat) ─────────────────────

  static void _handleChatEvent(PusherEvent event) {
    switch (event.eventName) {
      case 'MessageSent':
        _handleMessageSentLegacy(event);
        break;
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
        print('🟡 Pusher - Unhandled chat event: ${event.eventName}');
    }
  }

  static void _handleChatMessage(PusherEvent event) {
    try {
      final data = jsonDecode(event.data as String);
      final message = ChatMessage(
        message: data['message'] ?? '',
        sender: data['sender'] ?? 'Unknown',
        timestamp: data['timestamp'] ?? DateTime.now().toIso8601String(),
      );
      _messages.add(message);
      onMessageReceived?.call(message.message, message.sender, message.timestamp);
    } catch (e) {
      print('🔴 Pusher - Error handling chat message: $e');
    }
  }

  static void _handleUserJoined(PusherEvent event) {
    try {
      final data = jsonDecode(event.data as String);
      onUserJoined?.call(data['user'] ?? 'Unknown', 'joined');
    } catch (e) {
      print('🔴 Pusher - Error handling user joined: $e');
    }
  }

  static void _handleUserLeft(PusherEvent event) {
    try {
      final data = jsonDecode(event.data as String);
      onUserLeft?.call(data['user'] ?? 'Unknown', 'left');
    } catch (e) {
      print('🔴 Pusher - Error handling user left: $e');
    }
  }

  static void _handleMessageSentLegacy(PusherEvent event, {int? chatId}) {
    if (chatId != null) {
      onChatEvent?.call(chatId.toString(), 'MessageSent', event.data);
    }
  }

  // ── Message parsing ───────────────────────────────────────────────────────

  static ChatMessage? _parseMessageEvent(PusherEvent event) {
    try {
      Map<String, dynamic> data;
      if (event.data is String) {
        data = Map<String, dynamic>.from(jsonDecode(event.data as String));
      } else if (event.data is Map) {
        data = Map<String, dynamic>.from(event.data as Map);
      } else {
        return null;
      }

      final id = _toInt(data['id']) ?? DateTime.now().millisecondsSinceEpoch;
      final chatId = _toInt(data['chat_id']) ?? 0;
      final content = data['content'] as String? ?? '';
      final senderId = _toInt(data['sender_id']) ?? 0;
      final senderType = data['sender_type'] as String? ?? 'user';
      final isRead = data['is_read'] == true;
      final createdAtRaw = data['created_at'] as String?;
      DateTime createdAt;
      try {
        createdAt = createdAtRaw != null
            ? DateTime.parse(createdAtRaw.replaceAll(' ', 'T'))
            : DateTime.now();
      } catch (_) {
        createdAt = DateTime.now();
      }

      return ChatMessage(
        id: id,
        chatId: chatId,
        content: content,
        senderId: senderId,
        senderType: senderType,
        isRead: isRead,
        createdAt: createdAt,
      );
    } catch (e) {
      print('🔴 Pusher - Error parsing message event: $e');
      return null;
    }
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  static Future<void> subscribeToChatChannel(String channelName) async {
    if (_pusher == null) await initialize();
    _chatChannel = await _pusher!.subscribe(
      channelName: channelName,
      onEvent: (event) => _handleChatEvent(event),
    );
    print('🟢 Pusher - Subscribed to: $channelName');
  }

  static Future<void> testChatChannelSubscription(int chatId) async {
    if (_pusher == null) await initialize();
    await subscribeToChat(chatId);
    print('🧪 Pusher - Test subscription to chat $chatId complete');
  }

  static Future<void> disconnect() async {
    await unsubscribeFromPersonalChannel();
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
    print('🟢 Pusher - Disconnected');
  }

  static void clearMessages() => _messages.clear();

  static bool get isConnected => _pusher?.connectionState == 'CONNECTED';
  static bool get isInitialized => _pusher != null;
  static String? get connectionState => _pusher?.connectionState;
  static List<String> get activeChannels => _chatChannels.keys.toList();
  static String? get personalChannel => _personalChannelName;
}

// ── Legacy ChatMessage for PusherService internal use ────────────────────────

class ChatMessage {
  final dynamic id;
  final dynamic chatId;
  final String content;
  final dynamic senderId;
  final String senderType;
  final bool isRead;
  final DateTime createdAt;

  // Legacy fields
  final String message;
  final String sender;
  final String timestamp;

  ChatMessage({
    dynamic id,
    dynamic chatId,
    String? content,
    dynamic senderId,
    String? senderType,
    bool? isRead,
    DateTime? createdAt,
    // Legacy
    String? message,
    String? sender,
    String? timestamp,
  })  : id = id ?? 0,
        chatId = chatId ?? 0,
        content = content ?? message ?? '',
        senderId = senderId ?? 0,
        senderType = senderType ?? 'user',
        isRead = isRead ?? false,
        createdAt = createdAt ?? DateTime.now(),
        message = message ?? content ?? '',
        sender = sender ?? '',
        timestamp = timestamp ?? (createdAt ?? DateTime.now()).toIso8601String();

  DateTime get dateTime => createdAt;

  @override
  String toString() => 'ChatMessage(id: $id, chatId: $chatId, content: $content)';
}
