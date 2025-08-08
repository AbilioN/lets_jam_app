import '../../data/models/chat_model.dart';
import '../../data/services/chats_api.dart';
import '../../domain/repositories/chats_repository.dart';

class ChatsRepositoryImpl implements ChatsRepository {
  final ChatsApi _chatsApi;

  ChatsRepositoryImpl(this._chatsApi);

  @override
  Future<ChatsResponse> getChats() async {
    return await _chatsApi.getChats();
  }
}
