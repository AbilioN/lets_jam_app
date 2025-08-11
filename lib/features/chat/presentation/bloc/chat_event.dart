part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatInitialized extends ChatEvent {
  final int? chatId;

  const ChatInitialized({
    this.chatId,
  });

  @override
  List<Object> get props => [chatId ?? 0];
}

class MessageSent extends ChatEvent {
  final String content;
  final int? chatId;
  final int? otherUserId;
  final String? otherUserType;

  const MessageSent({
    required this.content,
    this.chatId,
    this.otherUserId,
    this.otherUserType,
  });

  @override
  List<Object> get props => [content, chatId ?? 0, otherUserId ?? 0, otherUserType ?? ''];
}

class MessageReceived extends ChatEvent {
  final chat_service.ChatMessage message;

  const MessageReceived({
    required this.message,
  });

  @override
  List<Object> get props => [message];
}

class LoadConversation extends ChatEvent {
  final int otherUserId;
  final String otherUserType;
  final int page;
  final int perPage;

  const LoadConversation({
    required this.otherUserId,
    required this.otherUserType,
    this.page = 1,
    this.perPage = 50,
  });

  @override
  List<Object> get props => [otherUserId, otherUserType, page, perPage];
}

class LoadChatMessages extends ChatEvent {
  final int chatId;
  final int page;
  final int perPage;

  const LoadChatMessages({
    required this.chatId,
    this.page = 1,
    this.perPage = 50,
  });

  @override
  List<Object> get props => [chatId, page, perPage];
}

class LoadChats extends ChatEvent {
  final int page;
  final int perPage;

  const LoadChats({
    this.page = 1,
    this.perPage = 20,
  });

  @override
  List<Object> get props => [page, perPage];
}

class CreatePrivateChat extends ChatEvent {
  final int otherUserId;
  final String otherUserType;

  const CreatePrivateChat({
    required this.otherUserId,
    required this.otherUserType,
  });

  @override
  List<Object> get props => [otherUserId, otherUserType];
}

class CreateGroupChat extends ChatEvent {
  final String name;
  final String description;
  final List<chat_service.ChatParticipant> participants;

  const CreateGroupChat({
    required this.name,
    required this.description,
    required this.participants,
  });

  @override
  List<Object> get props => [name, description, participants];
}

class ChatDisconnected extends ChatEvent {} 