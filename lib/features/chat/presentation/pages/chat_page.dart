import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_widget.dart';

class ChatPage extends StatelessWidget {
  final int? chatId;
  final int? otherUserId;
  final String? otherUserType;
  final String? chatName;

  const ChatPage({
    super.key,
    this.chatId,
    this.otherUserId,
    this.otherUserType,
    this.chatName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider<ChatBloc>(
        create: (context) => ChatBloc()..add(ChatInitialized(chatId: chatId)),
        child: ChatWidget(
          chatId: chatId,
          otherUserId: otherUserId,
          otherUserType: otherUserType,
          chatName: chatName,
        ),
      ),
    );
  }
} 