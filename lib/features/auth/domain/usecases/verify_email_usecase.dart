import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyEmailUseCase implements UseCase<Map<String, String>, VerifyEmailParams> {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, String>>> call(VerifyEmailParams params) async {
    return await repository.verifyEmail(params.email, params.code);
  }
}

class VerifyEmailParams extends Equatable {
  final String email;
  final String code;

  const VerifyEmailParams({
    required this.email,
    required this.code,
  });

  @override
  List<Object> get props => [email, code];
} 