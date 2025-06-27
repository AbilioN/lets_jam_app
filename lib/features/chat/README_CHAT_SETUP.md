# Chat Service - Documentação Completa

## Visão Geral

O ChatService é um sistema completo de chat em tempo real baseado na documentação da API Laravel fornecida. Ele suporta conversas privadas entre usuários e admins, com funcionalidades de broadcast em tempo real usando Pusher.

## Funcionalidades

- ✅ Chat em tempo real usando WebSockets (Pusher)
- ✅ Conversas privadas entre usuários e admins
- ✅ Envio e recebimento de mensagens
- ✅ Carregamento de conversas com paginação
- ✅ Listagem de conversas com contadores
- ✅ Suporte para mensagens de admin
- ✅ Gerenciamento de estado com BLoC
- ✅ Interface de usuário moderna e responsiva

## Estrutura do Projeto

```
lib/features/chat/
├── presentation/
│   ├── bloc/
│   │   ├── chat_bloc.dart
│   │   ├── chat_event.dart
│   │   └── chat_state.dart
│   ├── pages/
│   │   └── chat_page.dart
│   └── widgets/
│       └── chat_widget.dart
├── example_usage.dart
└── README_CHAT_SETUP.md
```

## Configuração

### 1. Dependências

Certifique-se de que as seguintes dependências estão no `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  pusher_channels_flutter: ^2.0.0
  dio: ^5.3.2
  shared_preferences: ^2.2.2
```

### 2. Configuração do Pusher

No arquivo `lib/core/config/pusher_config.dart`:

```dart
class PusherConfig {
  static const String clientAppKey = 'YOUR_PUSHER_APP_KEY';
  static const String clientCluster = 'YOUR_PUSHER_CLUSTER';
  static const String clientSecret = 'YOUR_PUSHER_SECRET';
  static const String clientAppId = 'YOUR_PUSHER_APP_ID';
}
```

### 3. Configuração da API

No arquivo `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  // ou para dispositivo físico: 'http://192.168.1.100:8000/api'
}
```

## Uso Básico

### 1. Inicializar o Chat

```dart
import 'package:your_app/core/services/chat_service.dart';

// Inicializar o ChatService
await ChatService.instance.initialize();

// Configurar callbacks
ChatService.onMessageReceived = (message) {
  print('Nova mensagem: ${message.content}');
};

ChatService.onError = (error) {
  print('Erro: $error');
};
```

### 2. Escutar Conversa

```dart
// Escutar conversa entre usuário 5 e admin 1
await ChatService.instance.listenToConversation(5, 1);
```

### 3. Enviar Mensagem

```dart
final message = await ChatService.instance.sendMessage(
  content: 'Olá! Como posso ajudar?',
  receiverType: 'admin',
  receiverId: 1,
);
```

### 4. Carregar Conversa

```dart
final messages = await ChatService.instance.getConversation(
  otherUserType: 'admin',
  otherUserId: 1,
  page: 1,
  perPage: 50,
);
```

### 5. Carregar Lista de Conversas

```dart
final conversations = await ChatService.instance.getConversations();
```

## Uso com BLoC

### 1. Inicializar Chat com BLoC

```dart
BlocProvider<ChatBloc>(
  create: (context) => ChatBloc(),
  child: ChatWidget(
    currentUserId: 5,
    otherUserId: 1,
    otherUserType: 'admin',
  ),
)
```

### 2. Enviar Mensagem via BLoC

```dart
context.read<ChatBloc>().add(
  MessageSent(
    content: 'Olá!',
    receiverType: 'admin',
    receiverId: 1,
  ),
);
```

### 3. Carregar Conversa via BLoC

```dart
context.read<ChatBloc>().add(
  LoadConversation(
    otherUserType: 'admin',
    otherUserId: 1,
  ),
);
```

## Navegação

### Usando AppRouter

```dart
import 'package:your_app/core/routes/app_router.dart';

// Navegar para chat
AppRouter.navigateToChat(
  context,
  currentUserId: 5,
  otherUserId: 1,
  otherUserType: 'admin',
);
```

### Navegação Direta

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ChatPage(
      currentUserId: 5,
      otherUserId: 1,
      otherUserType: 'admin',
    ),
  ),
);
```

## Funcionalidades de Admin

### 1. Admin Enviando Mensagem

```dart
final message = await ChatService.instance.adminSendMessage(
  content: 'Olá! Sou o administrador.',
  userId: 5, // ID do usuário que receberá
);
```

### 2. Admin Carregando Conversa

```dart
final messages = await ChatService.instance.adminGetConversation(
  userId: 5,
  page: 1,
  perPage: 50,
);
```

### 3. Admin Listando Conversas

```dart
final conversations = await ChatService.instance.adminGetConversations();
```

## Modelos de Dados

### ChatMessage

```dart
class ChatMessage {
  final int id;
  final String content;
  final String senderType;
  final int senderId;
  final String senderName;
  final String receiverType;
  final int receiverId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
}
```

### ChatConversation

```dart
class ChatConversation {
  final int otherUserId;
  final String otherUserType;
  final DateTime? lastMessageAt;
  final int messageCount;
  final int unreadCount;
}
```

## Estados do BLoC

- `ChatInitial`: Estado inicial
- `ChatLoading`: Carregando
- `ChatConnected`: Conectado com mensagens e conversas
- `ChatError`: Erro ocorreu
- `ChatDisconnectedState`: Desconectado

## Eventos do BLoC

- `ChatInitialized`: Inicializar chat
- `MessageSent`: Enviar mensagem
- `MessageReceived`: Mensagem recebida
- `LoadConversation`: Carregar conversa
- `LoadConversations`: Carregar lista de conversas
- `ChatDisconnected`: Desconectar

## Tratamento de Erros

O ChatService inclui tratamento robusto de erros:

```dart
ChatService.onError = (error) {
  // Mostrar snackbar ou dialog de erro
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erro no chat: $error'),
      backgroundColor: Colors.red,
    ),
  );
};
```

## Logs e Debug

O ChatService inclui logs detalhados para debug:

- 🟡 Logs informativos
- 🟢 Logs de sucesso
- 🔴 Logs de erro
- 🔵 Logs de HTTP

## Configuração do Backend Laravel

### 1. Variáveis de Ambiente

```env
BROADCAST_DRIVER=pusher
PUSHER_APP_KEY=your_pusher_key
PUSHER_APP_SECRET=your_pusher_secret
PUSHER_APP_ID=your_pusher_app_id
PUSHER_APP_CLUSTER=your_pusher_cluster
```

### 2. Rotas da API

O backend deve implementar as seguintes rotas:

- `POST /api/chat/send` - Enviar mensagem
- `GET /api/chat/conversation` - Buscar conversa
- `GET /api/chat/conversations` - Listar conversas
- `POST /api/admin/chat/send` - Admin enviar mensagem
- `GET /api/admin/chat/conversation` - Admin buscar conversa
- `GET /api/admin/chat/conversations` - Admin listar conversas

### 3. Evento de Broadcast

```php
// app/Events/MessageSent.php
class MessageSent implements ShouldBroadcast
{
    public function broadcastOn()
    {
        $channelName = 'chat.' . min($this->message->sender_id, $this->message->receiver_id) . 
                      '-' . max($this->message->sender_id, $this->message->receiver_id);
        
        return new PrivateChannel($channelName);
    }
}
```

## Exemplo Completo

Veja o arquivo `example_usage.dart` para exemplos completos de uso do ChatService.

## Troubleshooting

### 1. Erro de Conexão

- Verifique se o backend Laravel está rodando
- Confirme a URL base no `ApiConfig`
- Teste a conectividade com `curl` ou Postman

### 2. Erro do Pusher

- Verifique as credenciais do Pusher
- Confirme se o cluster está correto
- Teste em dispositivo físico (não web)

### 3. Mensagens Não Aparecem

- Verifique se o canal está correto
- Confirme se o evento `MessageSent` está sendo disparado
- Verifique os logs do backend

### 4. Erro de Autenticação

- Verifique se o token está sendo enviado
- Confirme se o token não expirou
- Teste o login novamente

## Próximos Passos

1. Implementar notificações push
2. Adicionar suporte para arquivos/mídia
3. Implementar indicador de digitação
4. Adicionar suporte para emojis
5. Implementar busca de mensagens
6. Adicionar suporte para grupos 