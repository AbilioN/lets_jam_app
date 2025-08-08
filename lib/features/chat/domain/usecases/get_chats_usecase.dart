import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/chat_model.dart';
import '../repositories/chats_repository.dart';

class GetChatsUseCase implements UseCase<ChatsResponse, NoParams> {
  final ChatsRepository _repository;

  GetChatsUseCase(this._repository);

  @override
  Future<Either<Failure, ChatsResponse>> call(NoParams params) async {
    try {
      final chats = await _repository.getChats();
      return Right(chats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
