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
    on<LoadChats>(_onLoadChats);
    on<CreatePrivateChat>(_onCreatePrivateChat);
    on<CreateGroupChat>(_onCreateGroupChat);
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
      
      // Escutar chat se especificado
      if (event.chatId != null) {
        await _chatService.listenToChat(event.chatId!);
      }
      
      emit(ChatConnected(
        chatId: event.chatId,
        messages: ChatService.messages,
        chats: ChatService.chats,
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
        
        ChatMessage message;
        
        if (event.chatId != null) {
          // Enviar mensagem para chat específico
          message = await _chatService.sendMessageToChat(
            chatId: event.chatId!,
            content: event.content,
          );
        } else {
          // Enviar mensagem para usuário (cria/usa chat privado)
          message = await _chatService.sendMessageToUser(
            content: event.content,
            otherUserId: event.otherUserId!,
            otherUserType: event.otherUserType!,
          );
        }
        
        // A mensagem será adicionada através do evento MessageReceived
        // que é disparado pelo callback do ChatService
        
        emit(ChatConnected(
          chatId: currentState.chatId,
          messages: ChatService.messages,
          chats: ChatService.chats,
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
        chatId: currentState.chatId,
        messages: ChatService.messages,
        chats: ChatService.chats,
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
        
        final conversation = await _chatService.getConversation(
          otherUserId: event.otherUserId,
          otherUserType: event.otherUserType,
          page: event.page,
          perPage: event.perPage,
        );
        
        // Escutar o chat da conversa
        await _chatService.listenToChat(conversation.chat.id);
        
        emit(ChatConnected(
          chatId: conversation.chat.id,
          messages: conversation.messages,
          chats: ChatService.chats,
        ));
        
      } catch (e) {
        emit(ChatError('Erro ao carregar conversa: $e'));
      }
    }
  }

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      
      try {
        emit(ChatLoading());
        
        final chats = await _chatService.getChats(
          page: event.page,
          perPage: event.perPage,
        );
        
        emit(ChatConnected(
          chatId: currentState.chatId,
          messages: ChatService.messages,
          chats: chats,
        ));
        
      } catch (e) {
        emit(ChatError('Erro ao carregar chats: $e'));
      }
    }
  }

  Future<void> _onCreatePrivateChat(
    CreatePrivateChat event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      
      try {
        emit(ChatLoading());
        
        final chat = await _chatService.createPrivateChat(
          otherUserId: event.otherUserId,
          otherUserType: event.otherUserType,
        );
        
        // Escutar o novo chat
        await _chatService.listenToChat(chat.id);
        
        emit(ChatConnected(
          chatId: chat.id,
          messages: ChatService.messages,
          chats: ChatService.chats,
        ));
        
      } catch (e) {
        emit(ChatError('Erro ao criar chat privado: $e'));
      }
    }
  }

  Future<void> _onCreateGroupChat(
    CreateGroupChat event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      
      try {
        emit(ChatLoading());
        
        final chat = await _chatService.createGroupChat(
          name: event.name,
          description: event.description,
          participants: event.participants,
        );
        
        // Escutar o novo chat
        await _chatService.listenToChat(chat.id);
        
        emit(ChatConnected(
          chatId: chat.id,
          messages: ChatService.messages,
          chats: ChatService.chats,
        ));
        
      } catch (e) {
        emit(ChatError('Erro ao criar chat em grupo: $e'));
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