import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/chat_service.dart' as chat_service;
import '../../../../core/services/pusher_service.dart' as pusher_service;
import '../../domain/usecases/get_chat_messages_usecase.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final chat_service.ChatService _chatService = chat_service.ChatService.instance;
  final GetChatMessagesUseCase _getChatMessagesUseCase;
  
  // Rastrear o chat ativo para gerenciar inscrições
  int? _currentChatId;

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
      // Se já estamos inscritos em outro chat, desinscrever primeiro
      if (_currentChatId != null && _currentChatId != event.chatId) {
        print('🟡 ChatBloc - Mudando de chat: $_currentChatId -> ${event.chatId}');
        print('🟡 ChatBloc - Desinscrevendo do canal anterior: private-chat.$_currentChatId');
        await pusher_service.PusherService.unsubscribeFromChat(_currentChatId!);
      }
      
      // Atualizar o chat ativo
      _currentChatId = event.chatId;
      
      // Configurar callbacks do PusherService para chat
      pusher_service.PusherService.onChatEvent = (chatId, eventType, data) {
        print('🔵 ChatBloc - Evento de chat recebido: $eventType para chat $chatId');
        print('🔵 ChatBloc - Dados do evento: $data');
        
        // Verificar se o evento é para o chat ativo
        if (chatId == _currentChatId.toString()) {
          print('🟢 ChatBloc - Evento é para o chat ativo: $chatId');
          
          // Processar diferentes tipos de eventos
          switch (eventType) {
            case 'message-sent':
              _processPusherMessage(chatId, data);
              break;
            case 'chat-message':
              _processPusherMessage(chatId, data);
              break;
            case 'user-joined':
              print('🟡 ChatBloc - Usuário entrou no chat: $data');
              break;
            case 'user-left':
              print('🟡 ChatBloc - Usuário saiu do chat: $data');
              break;
            default:
              print('🟡 ChatBloc - Evento não tratado: $eventType');
          }
        } else {
          print('🟡 ChatBloc - Evento não é para o chat ativo (${chatId} != ${_currentChatId})');
        }
      };
      
      // Inicializar PusherService se necessário
      if (event.chatId != null) {
        print('🟡 ChatBloc - Inscrevendo no canal: private-chat.${event.chatId}');
        
        // Inscrever no canal de chat específico
        await pusher_service.PusherService.subscribeToChat(event.chatId!);
        
        // Log do status após inscrição
        _logChannelStatus();
        
        // Carregar mensagens do chat via API
        final result = await _getChatMessagesUseCase(
          GetChatMessagesParams(chatId: event.chatId!),
        );
        
        result.fold(
          (failure) => emit(ChatError('Erro ao carregar mensagens: $failure')),
          (messagesResponse) {
            // Converter MessageModel para ChatMessage
            final messages = messagesResponse.messages.map((message) => 
              chat_service.ChatMessage(
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
              chats: [], // Lista vazia por enquanto
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
          final fakeMessage = chat_service.ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch,
            chatId: event.chatId!,
            content: event.content,
            senderId: 1, // TODO: Obter ID do usuário atual
            senderType: 'user',
            isRead: false,
            createdAt: DateTime.now(),
          );
          
          // Adicionar mensagem ao estado atual
          final updatedMessages = List<chat_service.ChatMessage>.from(currentState.messages)..add(fakeMessage);
          
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
          final fakeMessage = chat_service.ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch,
            chatId: 0, // Chat temporário
            content: event.content,
            senderId: 1, // TODO: Obter ID do usuário atual
            senderType: 'user',
            isRead: false,
            createdAt: DateTime.now(),
          );
          
          // Adicionar mensagem ao estado atual
          final updatedMessages = List<chat_service.ChatMessage>.from(currentState.messages)..add(fakeMessage);
          
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
      
      print('🔵 ChatBloc - Mensagem recebida: ${event.message.content}');
      print('🔵 ChatBloc - Chat ID: ${event.message.chatId}');
      print('🔵 ChatBloc - Remetente: ${event.message.senderId}');
      
      // Verificar se a mensagem é para o chat atual
      if (event.message.chatId == currentState.chatId) {
        // Adicionar a nova mensagem à lista existente
        final updatedMessages = List<chat_service.ChatMessage>.from(currentState.messages);
        
        // Verificar se a mensagem já existe (evitar duplicatas)
        final messageExists = updatedMessages.any((msg) => 
          msg.id == event.message.id || 
          (msg.content == event.message.content && 
           msg.senderId == event.message.senderId &&
           msg.createdAt.difference(event.message.createdAt).inSeconds.abs() < 5)
        );
        
        if (!messageExists) {
          updatedMessages.add(event.message);
          print('🟢 ChatBloc - Mensagem adicionada ao chat: ${event.message.content}');
          
          // Emitir novo estado com a mensagem adicionada
          emit(ChatConnected(
            chatId: currentState.chatId,
            messages: updatedMessages,
            chats: currentState.chats,
          ));
        } else {
          print('🟡 ChatBloc - Mensagem já existe, ignorando duplicata');
        }
      } else {
        print('🟡 ChatBloc - Mensagem não é para este chat (${event.message.chatId} != ${currentState.chatId})');
      }
    } else {
      print('🟡 ChatBloc - Estado não é ChatConnected, ignorando mensagem');
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
            chat_service.ChatMessage(
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
      // Desinscrever do chat ativo se houver
      if (_currentChatId != null) {
        print('🟡 ChatBloc - Desconectando do chat: $_currentChatId');
        print('🟡 ChatBloc - Desinscrevendo do canal: private-chat.$_currentChatId');
        await pusher_service.PusherService.unsubscribeFromChat(_currentChatId!);
        _currentChatId = null;
      }
      
      // TODO: Descomentar quando WebSocket estiver funcionando
      // await _chatService.disconnect();
      
      // Por enquanto, apenas emitir estado desconectado
      emit(ChatDisconnectedState());
    } catch (e) {
      emit(ChatError('Erro ao desconectar: $e'));
    }
  }

  void _processPusherMessage(String chatId, Map<String, dynamic> data) {
    print('🔵 ChatBloc - Processando mensagem do Pusher para chat: $chatId');
    print('🔵 ChatBloc - Dados brutos: $data');
    print('🔵 ChatBloc - Tipo dos dados: ${data.runtimeType}');
    
    final messageContent = data['message'] as String?;
    final senderId = data['sender_id'] as int?;
    final senderType = data['sender_type'] as String?;
    final createdAt = data['created_at'] as String?;

    print('🔵 ChatBloc - message: $messageContent');
    print('🔵 ChatBloc - sender_id: $senderId (tipo: ${senderId.runtimeType})');
    print('🔵 ChatBloc - sender_type: $senderType');
    print('🔵 ChatBloc - created_at: $createdAt');

    if (messageContent != null && senderId != null && senderType != null && createdAt != null) {
      final message = chat_service.ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch, // ID temporário
        chatId: int.parse(chatId), // Converter String para int
        content: messageContent,
        senderId: senderId,
        senderType: senderType,
        isRead: false,
        createdAt: DateTime.parse(createdAt),
      );
      
      print('🟢 ChatBloc - Mensagem criada com sucesso: ${message.content}');
      add(MessageReceived(message: message));
    } else {
      print('🔴 ChatBloc - Dados de mensagem incompletos do Pusher: $data');
      print('🔴 ChatBloc - message: $messageContent, sender_id: $senderId, sender_type: $senderType, created_at: $createdAt');
    }
  }

  /// Verifica o status das inscrições de canal
  void _logChannelStatus() {
    print('🔵 ChatBloc - Status das inscrições:');
    print('🔵 ChatBloc - Chat ativo: $_currentChatId');
    print('🔵 ChatBloc - Canais ativos no Pusher: ${pusher_service.PusherService.activeChannels}');
    print('🔵 ChatBloc - Estado da conexão: ${pusher_service.PusherService.connectionState}');
  }
} 