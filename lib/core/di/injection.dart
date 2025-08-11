import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/network_info.dart';
import '../network/network_info_impl.dart';
import '../services/token_service.dart';
import '../services/http_service.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/services/auth_api.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/verify_email_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/chat/data/repositories/chats_repository_impl.dart';
import '../../features/chat/data/services/chats_api.dart';
import '../../features/chat/domain/repositories/chats_repository.dart';
import '../../features/chat/domain/usecases/get_chats_usecase.dart';
import '../../features/chat/domain/usecases/get_chat_messages_usecase.dart';
import '../../features/chat/presentation/bloc/chats_bloc.dart';
import '../services/chat_service.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Core
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  
  // External
  getIt.registerLazySingleton<Dio>(() => Dio());
  
  // SharedPreferences precisa ser registrado de forma assíncrona
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Services
  getIt.registerLazySingleton<TokenService>(
    () => TokenServiceImpl(getIt<SharedPreferences>()),
  );
  
  final baseUrl = 'http://10.0.2.2:8006/api';
  print('🔵 Injection - Configurando HttpService com baseUrl: $baseUrl');
  
  getIt.registerLazySingleton<HttpService>(
    () => HttpService(
      baseUrl: baseUrl,
      tokenService: getIt<TokenService>(),
    ),
  );

  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      getIt<TokenService>(),
      getIt<AuthApi>(),
    ),
  );
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt<SharedPreferences>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<VerifyEmailUseCase>(
    () => VerifyEmailUseCase(getIt<AuthRepository>()),
  );

  // Blocs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      verifyEmailUseCase: getIt<VerifyEmailUseCase>(),
    ),
  );

  // Additional services
  getIt.registerLazySingleton<AuthApi>(
    () => AuthApi(getIt<HttpService>()),
  );
  
  // Chat services
  getIt.registerLazySingleton<ChatsApi>(
    () => ChatsApi(getIt<HttpService>()),
  );
  
  // Chat repositories
  getIt.registerLazySingleton<ChatsRepository>(
    () => ChatsRepositoryImpl(getIt<ChatsApi>()),
  );
  
  // Chat use cases
  getIt.registerLazySingleton<GetChatsUseCase>(
    () => GetChatsUseCase(getIt<ChatsRepository>()),
  );
  
  getIt.registerLazySingleton<GetChatMessagesUseCase>(
    () => GetChatMessagesUseCase(getIt<ChatsRepository>()),
  );
  
  // Chat blocs
  getIt.registerFactory<ChatsBloc>(
    () => ChatsBloc(getIt<GetChatsUseCase>()),
  );
  
  // Configurar dependências do ChatService
  ChatService.configureDependencies(
    getIt<HttpService>(),
    getIt<TokenService>(),
  );
} 