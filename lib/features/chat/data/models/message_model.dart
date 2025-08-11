class MessageModel {
  final int id;
  final int chatId;
  final String content;
  final int senderId;
  final String senderType;
  final String messageType;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final String? updatedAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    this.metadata,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      chatId: json['chat_id'] as int,
      content: json['content'] as String,
      senderId: json['sender_id'] as int,
      senderType: json['sender_type'] as String,
      messageType: json['message_type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'content': content,
      'sender_id': senderId,
      'sender_type': senderType,
      'message_type': messageType,
      'metadata': metadata,
      'is_read': isRead,
      'read_at': readAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, chatId: $chatId, content: $content, senderId: $senderId, senderType: $senderType, messageType: $messageType, isRead: $isRead, createdAt: $createdAt)';
  }
}

class MessagesResponse {
  final List<MessageModel> messages;
  final bool fromCache;
  final Map<String, dynamic> pagination;

  MessagesResponse({
    required this.messages,
    required this.fromCache,
    required this.pagination,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    print('🔵 MessagesResponse - Processando JSON: ${json.keys.toList()}');
    
    // Verificar se o JSON é válido
    if (json == null) {
      throw Exception('JSON recebido é null');
    }
    
    // A API pode retornar diferentes formatos
    List<dynamic> messagesList;
    bool fromCacheValue;
    Map<String, dynamic> paginationData;
    
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      // Formato: { "success": true, "data": { "messages": [...], "from_cache": false, "pagination": {...} } }
      final data = json['data'] as Map<String, dynamic>;
      print('🔵 MessagesResponse - Formato com data: ${data.keys.toList()}');
      
      if (data.containsKey('messages') && data['messages'] is List) {
        messagesList = data['messages'] as List<dynamic>;
      } else {
        print('🔴 MessagesResponse - Campo "messages" não encontrado ou não é uma lista');
        messagesList = []; // Lista vazia se não houver mensagens
      }
      
      fromCacheValue = data['from_cache'] as bool? ?? false;
      
      if (data.containsKey('pagination') && data['pagination'] is Map<String, dynamic>) {
        paginationData = data['pagination'] as Map<String, dynamic>;
      } else {
        paginationData = {}; // Paginação opcional
      }
    } else if (json.containsKey('messages') && json['messages'] is List) {
      // Formato direto: { "messages": [...], "from_cache": false, "pagination": {...} }
      print('🔵 MessagesResponse - Formato direto');
      messagesList = json['messages'] as List<dynamic>;
      fromCacheValue = json['from_cache'] as bool? ?? false;
      paginationData = json['pagination'] as Map<String, dynamic>? ?? {};
    } else {
      print('🔴 MessagesResponse - Formato não reconhecido, criando resposta vazia');
      print('🔴 MessagesResponse - Chaves disponíveis: ${json.keys.toList()}');
      // Retornar resposta vazia em vez de erro
      messagesList = [];
      fromCacheValue = false;
      paginationData = {};
    }
    
    return MessagesResponse(
      messages: messagesList.map((message) => MessageModel.fromJson(message as Map<String, dynamic>)).toList(),
      fromCache: fromCacheValue,
      pagination: paginationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages.map((message) => message.toJson()).toList(),
      'from_cache': fromCache,
      'pagination': pagination,
    };
  }
}
