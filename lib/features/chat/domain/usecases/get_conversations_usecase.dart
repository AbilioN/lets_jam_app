import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/conversation_model.dart';
import '../repositories/conversations_repository.dart';

class GetConversationsUseCase implements UseCase<ConversationsResponse, NoParams> {
  final ConversationsRepository _repository;

  GetConversationsUseCase(this._repository);

  @override
  Future<Either<Failure, ConversationsResponse>> call(NoParams params) async {
    try {
      final conversations = await _repository.getConversations();
      return Right(conversations);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
} 