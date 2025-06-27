import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chat = '/chat';

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
        final args = settings.arguments as Map<String, String>?;
        final channelName = args?['channelName'] ?? 'general';
        final currentUser = args?['currentUser'] ?? 'Anonymous';
        return MaterialPageRoute(
          builder: (_) => ChatPage(
            channelName: channelName,
            currentUser: currentUser,
          ),
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
    required String channelName,
    required String currentUser,
  }) {
    Navigator.of(context).pushNamed(
      chat,
      arguments: {
        'channelName': channelName,
        'currentUser': currentUser,
      },
    );
  }
} 