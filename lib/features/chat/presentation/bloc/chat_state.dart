part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatConnected extends ChatState {
  final String? chatId;
  final List<chat_service.ChatMessage> messages;
  final List<chat_service.Chat> chats;

  const ChatConnected({
    this.chatId,
    required this.messages,
    required this.chats,
  });

  @override
  List<Object> get props => [chatId ?? '', messages, chats];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

class ChatDisconnectedState extends ChatState {}

class UserSearchResults extends ChatState {
  final List<Map<String, dynamic>> users;

  const UserSearchResults(this.users);

  @override
  List<Object> get props => [users];
} 