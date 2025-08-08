import '../../../../core/services/http_service.dart';
import '../models/chat_model.dart';

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
}
