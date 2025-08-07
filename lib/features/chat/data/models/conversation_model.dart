class ConversationModel {
  final int id;
  final String name;
  final String type;
  final String description;
  final String? lastMessage;
  final int unreadCount;
  final int participantsCount;
  final String createdAt;
  final String updatedAt;

  ConversationModel({
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

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
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
}

class ConversationsResponse {
  final List<ConversationModel> chats;
  final Map<String, dynamic> pagination;

  ConversationsResponse({
    required this.chats,
    required this.pagination,
  });

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    return ConversationsResponse(
      chats: (json['chats'] as List<dynamic>)
          .map((chat) => ConversationModel.fromJson(chat as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] as Map<String, dynamic>,
    );
  }
} 