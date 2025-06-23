import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/routes/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Aguarda um pouco para mostrar a splash
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    try {
      final tokenService = getIt<TokenService>();
      final hasToken = await tokenService.hasToken();
      
      if (!mounted) return;
      
      if (hasToken) {
        // Usuário já está logado, vai para home
        AppRouter.navigateToHome(context);
      } else {
        // Usuário não está logado, vai para login
        AppRouter.navigateToLogin(context);
      }
    } catch (e) {
      // Em caso de erro, vai para login
      if (!mounted) return;
      AppRouter.navigateToLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou ícone do app
            const Icon(
              Icons.music_note,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Let\'s Jam',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
} 