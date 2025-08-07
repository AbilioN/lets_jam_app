import '../../domain/repositories/conversations_repository.dart';
import '../models/conversation_model.dart';
import '../services/conversations_api.dart';

class ConversationsRepositoryImpl implements ConversationsRepository {
  final ConversationsApi _api;

  ConversationsRepositoryImpl(this._api);

  @override
  Future<ConversationsResponse> getConversations() async {
    return await _api.getConversations();
  }
} 