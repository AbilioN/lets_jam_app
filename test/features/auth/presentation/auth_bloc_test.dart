import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:letsjam/features/auth/domain/usecases/login_usecase.dart';
import 'package:letsjam/features/auth/domain/entities/user.dart';
import 'package:letsjam/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:letsjam/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginUseCase(mockRepository);
  });

  final tEmail = 'user@email.com';
  final tPassword = 'password123';
  final tUser = User(id: '1', email: tEmail, name: 'Usuário Teste');
  final tParams = LoginParams(email: tEmail, password: tPassword);

  test('deve retornar User em caso de sucesso', () async {
    when(() => mockRepository.login(any(), any()))
        .thenAnswer((_) async => Right(tUser));

    final result = await usecase(tParams);

    expect(result, Right(tUser));
    verify(() => mockRepository.login(tEmail, tPassword)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('deve retornar Failure em caso de erro', () async {
    when(() => mockRepository.login(any(), any()))
        .thenAnswer((_) async => Left(ServerFailure('Erro')));

    final result = await usecase(tParams);

    expect(result, Left(ServerFailure('Erro')));
    verify(() => mockRepository.login(tEmail, tPassword)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
