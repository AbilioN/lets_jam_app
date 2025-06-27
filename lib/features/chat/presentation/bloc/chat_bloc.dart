import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/pusher_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatInitial()) {
    on<ChatInitialized>(_onChatInitialized);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
    on<UserJoined>(_onUserJoined);
    on<UserLeft>(_onUserLeft);
    on<ChatDisconnected>(_onChatDisconnected);
  }

  Future<void> _onChatInitialized(
    ChatInitialized event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    
    try {
      // Configurar callbacks do Pusher
      PusherService.onMessageReceived = (message, sender, timestamp) {
        add(MessageReceived(message: message, sender: sender, timestamp: timestamp));
      };
      
      PusherService.onUserJoined = (user, action) {
        add(UserJoined(user: user, action: action));
      };
      
      PusherService.onUserLeft = (user, action) {
        add(UserLeft(user: user, action: action));
      };
      
      // Inicializar Pusher e se inscrever no canal
      await PusherService.initialize();
      await PusherService.subscribeToChatChannel(event.channelName);
      
      // Notificar que o usuário entrou no canal
      await PusherService.joinChannel(event.channelName, event.currentUser);
      
      // Carregar mensagens existentes
      final messages = PusherService.messages;
      
      emit(ChatConnected(
        channelName: event.channelName,
        messages: messages,
        currentUser: event.currentUser,
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
        await PusherService.sendMessage(
          currentState.channelName,
          event.message,
          event.sender,
        );
        
        // A mensagem será adicionada através do evento MessageReceived
        // que é disparado pelo callback do Pusher
        
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
      final newMessage = ChatMessage(
        message: event.message,
        sender: event.sender,
        timestamp: event.timestamp,
      );
      
      final updatedMessages = List<ChatMessage>.from(currentState.messages)
        ..add(newMessage);
      
      emit(ChatConnected(
        channelName: currentState.channelName,
        messages: updatedMessages,
        currentUser: currentState.currentUser,
      ));
    }
  }

  void _onUserJoined(
    UserJoined event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      
      // Adicionar mensagem de sistema
      final systemMessage = ChatMessage(
        message: '${event.user} entrou no chat',
        sender: 'System',
        timestamp: DateTime.now().toIso8601String(),
      );
      
      final updatedMessages = List<ChatMessage>.from(currentState.messages)
        ..add(systemMessage);
      
      emit(ChatConnected(
        channelName: currentState.channelName,
        messages: updatedMessages,
        currentUser: currentState.currentUser,
      ));
    }
  }

  void _onUserLeft(
    UserLeft event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      
      // Adicionar mensagem de sistema
      final systemMessage = ChatMessage(
        message: '${event.user} saiu do chat',
        sender: 'System',
        timestamp: DateTime.now().toIso8601String(),
      );
      
      final updatedMessages = List<ChatMessage>.from(currentState.messages)
        ..add(systemMessage);
      
      emit(ChatConnected(
        channelName: currentState.channelName,
        messages: updatedMessages,
        currentUser: currentState.currentUser,
      ));
    }
  }

  Future<void> _onChatDisconnected(
    ChatDisconnected event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (state is ChatConnected) {
        final currentState = state as ChatConnected;
        // Notificar que o usuário saiu do canal
        await PusherService.leaveChannel(currentState.channelName, currentState.currentUser);
      }
      
      await PusherService.disconnect();
      emit(ChatDisconnectedState());
    } catch (e) {
      emit(ChatError('Erro ao desconectar: $e'));
    }
  }
} 