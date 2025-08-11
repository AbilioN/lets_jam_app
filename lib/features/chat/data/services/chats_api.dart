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

  Future<MessagesResponse> getChatMessages(int chatId, {int page = 1, int perPage = 50}) async {
    try {
      // URL correta: /chat/{chatId}/messages
      final response = await _httpService.get('/chat/$chatId/messages?page=$page&per_page=$perPage');
      print('🔵 ChatsApi - Resposta getChatMessages: $response');
      print('🔵 ChatsApi - Tipo da resposta: ${response.runtimeType}');
      
      // Deixar a validação para o fromJson
      return MessagesResponse.fromJson(response);
    } catch (e) {
      print('🔴 ChatsApi - Erro getChatMessages: $e');
      throw Exception('Erro ao buscar mensagens do chat: $e');
    }
  }
}
