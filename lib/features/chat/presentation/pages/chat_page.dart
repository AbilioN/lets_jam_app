import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_widget.dart';

class ChatPage extends StatelessWidget {
  final String channelName;
  final String currentUser;

  const ChatPage({
    super.key,
    required this.channelName,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider<ChatBloc>(
        create: (context) => ChatBloc(),
        child: ChatWidget(
          channelName: channelName,
          currentUser: currentUser,
        ),
      ),
    );
  }
} 