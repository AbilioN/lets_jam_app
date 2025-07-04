import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register(String name, String email, String password, String passwordConfirmation);
  Future<Either<Failure, Map<String, String>>> verifyEmail(String email, String code);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
} 