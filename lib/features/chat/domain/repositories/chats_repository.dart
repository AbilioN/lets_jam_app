import '../../data/models/chat_model.dart';

abstract class ChatsRepository {
  Future<ChatsResponse> getChats();
}
