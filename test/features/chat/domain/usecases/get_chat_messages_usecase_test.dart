import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:letsjam/core/error/failures.dart';
import 'package:letsjam/features/chat/domain/repositories/chats_repository.dart';
import 'package:letsjam/features/chat/domain/usecases/get_chat_messages_usecase.dart';
import 'package:letsjam/features/chat/data/models/message_model.dart';

class MockChatsRepository extends Mock implements ChatsRepository {}

void main() {
  late GetChatMessagesUseCase useCase;
  late MockChatsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(1);
    registerFallbackValue(50);
  });

  setUp(() {
    mockRepository = MockChatsRepository();
    useCase = GetChatMessagesUseCase(mockRepository);
  });

  const tChatId = 12;
  const tPage = 1;
  const tPerPage = 50;

  final tMessages = [
    MessageModel(
      id: 1,
      chatId: 12,
      content: 'mensagem',
      senderId: 2,
      senderType: 'user',
      messageType: 'text',
      metadata: null,
      isRead: false,
      readAt: null,
      createdAt: '2025-08-08 11:32:19',
      updatedAt: null,
    ),
  ];

  final tMessagesResponse = MessagesResponse(
    messages: tMessages,
    fromCache: false,
    pagination: {
      'current_page': 1,
      'per_page': 50,
      'total': 1,
      'last_page': 1,
      'from': 1,
      'to': 1,
    },
  );

  test('should get chat messages from the repository', () async {
    // arrange
    when(() => mockRepository.getChatMessages(
      tChatId,
      page: tPage,
      perPage: tPerPage,
    )).thenAnswer((_) async => tMessagesResponse);

    // act
    final result = await useCase(GetChatMessagesParams(
      chatId: tChatId,
      page: tPage,
      perPage: tPerPage,
    ));

    // assert
    expect(result, Right(tMessagesResponse));
    verify(() => mockRepository.getChatMessages(
      tChatId,
      page: tPage,
      perPage: tPerPage,
    )).called(1);
  });

  test('should return ServerFailure when repository throws an exception', () async {
    // arrange
    when(() => mockRepository.getChatMessages(
      tChatId,
      page: tPage,
      perPage: tPerPage,
    )).thenThrow(Exception('Server error'));

    // act
    final result = await useCase(GetChatMessagesParams(
      chatId: tChatId,
      page: tPage,
      perPage: tPerPage,
    ));

    // assert
    expect(result, Left(ServerFailure('Exception: Server error')));
    verify(() => mockRepository.getChatMessages(
      tChatId,
      page: tPage,
      perPage: tPerPage,
    )).called(1);
  });
}
