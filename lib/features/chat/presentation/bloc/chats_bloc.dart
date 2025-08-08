import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_chats_usecase.dart';
import 'chats_event.dart';
import 'chats_state.dart';

class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final GetChatsUseCase _getChatsUseCase;

  ChatsBloc(this._getChatsUseCase) : super(ChatsInitial()) {
    on<LoadChats>(_onLoadChats);
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
}
