import '../../data/models/conversation_model.dart';

abstract class ConversationsRepository {
  Future<ConversationsResponse> getConversations();
} 