import '../../../../core/services/http_service.dart';
import '../models/conversation_model.dart';

class ConversationsApi {
  final HttpService _httpService;

  ConversationsApi(this._httpService);

  Future<ConversationsResponse> getConversations() async {
    try {
      final response = await _httpService.get('/chat/conversations');
      return ConversationsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao buscar conversas: $e');
    }
  }
} 