# Chat System - Setup e Uso

## Visão Geral

O sistema de chat foi atualizado para usar uma infraestrutura baseada em **chats (chat_id)**, onde cada conversa tem um ID único. Isso permite:

- **Chats privados** entre dois usuários
- **Chats em grupo** com múltiplos participantes
- **Canais WebSocket** por chat (`chat.{chat_id}`)
- **Persistência** de conversas

## Nova Arquitetura

### Estrutura Baseada em Chats

```
Chat (chat_id) → Mensagens → Participantes
    ↓
Canal WebSocket: chat.{chat_id}
```

### Tipos de Chat

1. **Chat Privado**: Entre dois usuários (user/admin)
2. **Chat em Grupo**: Múltiplos participantes

## API Endpoints

### 1. Criar Chat Privado
```http
POST /api/chat/create-private
{
  "other_user_id": 2,
  "other_user_type": "user"
}
```

### 2. Criar Chat em Grupo
```http
POST /api/chat/create-group
{
  "name": "Grupo de Suporte",
  "description": "Chat para suporte geral",
  "participants": [
    {"user_id": 1, "user_type": "admin"},
    {"user_id": 2, "user_type": "user"}
  ]
}
```

### 3. Enviar Mensagem para Usuário
```http
POST /api/chat/send
{
  "content": "Olá! Como posso ajudar?",
  "other_user_id": 2,
  "other_user_type": "user"
}
```

### 4. Enviar Mensagem para Chat
```http
POST /api/chat/{chatId}/send
{
  "content": "Mensagem para o grupo!"
}
```

### 5. Buscar Conversa
```http
GET /api/chat/conversation/{otherUserId}/{otherUserType}?page=1&per_page=50
```

### 6. Listar Chats
```http
GET /api/chat/conversations?page=1&per_page=20
```

## WebSocket Events

### Canal
```
chat.{chat_id}
```

### Evento
```
MessageSent
```

### Payload
```json
{
  "id": 10,
  "chat_id": 1,
  "content": "Olá! Como posso ajudar?",
  "sender_type": "admin",
  "sender_id": 1,
  "is_read": false,
  "created_at": "2025-06-27 21:30:00"
}
```

## Uso no Flutter

### 1. Inicialização

```dart
// Inicializar ChatService
final chatService = ChatService.instance;
await chatService.initialize();

// Configurar callbacks
ChatService.onMessageReceived = (message) {
  print('Nova mensagem: ${message.content}');
};

ChatService.onError = (error) {
  print('Erro: $error');
};
```

### 2. Criar Chat Privado

```dart
final chat = await chatService.createPrivateChat(
  otherUserId: 2,
  otherUserType: 'user',
);

// Escutar o chat
await chatService.listenToChat(chat.id);
```

### 3. Criar Chat em Grupo

```dart
final groupChat = await chatService.createGroupChat(
  name: 'Grupo de Suporte',
  description: 'Chat para suporte geral',
  participants: [
    ChatParticipant(userId: 1, userType: 'admin'),
    ChatParticipant(userId: 2, userType: 'user'),
  ],
);

await chatService.listenToChat(groupChat.id);
```

### 4. Enviar Mensagens

```dart
// Para chat específico
await chatService.sendMessageToChat(
  chatId: 1,
  content: 'Mensagem para o chat',
);

// Para usuário (cria/usa chat privado)
await chatService.sendMessageToUser(
  content: 'Olá!',
  otherUserId: 2,
  otherUserType: 'user',
);
```

### 5. Buscar Conversas

```dart
// Buscar conversa com usuário
final conversation = await chatService.getConversation(
  otherUserId: 2,
  otherUserType: 'user',
  page: 1,
  perPage: 50,
);

// Listar todos os chats
final chats = await chatService.getChats(
  page: 1,
  perPage: 20,
);
```

## Uso com BLoC

### 1. Inicializar Chat

```dart
context.read<ChatBloc>().add(
  ChatInitialized(chatId: 1),
);
```

### 2. Enviar Mensagem

```dart
context.read<ChatBloc>().add(
  MessageSent(
    content: 'Olá!',
    chatId: 1, // Para chat específico
    // OU
    otherUserId: 2, // Para criar/usar chat privado
    otherUserType: 'user',
  ),
);
```

### 3. Carregar Conversa

```dart
context.read<ChatBloc>().add(
  LoadConversation(
    otherUserId: 2,
    otherUserType: 'user',
  ),
);
```

### 4. Listar Chats

```dart
context.read<ChatBloc>().add(
  LoadChats(page: 1, perPage: 20),
);
```

### 5. Criar Chats

```dart
// Chat privado
context.read<ChatBloc>().add(
  CreatePrivateChat(
    otherUserId: 2,
    otherUserType: 'user',
  ),
);

// Chat em grupo
context.read<ChatBloc>().add(
  CreateGroupChat(
    name: 'Grupo',
    description: 'Descrição',
    participants: [
      ChatParticipant(userId: 1, userType: 'admin'),
      ChatParticipant(userId: 2, userType: 'user'),
    ],
  ),
);
```

## Navegação

### 1. Para Chat Existente

```dart
AppRouter.navigateToChat(
  context,
  chatId: 1,
);
```

### 2. Para Chat com Usuário

```dart
AppRouter.navigateToChat(
  context,
  otherUserId: 2,
  otherUserType: 'user',
);
```

### 3. Widget de Chat

```dart
ChatWidget(
  chatId: 1, // Para chat existente
  // OU
  otherUserId: 2, // Para criar/usar chat privado
  otherUserType: 'user',
)
```

## Modelos de Dados

### ChatMessage
```dart
class ChatMessage {
  final int id;
  final int chatId;
  final String content;
  final String senderType;
  final int senderId;
  final bool isRead;
  final DateTime createdAt;
}
```

### Chat
```dart
class Chat {
  final int id;
  final String type; // 'private' ou 'group'
  final String name;
  final String description;
  final List<ChatParticipant>? participants;
  final ChatLastMessage? lastMessage;
  final int? unreadCount;
}
```

### ChatParticipant
```dart
class ChatParticipant {
  final int userId;
  final String userType;
}
```

### ChatConversation
```dart
class ChatConversation {
  final Chat chat;
  final List<ChatMessage> messages;
  final ChatPagination pagination;
}
```

## Estados do BLoC

### ChatInitial
Estado inicial do chat.

### ChatLoading
Carregando dados do chat.

### ChatConnected
```dart
class ChatConnected extends ChatState {
  final int? chatId;
  final List<ChatMessage> messages;
  final List<Chat> chats;
}
```

### ChatError
```dart
class ChatError extends ChatState {
  final String message;
}
```

### ChatDisconnectedState
Chat desconectado.

## Eventos do BLoC

### ChatInitialized
Inicializa o chat com um chatId opcional.

### MessageSent
Envia uma mensagem.

### MessageReceived
Mensagem recebida via WebSocket.

### LoadConversation
Carrega conversa com usuário específico.

### LoadChats
Lista todos os chats do usuário.

### CreatePrivateChat
Cria chat privado.

### CreateGroupChat
Cria chat em grupo.

### ChatDisconnected
Desconecta do chat.

## Configuração do Backend (Laravel)

### 1. Variáveis de Ambiente

```env
BROADCAST_DRIVER=pusher
PUSHER_APP_KEY=your_pusher_key
PUSHER_APP_SECRET=your_pusher_secret
PUSHER_APP_ID=your_pusher_app_id
PUSHER_APP_CLUSTER=your_pusher_cluster
```

### 2. Configuração do Pusher

```php
// config/broadcasting.php
'pusher' => [
    'driver' => 'pusher',
    'key' => env('PUSHER_APP_KEY'),
    'secret' => env('PUSHER_APP_SECRET'),
    'app_id' => env('PUSHER_APP_ID'),
    'options' => [
        'cluster' => env('PUSHER_APP_CLUSTER'),
        'encrypted' => true,
    ],
],
```

### 3. Evento de Broadcast

```php
// app/Events/MessageSent.php
class MessageSent implements ShouldBroadcast
{
    use InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct($message)
    {
        $this->message = $message;
    }

    public function broadcastOn()
    {
        return new PrivateChannel('chat.' . $this->message->chat_id);
    }

    public function broadcastAs()
    {
        return 'MessageSent';
    }
}
```

### 4. Controller

```php
// app/Http/Controllers/ChatController.php
class ChatController extends Controller
{
    public function createPrivate(Request $request)
    {
        // Lógica para criar chat privado
        $chat = Chat::createPrivate($request->other_user_id, $request->other_user_type);
        
        return response()->json([
            'success' => true,
            'data' => ['chat' => $chat]
        ], 201);
    }

    public function sendMessage(Request $request, $chatId = null)
    {
        if ($chatId) {
            // Enviar para chat específico
            $message = Message::create([
                'chat_id' => $chatId,
                'content' => $request->content,
                'sender_type' => auth()->user()->type,
                'sender_id' => auth()->id(),
            ]);
        } else {
            // Criar/usar chat privado
            $chat = Chat::createPrivate($request->other_user_id, $request->other_user_type);
            $message = Message::create([
                'chat_id' => $chat->id,
                'content' => $request->content,
                'sender_type' => auth()->user()->type,
                'sender_id' => auth()->id(),
            ]);
        }

        // Broadcast da mensagem
        broadcast(new MessageSent($message))->toOthers();

        return response()->json([
            'success' => true,
            'data' => [
                'message' => $message,
                'chat' => $chat ?? $message->chat
            ]
        ], 201);
    }
}
```

## Exemplos de Uso

Veja o arquivo `example_usage.dart` para exemplos completos de:

- Uso direto do ChatService
- Uso com BLoC
- Criação de chats privados e em grupo
- Navegação
- Gerenciamento de múltiplos chats
- Paginação
- Limpeza e desconexão

## Troubleshooting

### 1. Erro de Conexão
- Verifique se o backend está rodando
- Confirme as configurações do Pusher
- Teste a conectividade com `curl`

### 2. Mensagens Não Aparecem
- Verifique se está escutando o canal correto
- Confirme se o evento está sendo broadcastado
- Verifique os logs do ChatService

### 3. Chat Não Cria
- Verifique se o token está válido
- Confirme se os parâmetros estão corretos
- Verifique os logs do backend

### 4. WebSocket Não Conecta
- Verifique as configurações do Pusher
- Confirme se o cluster está correto
- Teste em dispositivo real (não web)

## Logs e Debug

O ChatService inclui logs detalhados para debug:

```
🟡 ChatService - Inicializando...
🟢 ChatService - Inicializado com sucesso
🟡 ChatService - Escutando canal: chat.1
🟢 ChatService - Inscrito no canal de chat: chat.1
🟡 ChatService - Enviando mensagem para chat...
🟢 ChatService - Mensagem enviada com sucesso
🟢 ChatService - Mensagem recebida: Olá! no chat 1
```

Use esses logs para identificar problemas de conectividade e funcionamento. 