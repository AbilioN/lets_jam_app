part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatInitialized extends ChatEvent {
  final String? chatId;

  const ChatInitialized({
    this.chatId,
  });

  @override
  List<Object> get props => [chatId ?? ''];
}

class MessageSent extends ChatEvent {
  final String content;
  final String? chatId;
  final int? otherUserId;
  final String? otherUserType;

  const MessageSent({
    required this.content,
    this.chatId,
    this.otherUserId,
    this.otherUserType,
  });

  @override
  List<Object> get props => [content, chatId ?? '', otherUserId ?? 0, otherUserType ?? ''];
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
  final String chatId;
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

class EditMessageRequested extends ChatEvent {
  final String messageId;
  final String newContent;

  const EditMessageRequested({required this.messageId, required this.newContent});

  @override
  List<Object> get props => [messageId, newContent];
}

class DeleteMessageRequested extends ChatEvent {
  final String messageId;

  const DeleteMessageRequested({required this.messageId});

  @override
  List<Object> get props => [messageId];
}

class MarkChatAsRead extends ChatEvent {
  const MarkChatAsRead();
}

class SearchUsersRequested extends ChatEvent {
  final String query;

  const SearchUsersRequested({required this.query});

  @override
  List<Object> get props => [query];
}

class _PusherMessageEdited extends ChatEvent {
  final String id;
  final String content;
  final String? editedAt;
  const _PusherMessageEdited({required this.id, required this.content, this.editedAt});
  @override
  List<Object> get props => [id, content];
}

class _PusherMessageDeleted extends ChatEvent {
  final String id;
  const _PusherMessageDeleted({required this.id});
  @override
  List<Object> get props => [id];
}

class _PusherMessageRead extends ChatEvent {
  final String readerId;
  const _PusherMessageRead({required this.readerId});
  @override
  List<Object> get props => [readerId];
}

class StartTyping extends ChatEvent {
  final String chatId;

  const StartTyping({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

class StopTyping extends ChatEvent {
  final String chatId;

  const StopTyping({required this.chatId});

  @override
  List<Object> get props => [chatId];
} 