class ChatModel {
  final int id;
  final String name;
  final String type;
  final String description;
  final String? lastMessage;
  final int unreadCount;
  final int participantsCount;
  final String createdAt;
  final String updatedAt;

  ChatModel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.lastMessage,
    required this.unreadCount,
    required this.participantsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      participantsCount: json['participants_count'] as int? ?? 0,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'last_message': lastMessage,
      'unread_count': unreadCount,
      'participants_count': participantsCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'ChatModel(id: $id, name: $name, type: $type, description: $description, lastMessage: $lastMessage, unreadCount: $unreadCount, participantsCount: $participantsCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class ChatsResponse {
  final List<ChatModel> chats;
  final Map<String, dynamic> pagination;

  ChatsResponse({
    required this.chats,
    required this.pagination,
  });

  factory ChatsResponse.fromJson(Map<String, dynamic> json) {
    print('🔵 ChatsResponse - Processando JSON: ${json.keys.toList()}');
    
    // Verificar se o JSON é válido
    if (json == null) {
      throw Exception('JSON recebido é null');
    }
    
    // A API pode retornar diferentes formatos
    List<dynamic> chatsList;
    Map<String, dynamic> paginationData;
    
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      // Formato: { "success": true, "data": { "chats": [...], "pagination": {...} } }
      final data = json['data'] as Map<String, dynamic>;
      print('🔵 ChatsResponse - Formato com data: ${data.keys.toList()}');
      
      if (data.containsKey('chats') && data['chats'] is List) {
        chatsList = data['chats'] as List<dynamic>;
      } else {
        print('🔴 ChatsResponse - Campo "chats" não encontrado ou não é uma lista');
        chatsList = []; // Lista vazia se não houver chats
      }
      
      if (data.containsKey('pagination') && data['pagination'] is Map<String, dynamic>) {
        paginationData = data['pagination'] as Map<String, dynamic>;
      } else {
        paginationData = {}; // Paginação opcional
      }
    } else if (json.containsKey('chats') && json['chats'] is List) {
      // Formato direto: { "chats": [...], "pagination": {...} }
      print('🔵 ChatsResponse - Formato direto');
      chatsList = json['chats'] as List<dynamic>;
      paginationData = json['pagination'] as Map<String, dynamic>? ?? {};
    } else {
      print('🔴 ChatsResponse - Formato não reconhecido, criando resposta vazia');
      print('🔴 ChatsResponse - Chaves disponíveis: ${json.keys.toList()}');
      // Retornar resposta vazia em vez de erro
      chatsList = [];
      paginationData = {};
    }
    
    return ChatsResponse(
      chats: chatsList.map((chat) => ChatModel.fromJson(chat as Map<String, dynamic>)).toList(),
      pagination: paginationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chats': chats.map((chat) => chat.toJson()).toList(),
      'pagination': pagination,
    };
  }
}
