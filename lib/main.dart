import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/routes/app_router.dart';
import 'core/services/pusher_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  
  // Inicializar PusherService
  try {
    await PusherService.initialize();
    print('🟢 Main - PusherService inicializado com sucesso');
    
    // Testar conexão
    // await PusherService.testConnection();
    
    // Testar inscrição em canal de chat específico
    print('🧪 Main - Testando inscrição em canal chat.12');
    await PusherService.testChatChannelSubscription(12);
    
  } catch (e) {
    print('🔴 Main - Erro ao inicializar PusherService: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>(),
      child: MaterialApp(
        title: 'Let\'s Jam',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

