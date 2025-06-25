part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthRegistrationSuccess extends AuthState {
  final String message;
  final String email;

  const AuthRegistrationSuccess({
    required this.message,
    required this.email,
  });

  @override
  List<Object> get props => [message, email];
}

class AuthEmailVerified extends AuthState {
  final String message;
  final String email;

  const AuthEmailVerified({
    required this.message,
    required this.email,
  });

  @override
  List<Object> get props => [message, email];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthUnauthenticated extends AuthState {} 