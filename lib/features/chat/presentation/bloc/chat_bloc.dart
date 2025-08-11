import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/di/injection.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService = ChatService.instance;
  final GetChatMessagesUseCase _getChatMessagesUseCase;

  ChatBloc() : _getChatMessagesUseCase = getIt<GetChatMessagesUseCase>(), super(ChatInitial()) {
    on<ChatInitialized>(_onChatInitialized);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
    on<LoadConversation>(_onLoadConversation);
    on<LoadChatMessages>(_onLoadChatMessages);
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
      // TODO: Descomentar quando WebSocket estiver funcionando
      // Configurar callbacks do ChatService
      // ChatService.onMessageReceived = (message) {
      //   add(MessageReceived(message: message));
      // };
      
      // ChatService.onError = (error) {
      //   print('🔴 ChatBloc - Erro do ChatService: $error');
      // };
      
      // Inicializar ChatService (apenas para manter referência)
      // await _chatService.initialize();
      
      // Se um chatId foi especificado, carregar mensagens via API
      if (event.chatId != null) {
        // TODO: Descomentar quando WebSocket estiver funcionando
        // await _chatService.listenToChat(event.chatId!);
        
        // Carregar mensagens do chat via API
        final result = await _getChatMessagesUseCase(
          GetChatMessagesParams(chatId: event.chatId!),
        );
        
        result.fold(
          (failure) => emit(ChatError('Erro ao carregar mensagens: $failure')),
          (messagesResponse) {
            // Converter MessageModel para ChatMessage
            final messages = messagesResponse.messages.map((message) => 
              ChatMessage(
                id: message.id,
                chatId: message.chatId,
                content: message.content,
                senderId: message.senderId,
                senderType: message.senderType,
                isRead: message.isRead,
                createdAt: DateTime.parse(message.createdAt),
              )
            ).toList();
            
            emit(ChatConnected(
              chatId: event.chatId,
              messages: messages,
              chats: [], // Lista vazia por enquanto, será preenchida quando WebSocket funcionar
            ));
          },
        );
      } else {
        // Se não há chatId, emitir estado conectado sem mensagens
        emit(ChatConnected(
          chatId: event.chatId,
          messages: [],
          chats: [],
        ));
      }
      
    } catch (e) {
      emit(ChatError('Erro ao carregar mensagens: $e'));
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
        
        // TODO: Descomentar quando WebSocket estiver funcionando
        // ChatMessage message;
        
        if (event.chatId != null) {
          // Enviar mensagem para chat específico
          // message = await _chatService.sendMessageToChat(
          //   chatId: event.chatId!,
          //   content: event.content,
          // );
          
          // FAKE: Simular mensagem enviada temporariamente
          final fakeMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch,
            chatId: event.chatId!,
            content: event.content,
            senderId: 1, // TODO: Obter ID do usuário atual
            senderType: 'user',
            isRead: false,
            createdAt: DateTime.now(),
          );
          
          // Adicionar mensagem ao estado atual
          final updatedMessages = List<ChatMessage>.from(currentState.messages)..add(fakeMessage);
          
          emit(ChatConnected(
            chatId: currentState.chatId,
            messages: updatedMessages,
            chats: currentState.chats,
          ));
        } else {
          // Enviar mensagem para usuário (cria/usa chat privado)
          // message = await _chatService.sendMessageToUser(
          //   content: event.content,
          //   otherUserId: event.otherUserId!,
          //   otherUserType: event.otherUserType!,
          // );
          
          // FAKE: Simular mensagem enviada temporariamente
          final fakeMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch,
            chatId: 0, // Chat temporário
            content: event.content,
            senderId: 1, // TODO: Obter ID do usuário atual
            senderType: 'user',
            isRead: false,
            createdAt: DateTime.now(),
          );
          
          // Adicionar mensagem ao estado atual
          final updatedMessages = List<ChatMessage>.from(currentState.messages)..add(fakeMessage);
          
          emit(ChatConnected(
            chatId: currentState.chatId,
            messages: updatedMessages,
            chats: currentState.chats,
          ));
        }
        
        // TODO: Descomentar quando WebSocket estiver funcionando
        // A mensagem será adicionada através do evento MessageReceived
        // que é disparado pelo callback do ChatService
        
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
      
      // TODO: Descomentar quando WebSocket estiver funcionando
      // emit(ChatConnected(
      //   chatId: currentState.chatId,
      //   messages: ChatService.messages,
      //   chats: ChatService.chats,
      // ));
      
      // Por enquanto, apenas manter o estado atual
      // As mensagens são gerenciadas via API
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
        
        // TODO: Descomentar quando WebSocket estiver funcionando
        // final conversation = await _chatService.getConversation(
        //   otherUserId: event.otherUserId,
        //   otherUserType: event.otherUserType,
        //   page: event.page,
        //   perPage: event.perPage,
        // );
        
        // Escutar o chat da conversa
        // await _chatService.listenToChat(conversation.chat.id);
        
        // Por enquanto, apenas emitir erro
        emit(ChatError('Funcionalidade de conversa não implementada ainda (WebSocket desabilitado)'));
        
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
        
        // TODO: Descomentar quando WebSocket estiver funcionando
        // final chats = await _chatService.getChats(
        //   page: event.page,
        //   perPage: event.perPage,
        // );
        
        // Por enquanto, apenas voltar ao estado anterior
        // Os chats são carregados via ChatsBloc separadamente
        emit(currentState);
        
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
        
        // TODO: Descomentar quando WebSocket estiver funcionando
        // final chat = await _chatService.createPrivateChat(
        //   otherUserId: event.otherUserId,
        //   otherUserType: event.otherUserType,
        // );
        
        // Escutar o novo chat
        // await _chatService.listenToChat(chat.id);
        
        // Por enquanto, apenas emitir erro
        emit(ChatError('Funcionalidade de criar chat privado não implementada ainda (WebSocket desabilitado)'));
        
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
        
        // TODO: Descomentar quando WebSocket estiver funcionando
        // final chat = await _chatService.createGroupChat(
        //   name: event.name,
        //   description: event.description,
        //   participants: event.participants,
        // );
        
        // Escutar o novo chat
        // await _chatService.listenToChat(chat.id);
        
        // Por enquanto, apenas emitir erro
        emit(ChatError('Funcionalidade de criar chat em grupo não implementada ainda (WebSocket desabilitado)'));
        
      } catch (e) {
        emit(ChatError('Erro ao criar chat em grupo: $e'));
      }
    }
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatLoading());
      
      final result = await _getChatMessagesUseCase(
        GetChatMessagesParams(
          chatId: event.chatId,
          page: event.page,
          perPage: event.perPage,
        ),
      );
      
      result.fold(
        (failure) => emit(ChatError(failure.toString())),
        (messagesResponse) {
          // Converter MessageModel para ChatMessage
          final messages = messagesResponse.messages.map((message) => 
            ChatMessage(
              id: message.id,
              chatId: message.chatId,
              content: message.content,
              senderId: message.senderId,
              senderType: message.senderType,
              isRead: message.isRead,
              createdAt: DateTime.parse(message.createdAt),
            )
          ).toList();
          
          emit(ChatConnected(
            chatId: event.chatId,
            messages: messages,
            chats: [], // TODO: Usar ChatService.chats quando WebSocket estiver funcionando
          ));
        },
      );
      
    } catch (e) {
      emit(ChatError('Erro ao carregar mensagens: $e'));
    }
  }

  Future<void> _onChatDisconnected(
    ChatDisconnected event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // TODO: Descomentar quando WebSocket estiver funcionando
      // await _chatService.disconnect();
      
      // Por enquanto, apenas emitir estado desconectado
      emit(ChatDisconnectedState());
    } catch (e) {
      emit(ChatError('Erro ao desconectar: $e'));
    }
  }
} 