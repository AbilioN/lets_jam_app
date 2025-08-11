import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';

abstract class ChatsRepository {
  Future<ChatsResponse> getChats();
  Future<MessagesResponse> getChatMessages(int chatId, {int page, int perPage});
}
