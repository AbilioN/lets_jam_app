import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/chat_widget.dart';

class ChatPage extends StatelessWidget {
  final int currentUserId;
  final int? otherUserId;
  final String? otherUserType;

  const ChatPage({
    super.key,
    required this.currentUserId,
    this.otherUserId,
    this.otherUserType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider<ChatBloc>(
        create: (context) => ChatBloc(),
        child: ChatWidget(
          currentUserId: currentUserId,
          otherUserId: otherUserId,
          otherUserType: otherUserType,
        ),
      ),
    );
  }
} 