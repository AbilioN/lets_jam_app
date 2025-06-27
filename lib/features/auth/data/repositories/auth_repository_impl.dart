import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    print('🟡 AuthRepository - Iniciando login...');
    print('   Email: $email');
    print('   Password: $password');
    
    if (await networkInfo.isConnected) {
      print('🟢 AuthRepository - Conexão com internet OK');
      try {
        print('🟡 AuthRepository - Chamando remoteDataSource.login...');
        final user = await remoteDataSource.login(email, password);
        print('🟢 AuthRepository - Login bem-sucedido no remoteDataSource');
        print('   User ID: ${user.id}');
        print('   User Name: ${user.name}');
        print('   User Email: ${user.email}');
        
        print('🟡 AuthRepository - Salvando usuário no cache...');
        await localDataSource.cacheUser(user);
        print('🟢 AuthRepository - Usuário salvo no cache');
        
        return Right(user);
      } catch (e) {
        print('🔴 AuthRepository - Erro no login: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('🔴 AuthRepository - Sem conexão com internet');
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> register(String name, String email, String password, String passwordConfirmation) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.register(name, email, password, passwordConfirmation);
        await localDataSource.cacheUser(user);
        return Right(user);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCachedUser();
      return Right(user);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, String>>> verifyEmail(String email, String code) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.verifyEmail(email, code);
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
} 