part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatConnected extends ChatState {
  final String channelName;
  final List<ChatMessage> messages;
  final String currentUser;

  const ChatConnected({
    required this.channelName,
    required this.messages,
    required this.currentUser,
  });

  @override
  List<Object> get props => [channelName, messages, currentUser];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}

class ChatDisconnectedState extends ChatState {} 