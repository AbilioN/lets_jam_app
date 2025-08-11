import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../data/models/chat_model.dart';
import '../bloc/chats_bloc.dart';
import '../bloc/chats_event.dart';
import '../bloc/chats_state.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocProvider(
        create: (context) => getIt<ChatsBloc>()..add(LoadChats()),
        child: BlocBuilder<ChatsBloc, ChatsState>(
          builder: (context, state) {
            if (state is ChatsLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is ChatsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ChatsBloc>().add(LoadChats());
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            } else if (state is ChatsLoaded) {
              if (state.chats.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum chat encontrado',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: state.chats.length,
                itemBuilder: (context, index) {
                  final chat = state.chats[index];
                  return _ChatTile(chat: chat);
                },
              );
            }
            
            return const Center(
              child: Text('Carregando chats...'),
            );
          },
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatModel chat;

  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(
          'https://picsum.photos/100/100?random=${chat.id}',
        ),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback para ícone se a imagem falhar
        },
        child: chat.unreadCount > 0
            ? Badge(
                label: Text(
                  chat.unreadCount.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
                child: null,
              )
            : null,
      ),
      title: Text(
        chat.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        chat.lastMessage ?? 'Nenhuma mensagem ainda',
        style: TextStyle(
          color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
          fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDate(chat.updatedAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => _openChat(context),
    );
  }

  void _openChat(BuildContext context) {
    // Disparar evento para carregar mensagens do chat
    context.read<ChatsBloc>().add(LoadChatMessages(chatId: chat.id));
    
    // Navegar para o chat
    AppRouter.navigateToChat(
      context,
      chatId: chat.id,
      chatName: chat.name,
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Ontem';
      } else if (difference.inDays < 7) {
        return _getDayName(date.weekday);
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Seg';
      case 2:
        return 'Ter';
      case 3:
        return 'Qua';
      case 4:
        return 'Qui';
      case 5:
        return 'Sex';
      case 6:
        return 'Sáb';
      case 7:
        return 'Dom';
      default:
        return '';
    }
  }
}
