import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/message_model.dart';
import '../repositories/chats_repository.dart';

class GetChatMessagesParams {
  final int chatId;
  final int page;
  final int perPage;

  GetChatMessagesParams({
    required this.chatId,
    this.page = 1,
    this.perPage = 50,
  });
}

class GetChatMessagesUseCase implements UseCase<MessagesResponse, GetChatMessagesParams> {
  final ChatsRepository _repository;

  GetChatMessagesUseCase(this._repository);

  @override
  Future<Either<Failure, MessagesResponse>> call(GetChatMessagesParams params) async {
    try {
      final messages = await _repository.getChatMessages(
        params.chatId,
        page: params.page,
        perPage: params.perPage,
      );
      return Right(messages);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
