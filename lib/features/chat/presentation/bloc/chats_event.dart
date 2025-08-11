import 'package:equatable/equatable.dart';

abstract class ChatsEvent extends Equatable {
  const ChatsEvent();

  @override
  List<Object> get props => [];
}

class LoadChats extends ChatsEvent {}

class LoadChatMessages extends ChatsEvent {
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
