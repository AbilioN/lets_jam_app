import '../../../../core/services/http_service.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/di/injection.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatsApi {
  final HttpService _httpService;
  final TokenService _tokenService;

  ChatsApi(this._httpService) : _tokenService = getIt<TokenService>();

  Future<ChatsResponse> getChats() async {
    try {
      print('🔵 ChatsApi - Chamando endpoint: /chats');
      
      // Verificar token de autenticação
      final token = await _tokenService.getToken();
      print('🔵 ChatsApi - Token disponível: ${token != null && token.isNotEmpty ? 'Sim' : 'Não'}');
      if (token != null && token.isNotEmpty) {
        print('🔵 ChatsApi - Token: ${token.substring(0, 20)}...');
      }
      
      // Log da URL completa
      print('🔵 ChatsApi - URL base configurada no HttpService');
      
      final response = await _httpService.get('/chats');
      print('🔵 ChatsApi - Resposta getChats: $response');
      print('🔵 ChatsApi - Tipo da resposta: ${response.runtimeType}');
      
      // Log adicional para debug
      if (response != null) {
        print('🔵 ChatsApi - Resposta não é null');
        if (response is Map<String, dynamic>) {
          print('🔵 ChatsApi - Chaves da resposta: ${response.keys.toList()}');
        }
      } else {
        print('🔴 ChatsApi - Resposta é null!');
      }
      
      // Deixar a validação para o fromJson
      return ChatsResponse.fromJson(response);
    } catch (e) {
      print('🔴 ChatsApi - Erro getChats: $e');
      throw Exception('Erro ao buscar chats: $e');
    }
  }

  Future<MessagesResponse> getChatMessages(String chatId, {int page = 1, int perPage = 50}) async {
    try {
      final response = await _httpService.get('/chat/$chatId/messages?page=$page&per_page=$perPage');
      return MessagesResponse.fromJson(response);
    } catch (e, st) {
      throw Exception('Erro ao buscar mensagens do chat: $e');
    }
  }

  Future<void> sendMessage(String chatId, String content, {String? replyToId}) async {
    final body = <String, dynamic>{
      'content': content,
      'message_type': 'text',
    };
    if (replyToId != null) body['reply_to_id'] = replyToId;
    await _httpService.post('/chat/$chatId/send', body);
  }

  Future<void> editMessage(String chatId, String messageId, String content) async {
    await _httpService.patch('/chat/$chatId/messages/$messageId', {'content': content});
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _httpService.delete('/chat/$chatId/messages/$messageId');
  }

  Future<void> markChatAsRead(String chatId) async {
    await _httpService.post('/chat/$chatId/read', {});
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await _httpService.get('/users/search?q=${Uri.encodeComponent(query)}');
    final data = response['data'] ?? response;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }
}
