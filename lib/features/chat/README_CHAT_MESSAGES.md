# Funcionalidade de Mensagens de Chat

## Visão Geral

Esta funcionalidade permite buscar e exibir mensagens de um chat específico através da API REST.

## Endpoint da API

```
GET {{baseUrl}}/chat/{{chatId}}/messages?page={{page}}&per_page={{perPage}}
```

### Parâmetros de Query
- `page`: Número da página (padrão: 1)
- `per_page`: Mensagens por página (padrão: 50)

### Exemplo de Resposta

```json
{
    "success": true,
    "data": {
        "messages": [
            {
                "id": 1,
                "chat_id": 12,
                "content": "mensagem",
                "sender_id": 2,
                "sender_type": "user",
                "message_type": "text",
                "metadata": null,
                "is_read": false,
                "read_at": null,
                "created_at": "2025-08-08 11:32:19",
                "updated_at": null
            }
        ],
        "from_cache": false,
        "pagination": {
            "current_page": 1,
            "per_page": 50,
            "total": 1,
            "last_page": 1,
            "from": 1,
            "to": 1
        }
    }
}
```

## Arquitetura

### Modelos de Dados

#### MessageModel
Representa uma mensagem individual do chat com os seguintes campos:
- `id`: ID único da mensagem
- `chatId`: ID do chat ao qual a mensagem pertence
- `content`: Conteúdo da mensagem
- `senderId`: ID do remetente
- `senderType`: Tipo do remetente (ex: "user", "admin")
- `messageType`: Tipo da mensagem (ex: "text", "image")
- `metadata`: Dados adicionais da mensagem (opcional)
- `isRead`: Se a mensagem foi lida
- `readAt`: Timestamp de quando foi lida (opcional)
- `createdAt`: Timestamp de criação
- `updatedAt`: Timestamp de atualização (opcional)

#### MessagesResponse
Wrapper da resposta da API contendo:
- `messages`: Lista de mensagens
- `fromCache`: Se os dados vieram do cache
- `pagination`: Informações de paginação

### Camada de Dados

#### ChatsApi
```dart
Future<MessagesResponse> getChatMessages(int chatId, {int page = 1, int perPage = 50})
```

#### ChatsRepository
```dart
Future<MessagesResponse> getChatMessages(int chatId, {int page, int perPage})
```

### Casos de Uso

#### GetChatMessagesUseCase
```dart
class GetChatMessagesUseCase implements UseCase<MessagesResponse, GetChatMessagesParams>
```

Parâmetros:
- `chatId`: ID do chat
- `page`: Número da página
- `perPage`: Mensagens por página

### Camada de Apresentação

#### Eventos
- `LoadChatMessages`: Dispara a busca de mensagens de um chat específico

#### Estados
- `ChatLoading`: Carregando mensagens
- `ChatConnected`: Mensagens carregadas com sucesso
- `ChatError`: Erro ao carregar mensagens

## Como Usar

### 1. Carregar Mensagens ao Clicar em um Chat

```dart
// Na página de chats, ao clicar em um chat
context.read<ChatsBloc>().add(LoadChatMessages(chatId: chat.id));

// Navegar para o chat
AppRouter.navigateToChat(context, chatId: chat.id, chatName: chat.name);
```

### 2. Carregar Mensagens Automaticamente

```dart
// O ChatBloc carrega automaticamente as mensagens quando inicializado
ChatBloc()..add(ChatInitialized(chatId: chatId))
```

### 3. Buscar Mensagens Manualmente

```dart
// Em qualquer lugar do app
context.read<ChatBloc>().add(LoadChatMessages(
  chatId: chatId,
  page: 1,
  perPage: 50,
));
```

## Fluxo de Dados

1. **Usuário clica em um chat** na lista de chats
2. **ChatsBloc** dispara evento `LoadChatMessages`
3. **GetChatMessagesUseCase** é executado
4. **ChatsRepository** chama a API via **ChatsApi**
5. **Mensagens são convertidas** de `MessageModel` para `ChatMessage`
6. **ChatBloc** emite estado `ChatConnected` com as mensagens
7. **ChatWidget** exibe as mensagens na interface

## Tratamento de Erros

- Erros de rede são capturados e convertidos para `ServerFailure`
- Erros são exibidos na interface através de `SnackBar`
- Usuário pode tentar novamente através de botão de retry

## Paginação

A funcionalidade suporta paginação para chats com muitas mensagens:
- Padrão: 50 mensagens por página
- Parâmetros configuráveis via `page` e `perPage`
- Informações de paginação retornadas pela API

## Cache

A API pode retornar dados do cache (`from_cache: true`), mas a implementação atual não implementa cache local. Futuras versões podem incluir:
- Cache local com SQLite
- Sincronização com servidor
- Expiração de cache

## Testes

Testes unitários estão disponíveis para:
- `GetChatMessagesUseCase`
- Modelos de dados
- Repositórios

Execute os testes com:
```bash
flutter test test/features/chat/
```
