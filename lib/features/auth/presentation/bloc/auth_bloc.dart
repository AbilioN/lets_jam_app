import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_email_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/pusher_service.dart' as pusher_service;

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyEmailUseCase verifyEmailUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.verifyEmailUseCase,
    required this.forgotPasswordUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<VerifyEmailRequested>(_onVerifyEmailRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<LoadProfileRequested>(_onLoadProfileRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🟠 AuthBloc - Iniciando login...');
    print('   Email: ${event.email}');
    print('   Password: ${event.password}');
    
    emit(AuthLoading());
    
    try {
      final result = await loginUseCase(LoginParams(
        email: event.email,
        password: event.password,
      ));

      print('🟠 AuthBloc - Resultado do UseCase:');
      print('   Result: $result');
      print('   É Right? ${result.isRight()}');
      print('   É Left? ${result.isLeft()}');

      result.fold(
        (failure) {
          print('🔴 AuthBloc - Falha no login: ${failure.message}');
          emit(AuthError(failure.message));
        },
        (user) async {
          print('🟢 AuthBloc - Login bem-sucedido:');
          print('   User ID: ${user.id}');
          print('   User Name: ${user.name}');
          print('   User Email: ${user.email}');
          emit(AuthAuthenticated(user));

          // Subscribe to personal channel for all-chat real-time events
          if (user.channel != null) {
            final personalChannel = 'private-${user.channel}';
            try {
              await pusher_service.PusherService.subscribeToPersonalChannel(personalChannel);
            } catch (e) {
              print('🔴 AuthBloc - Failed to subscribe to personal channel: $e');
            }
          }
        },
      );
    } catch (e) {
      print('🔴 AuthBloc - Erro inesperado no login: $e');
      emit(AuthError('Erro inesperado: $e'));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🟠 AuthBloc - Iniciando registro...');
    print('Nome: ${event.name}');
    print('Email: ${event.email}');
    print('Password: ${event.password}');
    print('Password Confirmation: ${event.passwordConfirmation}');
    
    emit(AuthLoading());
    
    final result = await registerUseCase(RegisterParams(
      name: event.name,
      email: event.email,
      password: event.password,
      passwordConfirmation: event.passwordConfirmation,
    ));

    print('🟠 AuthBloc - Resultado do UseCase:');
    print('   Result: $result');
    print('   É Right? ${result.isRight()}');
    print('   É Left? ${result.isLeft()}');
    
    result.fold(
      (failure) {
        print('🔴 AuthBloc - Falha: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        print('🟢 AuthBloc - Sucesso:');
        print('   User ID: ${user.id}');
        print('   User Name: ${user.name}');
        print('   User Email: ${user.email}');
        emit(AuthRegistrationSuccess(
          message: "User registered successfully. Please check your email for verification code.",
          email: user.email,
        ));
      },
    );
  }

  Future<void> _onVerifyEmailRequested(
    VerifyEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🟠 AuthBloc - Iniciando verificação de email...');
    print('   Email: ${event.email}');
    print('   Código: ${event.code}');
    print('   Código length: ${event.code.length}');
    
    emit(AuthLoading());
    
    final result = await verifyEmailUseCase(VerifyEmailParams(
      email: event.email,
      code: event.code,
    ));

    print('🟠 AuthBloc - Resultado do UseCase:');
    print('   Result: $result');
    print('   É Right? ${result.isRight()}');
    print('   É Left? ${result.isLeft()}');

    result.fold(
      (failure) {
        print('🔴 AuthBloc - Falha na verificação: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (verificationResult) {
        print('🟢 AuthBloc - Verificação bem-sucedida:');
        print('   Message: ${verificationResult['message']}');
        print('   Email: ${verificationResult['email']}');
        emit(AuthEmailVerified(
          message: verificationResult['message']!,
          email: verificationResult['email']!,
        ));
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await pusher_service.PusherService.unsubscribeFromPersonalChannel();
    await pusher_service.PusherService.unsubscribeFromAllChats();
    emit(AuthUnauthenticated());
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await forgotPasswordUseCase(ForgotPasswordParams(email: event.email));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (message) => emit(PasswordResetEmailSent(message: message)),
    );
  }

  Future<void> _onLoadProfileRequested(
    LoadProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.getProfile();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(ProfileLoaded(user)),
    );
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.updateProfile(event.name);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(ProfileUpdated(user)),
    );
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await authRepository.changePassword(
      event.currentPassword,
      event.newPassword,
      event.confirmation,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(PasswordChanged()),
    );
  }
} 