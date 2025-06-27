import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/chat_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService = ChatService.instance;

  ChatBloc() : super(ChatInitial()) {
    on<ChatInitialized>(_onChatInitialized);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
    on<LoadConversation>(_onLoadConversation);
    on<LoadConversations>(_onLoadConversations);
    on<ChatDisconnected>(_onChatDisconnected);
  }

  Future<void> _onChatInitialized(
    ChatInitialized event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    
    try {
      // Configurar callbacks do ChatService
      ChatService.onMessageReceived = (message) {
        add(MessageReceived(message: message));
      };
      
      ChatService.onError = (error) {
        print('🔴 ChatBloc - Erro do ChatService: $error');
      };
      
      // Inicializar ChatService
      await _chatService.initialize();
      
      // Escutar conversa se especificada
      if (event.otherUserId != null) {
        await _chatService.listenToConversation(
          event.currentUserId,
          event.otherUserId!,
        );
      }
      
      emit(ChatConnected(
        currentUserId: event.currentUserId,
        otherUserId: event.otherUserId,
        messages: ChatService.messages,
        conversations: ChatService.conversations,
      ));
      
    } catch (e) {
      emit(ChatError('Erro ao conectar ao chat: $e'));
    }
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      
      try {
        emit(ChatLoading());
        
        await _chatService.sendMessage(
          content: event.content,
          receiverType: event.receiverType,
          receiverId: event.receiverId,
        );
        
        // A mensagem será adicionada através do evento MessageReceived
        // que é disparado pelo callback do ChatService
        
        emit(ChatConnected(
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
          messages: ChatService.messages,
          conversations: ChatService.conversations,
        ));
        
      } catch (e) {
        emit(ChatError('Erro ao enviar mensagem: $e'));
      }
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      
      emit(ChatConnected(
        currentUserId: currentState.currentUserId,
        otherUserId: currentState.otherUserId,
        messages: ChatService.messages,
        conversations: ChatService.conversations,
      ));
    }
  }

  Future<void> _onLoadConversation(
    LoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      
      try {
        emit(ChatLoading());
        
        final messages = await _chatService.getConversation(
          otherUserType: event.otherUserType,
          otherUserId: event.otherUserId,
          page: event.page,
          perPage: event.perPage,
        );
        
        emit(ChatConnected(
          currentUserId: currentState.currentUserId,
          otherUserId: event.otherUserId,
          messages: messages,
          conversations: ChatService.conversations,
        ));
        
      } catch (e) {
        emit(ChatError('Erro ao carregar conversa: $e'));
      }
    }
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      
      try {
        emit(ChatLoading());
        
        final conversations = await _chatService.getConversations();
        
        emit(ChatConnected(
          currentUserId: currentState.currentUserId,
          otherUserId: currentState.otherUserId,
          messages: ChatService.messages,
          conversations: conversations,
        ));
        
      } catch (e) {
        emit(ChatError('Erro ao carregar conversas: $e'));
      }
    }
  }

  Future<void> _onChatDisconnected(
    ChatDisconnected event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatService.disconnect();
      emit(ChatDisconnectedState());
    } catch (e) {
      emit(ChatError('Erro ao desconectar: $e'));
    }
  }
} 