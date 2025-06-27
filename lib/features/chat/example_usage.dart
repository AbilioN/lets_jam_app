// Exemplo de uso do Chat com Pusher
// Este arquivo demonstra como usar o sistema de chat

import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';

class ChatExamplePage extends StatelessWidget {
  const ChatExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplos de Chat'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Exemplos de Chat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Chat Geral
            ElevatedButton.icon(
              onPressed: () {
                AppRouter.navigateToChat(
                  context,
                  channelName: 'general',
                  currentUser: 'Usuário Teste',
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat Geral'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Chat de Música
            ElevatedButton.icon(
              onPressed: () {
                AppRouter.navigateToChat(
                  context,
                  channelName: 'musica',
                  currentUser: 'Músico',
                );
              },
              icon: const Icon(Icons.music_note),
              label: const Text('Chat de Música'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Chat de Desenvolvimento
            ElevatedButton.icon(
              onPressed: () {
                AppRouter.navigateToChat(
                  context,
                  channelName: 'dev',
                  currentUser: 'Desenvolvedor',
                );
              },
              icon: const Icon(Icons.code),
              label: const Text('Chat de Dev'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Chat Customizado
            OutlinedButton.icon(
              onPressed: () {
                _showCustomChatDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Chat Customizado'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Instruções:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Clique em qualquer chat para entrar\n'
              '2. Digite mensagens no campo de texto\n'
              '3. Veja mensagens em tempo real\n'
              '4. Use o botão X para sair do chat\n'
              '5. Cada canal é independente',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nota: Para funcionar completamente, você precisa ter o backend Laravel rodando com as rotas de chat configuradas.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomChatDialog(BuildContext context) {
    final channelController = TextEditingController();
    final userController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Criar Chat Customizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: channelController,
              decoration: const InputDecoration(
                labelText: 'Nome do Canal',
                hintText: 'ex: projeto-a, equipe-b, etc.',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: 'Seu Nome',
                hintText: 'Como você quer ser chamado?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final channel = channelController.text.trim();
              final user = userController.text.trim();
              
              if (channel.isNotEmpty && user.isNotEmpty) {
                Navigator.of(context).pop();
                AppRouter.navigateToChat(
                  context,
                  channelName: channel,
                  currentUser: user,
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
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