part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatInitialized extends ChatEvent {
  final int currentUserId;
  final int? otherUserId;

  const ChatInitialized({
    required this.currentUserId,
    this.otherUserId,
  });

  @override
  List<Object> get props => [currentUserId, otherUserId ?? 0];
}

class MessageSent extends ChatEvent {
  final String content;
  final String receiverType;
  final int receiverId;

  const MessageSent({
    required this.content,
    required this.receiverType,
    required this.receiverId,
  });

  @override
  List<Object> get props => [content, receiverType, receiverId];
}

class MessageReceived extends ChatEvent {
  final ChatMessage message;

  const MessageReceived({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

class LoadConversation extends ChatEvent {
  final String otherUserType;
  final int otherUserId;
  final int page;
  final int perPage;

  const LoadConversation({
    required this.otherUserType,
    required this.otherUserId,
    this.page = 1,
    this.perPage = 50,
  });

  @override
  List<Object> get props => [otherUserType, otherUserId, page, perPage];
}

class LoadConversations extends ChatEvent {}

class ChatDisconnected extends ChatEvent {} 