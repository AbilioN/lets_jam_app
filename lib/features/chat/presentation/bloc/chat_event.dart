part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatInitialized extends ChatEvent {
  final String channelName;
  final String currentUser;

  const ChatInitialized({
    required this.channelName,
    required this.currentUser,
  });

  @override
  List<Object> get props => [channelName, currentUser];
}

class MessageSent extends ChatEvent {
  final String message;
  final String sender;

  const MessageSent({
    required this.message,
    required this.sender,
  });

  @override
  List<Object> get props => [message, sender];
}

class MessageReceived extends ChatEvent {
  final String message;
  final String sender;
  final String timestamp;

  const MessageReceived({
    required this.message,
    required this.sender,
    required this.timestamp,
  });

  @override
  List<Object> get props => [message, sender, timestamp];
}

class UserJoined extends ChatEvent {
  final String user;
  final String action;

  const UserJoined({
    required this.user,
    required this.action,
  });

  @override
  List<Object> get props => [user, action];
}

class UserLeft extends ChatEvent {
  final String user;
  final String action;

  const UserLeft({
    required this.user,
    required this.action,
  });

  @override
  List<Object> get props => [user, action];
}

class ChatDisconnected extends ChatEvent {} 