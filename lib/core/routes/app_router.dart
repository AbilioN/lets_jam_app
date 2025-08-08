import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/chats_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String chats = '/chats';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashPage(),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        final chatId = args?['chatId'] as int?;
        final otherUserId = args?['otherUserId'] as int?;
        final otherUserType = args?['otherUserType'] as String?;
        final chatName = args?['chatName'] as String?;
        return MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserType: otherUserType,
            chatName: chatName,
          ),
        );
      case chats:
        return MaterialPageRoute(
          builder: (_) => const ChatsPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Página não encontrada'),
            ),
          ),
        );
    }
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(login);
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.of(context).pushNamed(register);
  }

  static void navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(home);
  }

  static void navigateToSplash(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(splash);
  }

  static void navigateToChat(BuildContext context, {
    int? chatId,
    int? otherUserId,
    String? otherUserType,
    String? chatName,
  }) {
    Navigator.of(context).pushNamed(
      chat,
      arguments: {
        'chatId': chatId,
        'otherUserId': otherUserId,
        'otherUserType': otherUserType,
        'chatName': chatName,
      },
    );
  }

  static void navigateToChats(BuildContext context) {
    Navigator.of(context).pushNamed(chats);
  }
} 