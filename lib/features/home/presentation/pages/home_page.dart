import 'package:flutter/material.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/di/injection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Let\'s Jam'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_note,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bem-vindo ao Let\'s Jam!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sua aplicação de música está funcionando!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openChat(context),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Abrir Chat'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openChatWithCustomChannel(context),
                icon: const Icon(Icons.group),
                label: const Text('Chat em Grupo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context) {
    AppRouter.navigateToChat(
      context,
      otherUserId: 1, // ID do admin
      otherUserType: 'admin',
    );
  }

  void _openChatWithCustomChannel(BuildContext context) {
    _showChannelDialog(context);
  }

  void _showChannelDialog(BuildContext context) {
    final chatIdController = TextEditingController();
    final otherUserIdController = TextEditingController();
    final otherUserTypeController = TextEditingController(text: 'admin');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entrar no Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: chatIdController,
              decoration: const InputDecoration(
                labelText: 'Chat ID (opcional)',
                hintText: 'ex: 1, 2, 3... (deixe vazio para criar novo)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otherUserIdController,
              decoration: const InputDecoration(
                labelText: 'ID do Outro Usuário (se não tiver Chat ID)',
                hintText: 'ex: 1, 2, 3...',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otherUserTypeController,
              decoration: const InputDecoration(
                labelText: 'Tipo do Outro Usuário',
                hintText: 'ex: admin, user',
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
              final chatId = int.tryParse(chatIdController.text.trim());
              final otherUserId = int.tryParse(otherUserIdController.text.trim());
              final otherUserType = otherUserTypeController.text.trim();
              
              if (chatId != null || (otherUserId != null && otherUserType.isNotEmpty)) {
                Navigator.of(context).pop();
                AppRouter.navigateToChat(
                  context,
                  chatId: chatId,
                  otherUserId: otherUserId,
                  otherUserType: otherUserType,
                );
              }
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final tokenService = getIt<TokenService>();
      await tokenService.clearToken();
      
      if (context.mounted) {
        AppRouter.navigateToLogin(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer logout: $e')),
        );
      }
    }
  }
} 