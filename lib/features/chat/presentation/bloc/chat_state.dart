part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatConnected extends ChatState {
  final int currentUserId;
  final int? otherUserId;
  final List<ChatMessage> messages;
  final List<ChatConversation> conversations;

  const ChatConnected({
    required this.currentUserId,
    this.otherUserId,
    required this.messages,
    required this.conversations,
  });

  @override
  List<Object> get props => [currentUserId, otherUserId ?? 0, messages, conversations];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

class ChatDisconnectedState extends ChatState {} 