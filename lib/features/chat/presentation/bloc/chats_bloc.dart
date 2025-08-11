import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/di/injection.dart';
import '../../domain/usecases/get_chats_usecase.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import 'chats_event.dart';
import 'chats_state.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final GetChatsUseCase _getChatsUseCase;
  final GetChatMessagesUseCase _getChatMessagesUseCase;

  ChatsBloc(this._getChatsUseCase) 
      : _getChatMessagesUseCase = getIt<GetChatMessagesUseCase>(),
        super(ChatsInitial()) {
    on<LoadChats>(_onLoadChats);
    on<LoadChatMessages>(_onLoadChatMessages);
  }

  Future<void> _onLoadChats(
    LoadChats event,
    Emitter<ChatsState> emit,
  ) async {
    emit(ChatsLoading());

    final result = await _getChatsUseCase(NoParams());

    result.fold(
      (failure) => emit(ChatsError(failure.toString())),
      (chatsResponse) => emit(ChatsLoaded(chatsResponse.chats)),
    );
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatsState> emit,
  ) async {
    // Este evento é usado para pré-carregar mensagens antes de navegar
    // Não emite um novo estado, apenas executa a busca
    try {
      await _getChatMessagesUseCase(
        GetChatMessagesParams(
          chatId: event.chatId,
          page: event.page,
          perPage: event.perPage,
        ),
      );
    } catch (e) {
      // Silenciosamente ignora erros de pré-carregamento
      print('Erro ao pré-carregar mensagens: $e');
    }
  }
}
