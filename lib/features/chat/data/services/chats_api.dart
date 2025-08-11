import '../../../../core/services/http_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatsApi {
  final HttpService _httpService;

  ChatsApi(this._httpService);

  Future<ChatsResponse> getChats() async {
    try {
      final response = await _httpService.get('/chats');
      return ChatsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao buscar chats: $e');
    }
  }

  Future<MessagesResponse> getChatMessages(int chatId, {int page = 1, int perPage = 50}) async {
    try {
      final response = await _httpService.get('/chat/$chatId/messages?page=$page&per_page=$perPage');
      return MessagesResponse.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao buscar mensagens do chat: $e');
    }
  }
}
