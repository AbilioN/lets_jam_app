import '../../../../core/services/http_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatsApi {
  final HttpService _httpService;

  ChatsApi(this._httpService);

  Future<ChatsResponse> getChats() async {
    try {
      final response = await _httpService.get('/chats');
      print('🔵 ChatsApi - Resposta getChats: $response');
      return ChatsResponse.fromJson(response);
    } catch (e) {
      print('🔴 ChatsApi - Erro getChats: $e');
      throw Exception('Erro ao buscar chats: $e');
    }
  }

  Future<MessagesResponse> getChatMessages(int chatId, {int page = 1, int perPage = 50}) async {
    try {
      // Corrigir a URL para usar o formato correto da API
      final response = await _httpService.get('/chats/$chatId/messages?page=$page&per_page=$perPage');
      print('🔵 ChatsApi - Resposta getChatMessages: $response');
      print('🔵 ChatsApi - Tipo da resposta: ${response.runtimeType}');
      
      // Verificar se a resposta tem a estrutura esperada
      if (response is Map<String, dynamic>) {
        print('🔵 ChatsApi - Chaves da resposta: ${response.keys.toList()}');
        if (response.containsKey('data')) {
          print('🔵 ChatsApi - Chaves do data: ${response['data'].keys.toList()}');
        }
      }
      
      return MessagesResponse.fromJson(response);
    } catch (e) {
      print('🔴 ChatsApi - Erro getChatMessages: $e');
      throw Exception('Erro ao buscar mensagens do chat: $e');
    }
  }
}
