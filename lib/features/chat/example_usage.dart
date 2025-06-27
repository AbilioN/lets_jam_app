// Exemplo de uso do ChatService
// Este arquivo demonstra como usar o ChatService em diferentes cenários

import 'package:flutter/material.dart';
import '../../core/services/chat_service.dart';
import '../../core/routes/app_router.dart';

class ChatExampleUsage {
  
  /// Exemplo 1: Inicializar chat e escutar mensagens
  static Future<void> initializeChatExample() async {
    try {
      // Inicializar o ChatService
      await ChatService.instance.initialize();
      
      // Configurar callbacks para receber mensagens
      ChatService.onMessageReceived = (message) {
        print('🟢 Nova mensagem recebida: ${message.content}');
        print('   De: ${message.senderName} (${message.senderType})');
        print('   Para: ${message.receiverType} ID ${message.receiverId}');
        print('   Horário: ${message.createdAt}');
      };
      
      ChatService.onError = (error) {
        print('🔴 Erro no chat: $error');
      };
      
      print('🟢 Chat inicializado com sucesso!');
      
    } catch (e) {
      print('🔴 Erro ao inicializar chat: $e');
    }
  }
  
  /// Exemplo 2: Escutar conversa específica
  static Future<void> listenToConversationExample() async {
    try {
      const currentUserId = 5; // ID do usuário atual
      const otherUserId = 1;   // ID do admin
      
      await ChatService.instance.listenToConversation(
        currentUserId,
        otherUserId,
      );
      
      print('🟢 Escutando conversa entre usuário $currentUserId e admin $otherUserId');
      
    } catch (e) {
      print('🔴 Erro ao escutar conversa: $e');
    }
  }
  
  /// Exemplo 3: Enviar mensagem
  static Future<void> sendMessageExample() async {
    try {
      final message = await ChatService.instance.sendMessage(
        content: 'Olá! Como posso ajudar?',
        receiverType: 'admin',
        receiverId: 1,
      );
      
      print('🟢 Mensagem enviada com sucesso!');
      print('   ID: ${message.id}');
      print('   Conteúdo: ${message.content}');
      print('   Horário: ${message.createdAt}');
      
    } catch (e) {
      print('🔴 Erro ao enviar mensagem: $e');
    }
  }
  
  /// Exemplo 4: Carregar conversa
  static Future<void> loadConversationExample() async {
    try {
      final messages = await ChatService.instance.getConversation(
        otherUserType: 'admin',
        otherUserId: 1,
        page: 1,
        perPage: 50,
      );
      
      print('🟢 Conversa carregada com sucesso!');
      print('   Total de mensagens: ${messages.length}');
      
      for (final message in messages) {
        print('   - ${message.senderName}: ${message.content}');
      }
      
    } catch (e) {
      print('🔴 Erro ao carregar conversa: $e');
    }
  }
  
  /// Exemplo 5: Carregar lista de conversas
  static Future<void> loadConversationsExample() async {
    try {
      final conversations = await ChatService.instance.getConversations();
      
      print('🟢 Conversas carregadas com sucesso!');
      print('   Total de conversas: ${conversations.length}');
      
      for (final conversation in conversations) {
        print('   - Conversa com ${conversation.otherUserType} ID ${conversation.otherUserId}');
        print('     Mensagens: ${conversation.messageCount}');
        print('     Não lidas: ${conversation.unreadCount}');
        print('     Última mensagem: ${conversation.lastMessageAt}');
      }
      
    } catch (e) {
      print('🔴 Erro ao carregar conversas: $e');
    }
  }
  
  /// Exemplo 6: Admin enviando mensagem
  static Future<void> adminSendMessageExample() async {
    try {
      final message = await ChatService.instance.adminSendMessage(
        content: 'Olá! Sou o administrador. Como posso ajudar?',
        userId: 5, // ID do usuário que receberá a mensagem
      );
      
      print('🟢 Mensagem de admin enviada com sucesso!');
      print('   ID: ${message.id}');
      print('   Conteúdo: ${message.content}');
      
    } catch (e) {
      print('🔴 Erro ao enviar mensagem de admin: $e');
    }
  }
  
  /// Exemplo 7: Admin carregando conversa
  static Future<void> adminLoadConversationExample() async {
    try {
      final messages = await ChatService.instance.adminGetConversation(
        userId: 5, // ID do usuário
        page: 1,
        perPage: 50,
      );
      
      print('🟢 Conversa de admin carregada com sucesso!');
      print('   Total de mensagens: ${messages.length}');
      
    } catch (e) {
      print('🔴 Erro ao carregar conversa de admin: $e');
    }
  }
  
  /// Exemplo 8: Desconectar do chat
  static Future<void> disconnectExample() async {
    try {
      await ChatService.instance.disconnect();
      print('🟢 Chat desconectado com sucesso!');
      
    } catch (e) {
      print('🔴 Erro ao desconectar: $e');
    }
  }
  
  /// Exemplo 9: Navegação para chat usando AppRouter
  static void navigateToChatExample(BuildContext context) {
    // Navegar para chat com admin
    AppRouter.navigateToChat(
      context,
      currentUserId: 5,
      otherUserId: 1,
      otherUserType: 'admin',
    );
  }
  
  /// Exemplo 10: Widget de exemplo completo
  static Widget buildExampleWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo de Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => initializeChatExample(),
              child: const Text('1. Inicializar Chat'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => listenToConversationExample(),
              child: const Text('2. Escutar Conversa'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => sendMessageExample(),
              child: const Text('3. Enviar Mensagem'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => loadConversationExample(),
              child: const Text('4. Carregar Conversa'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => loadConversationsExample(),
              child: const Text('5. Carregar Conversas'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => adminSendMessageExample(),
              child: const Text('6. Admin - Enviar Mensagem'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => adminLoadConversationExample(),
              child: const Text('7. Admin - Carregar Conversa'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => disconnectExample(),
              child: const Text('8. Desconectar'),
            ),
          ],
        ),
      ),
    );
  }
}

// Exemplo de uso em um widget
class ChatExampleWidget extends StatefulWidget {
  const ChatExampleWidget({super.key});

  @override
  State<ChatExampleWidget> createState() => _ChatExampleWidgetState();
}

class _ChatExampleWidgetState extends State<ChatExampleWidget> {
  @override
  void initState() {
    super.initState();
    // Inicializar chat quando o widget for criado
    ChatExampleUsage.initializeChatExample();
  }

  @override
  Widget build(BuildContext context) {
    return ChatExampleUsage.buildExampleWidget();
  }
}

// Para usar esta página, adicione uma rota no AppRouter:
/*
static const String chatExample = '/chat-example';

// No generateRoute:
case chatExample:
  return MaterialPageRoute(
    builder: (_) => const ChatExamplePage(),
  );

// Método de navegação:
static void navigateToChatExample(BuildContext context) {
  Navigator.of(context).pushNamed(chatExample);
}
*/ 