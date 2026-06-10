import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:convert'; // Added for json.decode
import '../../../../core/di/injection.dart';
import '../../../../core/services/chat_service.dart' as chat_service;
import '../../../../core/services/pusher_service.dart' as pusher_service;
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../../../core/services/http_service.dart' as http_service;
import '../../../auth/presentation/bloc/auth_bloc.dart' as auth_bloc;

part 'chat_event.dart';
part 'chat_state.dart';

// MySQL datetime uses a space separator; Dart's DateTime.parse requires 'T'.
DateTime _parseDate(String raw) => DateTime.parse(raw.replaceAll(' ', 'T'));

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final chat_service.ChatService _chatService = chat_service.ChatService.instance;
  final GetChatMessagesUseCase _getChatMessagesUseCase;
  
  // Rastrear o chat ativo para gerenciar inscrições
  String? _currentChatId;

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
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
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
        print('🟡 ChatBloc - Desinscrevendo do canal anterior: chat.$_currentChatId');
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
            case 'MessageSent':
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
      
      // Register personal channel callback so messages from any chat update this bloc
      pusher_service.PusherService.onChatMessageReceived = (msg) {
        add(MessageReceived(message: chat_service.ChatMessage(
          id: msg.id.toString(),
          chatId: msg.chatId.toString(),
          content: msg.content,
          senderId: msg.senderId.toString(),
          senderType: msg.senderType,
          isRead: msg.isRead,
          createdAt: msg.createdAt,
        )));
      };

      // Subscribe to per-chat private channel for typing indicators
      if (event.chatId != null) {
        print('🟡 ChatBloc - Inscrevendo no canal: private-chat.${event.chatId}');

        // Subscribe to private-chat.{chatId} for typing indicators only
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
                createdAt: _parseDate(message.createdAt),
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
      try {
        if (event.chatId != null) {
          // Enviar mensagem real via API
          final httpService = getIt<http_service.HttpService>();
          final response = await httpService.post(
            '/chat/${event.chatId}/send',
            {
              'content': event.content,
              'message_type': 'text',
            },
          );
          
          print('🟢 ChatBloc - Mensagem enviada via API: ${event.content}');
          print('🟢 ChatBloc - Response: $response');
          // Message is queued — Pusher will deliver it via MessageReceived.
          // Do NOT emit optimistically; that causes duplicates when the event arrives.
          
        } else {
          // Enviar mensagem para usuário (cria/usa chat privado)
          // TODO: Implementar quando WebSocket estiver funcionando
          emit(ChatError('Funcionalidade de chat privado não implementada ainda'));
        }
        
      } catch (e) {
        print('🔴 ChatBloc - Erro ao enviar mensagem: $e');
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
              createdAt: _parseDate(message.createdAt),
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
        print('🟡 ChatBloc - Desinscrevendo do canal: chat.$_currentChatId');
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

  void _processPusherMessage(String chatId, dynamic data) {
    print('🔵 ChatBloc - Processando mensagem do Pusher para chat: $chatId');
    print('🔵 ChatBloc - Dados brutos: $data');
    print('🔵 ChatBloc - Tipo dos dados: ${data.runtimeType}');
    
    Map<String, dynamic> messageData;
    
    // Verificar se os dados são uma String JSON e fazer parse
    if (data is String) {
      try {
        messageData = Map<String, dynamic>.from(json.decode(data));
        print('🟢 ChatBloc - JSON parseado com sucesso: $messageData');
      } catch (e) {
        print('🔴 ChatBloc - Erro ao fazer parse do JSON: $e');
        return;
      }
    } else if (data is Map<String, dynamic>) {
      messageData = data;
      print('🟢 ChatBloc - Dados já são Map: $messageData');
    } else {
      print('🔴 ChatBloc - Tipo de dados não suportado: ${data.runtimeType}');
      return;
    }
    
    final messageContent = messageData['content'] as String?;
    final senderId = messageData['sender_id'] != null ? messageData['sender_id'].toString() : null;
    final senderType = messageData['sender_type'] as String?;
    final createdAt = messageData['created_at'] as String?;

    print('🔵 ChatBloc - content: $messageContent');
    print('🔵 ChatBloc - sender_id: $senderId');
    print('🔵 ChatBloc - sender_type: $senderType');
    print('🔵 ChatBloc - created_at: $createdAt');

    if (messageContent != null && senderId != null && senderType != null && createdAt != null) {
      final message = chat_service.ChatMessage(
        id: messageData['id'] != null ? messageData['id'].toString() : DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: chatId,
        content: messageContent,
        senderId: senderId,
        senderType: senderType,
        isRead: messageData['is_read'] as bool? ?? false,
        createdAt: _parseDate(createdAt),
      );

      print('🟢 ChatBloc - Mensagem criada com sucesso: ${message.content}');
      add(MessageReceived(message: message));
    } else {
      print('🔴 ChatBloc - Dados de mensagem incompletos do Pusher: $messageData');
      print('🔴 ChatBloc - content: $messageContent, sender_id: $senderId, sender_type: $senderType, created_at: $createdAt');
    }
  }

  Future<void> _onStartTyping(
    StartTyping event,
    Emitter<ChatState> emit,
  ) async {
    final authState = getIt<auth_bloc.AuthBloc>().state;
    if (authState is auth_bloc.AuthAuthenticated) {
      await pusher_service.PusherService.triggerTyping(event.chatId, authState.user.id, true);
    }
  }

  Future<void> _onStopTyping(
    StopTyping event,
    Emitter<ChatState> emit,
  ) async {
    final authState = getIt<auth_bloc.AuthBloc>().state;
    if (authState is auth_bloc.AuthAuthenticated) {
      await pusher_service.PusherService.triggerTyping(event.chatId, authState.user.id, false);
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