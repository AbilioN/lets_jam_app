// Exemplo de uso do ChatService
// Este arquivo demonstra como usar o ChatService em diferentes cenários

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:letsjam/core/services/chat_service.dart';
import 'package:letsjam/core/services/token_service.dart';
import 'package:letsjam/core/di/injection.dart';
import 'package:letsjam/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:letsjam/features/chat/presentation/pages/chat_page.dart';

/// Exemplo de uso do sistema de chat atualizado
/// 
/// Este arquivo demonstra como usar o ChatService e ChatBloc
/// com a nova infraestrutura baseada em chats (chat_id)

class ChatExampleUsage {
  
  /// Exemplo 1: Uso direto do ChatService
  static Future<void> exampleDirectUsage() async {
    print('🟡 Iniciando exemplo de uso direto do ChatService...');
    
    try {
      // 1. Inicializar o ChatService
      final chatService = ChatService.instance;
      await chatService.initialize();
      
      // 2. Criar um chat privado
      final chat = await chatService.createPrivateChat(
        otherUserId: '2',
        otherUserType: 'user',
      );
      
      print('🟢 Chat privado criado: ${chat.name} (ID: ${chat.id})');
      
      // 3. Escutar mensagens do chat
      await chatService.listenToChat(chat.id);
      
      // 4. Enviar uma mensagem
      final message = await chatService.sendMessageToChat(
        chatId: chat.id,
        content: 'Olá! Como posso ajudar?',
      );
      
      print('🟢 Mensagem enviada: ${message.content}');
      
      // 5. Buscar conversa
      final conversation = await chatService.getConversation(
        otherUserId: '2',
        otherUserType: 'user',
      );
      
      print('🟢 Conversa carregada: ${conversation.messages.length} mensagens');
      
      // 6. Listar todos os chats
      final chats = await chatService.getChats();
      print('🟢 Total de chats: ${chats.length}');
      
    } catch (e) {
      print('🔴 Erro no exemplo: $e');
    }
  }
  
  /// Exemplo 2: Criar chat em grupo
  static Future<void> exampleGroupChat() async {
    print('🟡 Iniciando exemplo de chat em grupo...');
    
    try {
      final chatService = ChatService.instance;
      await chatService.initialize();
      
      // Criar chat em grupo
      final groupChat = await chatService.createGroupChat(
        name: 'Grupo de Suporte',
        description: 'Chat para suporte geral',
        participants: [
          ChatParticipant(userId: '1', userType: 'admin'),
          ChatParticipant(userId: '2', userType: 'user'),
          ChatParticipant(userId: '3', userType: 'admin'),
        ],
      );
      
      print('🟢 Chat em grupo criado: ${groupChat.name} (ID: ${groupChat.id})');
      
      // Escutar o grupo
      await chatService.listenToChat(groupChat.id);
      
      // Enviar mensagem para o grupo
      final message = await chatService.sendMessageToChat(
        chatId: groupChat.id,
        content: 'Bem-vindos ao grupo de suporte!',
      );
      
      print('🟢 Mensagem enviada para o grupo: ${message.content}');
      
    } catch (e) {
      print('🔴 Erro no chat em grupo: $e');
    }
  }
  
  /// Exemplo 3: Uso com BLoC
  static Widget exampleWithBloc() {
    return BlocProvider<ChatBloc>(
      create: (context) => ChatBloc(),
      child: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is ChatConnected) {
              return Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue,
                    child: Row(
                      children: [
                        Text(
                          'Chat ${state.chatId ?? "Novo"}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        Text(
                          '${state.messages.length} mensagens',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de mensagens
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return ListTile(
                          title: Text(message.content),
                          subtitle: Text('${message.senderType} - ${message.createdAt}'),
                        );
                      },
                    ),
                  ),
                  
                  // Campo de entrada
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Digite sua mensagem...',
                            ),
                            onSubmitted: (content) {
                              context.read<ChatBloc>().add(
                                MessageSent(
                                  content: content,
                                  chatId: state.chatId,
                                  otherUserId: 2,
                                  otherUserType: 'user',
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            
            return const Center(child: Text('Nenhum chat ativo'));
          },
        ),
      ),
    );
  }
  
  /// Exemplo 4: Navegação para chat
  static void navigateToChatExample(BuildContext context) {
    // Navegar para chat existente
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChatPage(chatId: '1'),
      ),
    );
    
    // Ou navegar para chat com usuário específico
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          otherUserId: 2,
          otherUserType: 'user',
        ),
      ),
    );
  }
  
  /// Exemplo 5: Configurar callbacks do ChatService
  static void setupCallbacks() {
    // Callback para mensagens recebidas
    ChatService.onMessageReceived = (message) {
      print('🟢 Nova mensagem recebida: ${message.content}');
      // Aqui você pode atualizar a UI, mostrar notificação, etc.
    };
    
    // Callback para erros
    ChatService.onError = (error) {
      print('🔴 Erro no chat: $error');
      // Aqui você pode mostrar snackbar, dialog de erro, etc.
    };
  }
  
  /// Exemplo 6: Gerenciar múltiplos chats
  static Future<void> manageMultipleChats() async {
    final chatService = ChatService.instance;
    await chatService.initialize();
    
    // Criar múltiplos chats
    final chat1 = await chatService.createPrivateChat(
      otherUserId: '2',
      otherUserType: 'user',
    );

    final chat2 = await chatService.createPrivateChat(
      otherUserId: '3',
      otherUserType: 'admin',
    );
    
    // Escutar ambos os chats
    await chatService.listenToChat(chat1.id);
    await chatService.listenToChat(chat2.id);
    
    // Enviar mensagens para diferentes chats
    await chatService.sendMessageToChat(
      chatId: chat1.id,
      content: 'Mensagem para chat 1',
    );
    
    await chatService.sendMessageToChat(
      chatId: chat2.id,
      content: 'Mensagem para chat 2',
    );
    
    // Listar todos os chats
    final allChats = await chatService.getChats();
    print('🟢 Total de chats: ${allChats.length}');
    
    for (final chat in allChats) {
      print('  - ${chat.name} (ID: ${chat.id}, Tipo: ${chat.type})');
      if (chat.unreadCount != null && chat.unreadCount! > 0) {
        print('    Mensagens não lidas: ${chat.unreadCount}');
      }
    }
  }
  
  /// Exemplo 7: Paginação de mensagens
  static Future<void> paginationExample() async {
    final chatService = ChatService.instance;
    await chatService.initialize();
    
    // Buscar conversa com paginação
    final conversation = await chatService.getConversation(
      otherUserId: '2',
      otherUserType: 'user',
      page: 1,
      perPage: 20,
    );

    print('🟢 Página ${conversation.pagination.currentPage} de ${conversation.pagination.lastPage}');
    print('🟢 Total de mensagens: ${conversation.pagination.total}');
    print('🟢 Mensagens nesta página: ${conversation.messages.length}');

    // Se houver mais páginas, carregar a próxima
    if (conversation.pagination.currentPage < conversation.pagination.lastPage) {
      final nextPage = await chatService.getConversation(
        otherUserId: '2',
        otherUserType: 'user',
        page: conversation.pagination.currentPage + 1,
        perPage: 20,
      );
      
      print('🟢 Próxima página carregada: ${nextPage.messages.length} mensagens');
    }
  }
  
  /// Exemplo 8: Limpeza e desconexão
  static Future<void> cleanupExample() async {
    final chatService = ChatService.instance;
    
    // Limpar mensagens em memória
    chatService.clearMessages();
    
    // Limpar chats em memória
    chatService.clearChats();
    
    // Desconectar do chat
    await chatService.disconnect();
    
    print('🟢 ChatService limpo e desconectado');
  }
}

/// Widget de exemplo para testar o chat
class ChatExampleWidget extends StatefulWidget {
  const ChatExampleWidget({super.key});

  @override
  State<ChatExampleWidget> createState() => _ChatExampleWidgetState();
}

class _ChatExampleWidgetState extends State<ChatExampleWidget> {
  @override
  void initState() {
    super.initState();
    // Configurar callbacks
    ChatExampleUsage.setupCallbacks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplos de Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => ChatExampleUsage.exampleDirectUsage(),
              child: const Text('Testar ChatService Direto'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ChatExampleUsage.exampleGroupChat(),
              child: const Text('Testar Chat em Grupo'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ChatExampleUsage.manageMultipleChats(),
              child: const Text('Gerenciar Múltiplos Chats'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ChatExampleUsage.paginationExample(),
              child: const Text('Testar Paginação'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ChatExampleUsage.cleanupExample(),
              child: const Text('Limpar e Desconectar'),
            ),
            const SizedBox(height: 32),
            const Text('Chat com BLoC:'),
            const SizedBox(height: 16),
            Expanded(
              child: ChatExampleUsage.exampleWithBloc(),
            ),
          ],
        ),
      ),
    );
  }
} 