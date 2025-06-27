# Configuração do Chat com Laravel e Pusher

## Backend Laravel

### 1. Instalar dependências

```bash
composer require pusher/pusher-php-server
```

### 2. Configurar .env

```env
BROADCAST_DRIVER=pusher
PUSHER_APP_ID=1553073
PUSHER_APP_KEY=b395ac035994ca7af583
PUSHER_APP_SECRET=8a20e39fc3f1ab6111af
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=eu
```

### 3. Configurar broadcasting.php

```php
'pusher' => [
    'driver' => 'pusher',
    'key' => env('PUSHER_APP_KEY'),
    'secret' => env('PUSHER_APP_SECRET'),
    'app_id' => env('PUSHER_APP_ID'),
    'options' => [
        'cluster' => env('PUSHER_APP_CLUSTER'),
        'host' => env('PUSHER_HOST') ?: 'api-'.env('PUSHER_APP_CLUSTER', 'mt1').'.pusherapp.com',
        'port' => env('PUSHER_PORT', 443),
        'scheme' => env('PUSHER_SCHEME', 'https'),
        'encrypted' => true,
        'useTLS' => env('PUSHER_SCHEME', 'https') === 'https',
    ],
],
```

### 4. Criar Evento de Chat

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ChatMessage implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;
    public $sender;
    public $timestamp;
    public $channelName;

    public function __construct($message, $sender, $channelName)
    {
        $this->message = $message;
        $this->sender = $sender;
        $this->timestamp = now()->toISOString();
        $this->channelName = $channelName;
    }

    public function broadcastOn()
    {
        return new Channel($this->channelName);
    }

    public function broadcastAs()
    {
        return 'chat-message';
    }

    public function broadcastWith()
    {
        return [
            'message' => $this->message,
            'sender' => $this->sender,
            'timestamp' => $this->timestamp,
        ];
    }
}
```

### 5. Criar Controller

```php
<?php

namespace App\Http\Controllers;

use App\Events\ChatMessage;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function sendMessage(Request $request)
    {
        $request->validate([
            'message' => 'required|string|max:1000',
            'sender' => 'required|string|max:100',
            'channel' => 'required|string|max:100',
        ]);

        $message = $request->input('message');
        $sender = $request->input('sender');
        $channel = $request->input('channel');

        // Disparar evento
        broadcast(new ChatMessage($message, $sender, $channel))->toOthers();

        return response()->json([
            'success' => true,
            'message' => 'Mensagem enviada com sucesso',
        ]);
    }

    public function joinChannel(Request $request)
    {
        $request->validate([
            'user' => 'required|string|max:100',
            'channel' => 'required|string|max:100',
        ]);

        $user = $request->input('user');
        $channel = $request->input('channel');

        // Disparar evento de usuário entrou
        broadcast(new \App\Events\UserJoined($user, $channel))->toOthers();

        return response()->json([
            'success' => true,
            'message' => 'Usuário entrou no canal',
        ]);
    }

    public function leaveChannel(Request $request)
    {
        $request->validate([
            'user' => 'required|string|max:100',
            'channel' => 'required|string|max:100',
        ]);

        $user = $request->input('user');
        $channel = $request->input('channel');

        // Disparar evento de usuário saiu
        broadcast(new \App\Events\UserLeft($user, $channel))->toOthers();

        return response()->json([
            'success' => true,
            'message' => 'Usuário saiu do canal',
        ]);
    }
}
```

### 6. Criar Eventos Adicionais

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UserJoined implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $user;
    public $channelName;

    public function __construct($user, $channelName)
    {
        $this->user = $user;
        $this->channelName = $channelName;
    }

    public function broadcastOn()
    {
        return new Channel($this->channelName);
    }

    public function broadcastAs()
    {
        return 'user-joined';
    }

    public function broadcastWith()
    {
        return [
            'user' => $this->user,
        ];
    }
}
```

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UserLeft implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $user;
    public $channelName;

    public function __construct($user, $channelName)
    {
        $this->user = $user;
        $this->channelName = $channelName;
    }

    public function broadcastOn()
    {
        return new Channel($this->channelName);
    }

    public function broadcastAs()
    {
        return 'user-left';
    }

    public function broadcastWith()
    {
        return [
            'user' => $this->user,
        ];
    }
}
```

### 7. Adicionar Rotas

```php
// routes/api.php
Route::post('/chat/send', [ChatController::class, 'sendMessage']);
Route::post('/chat/join', [ChatController::class, 'joinChannel']);
Route::post('/chat/leave', [ChatController::class, 'leaveChannel']);
```

## Frontend Flutter

### Como usar

1. **Acessar chat simples:**
   ```dart
   AppRouter.navigateToChat(
     context,
     channelName: 'general',
     currentUser: 'Seu Nome',
   );
   ```

2. **Acessar chat customizado:**
   ```dart
   AppRouter.navigateToChat(
     context,
     channelName: 'musica',
     currentUser: 'João',
   );
   ```

### Funcionalidades

- ✅ Conexão em tempo real com Pusher
- ✅ Envio e recebimento de mensagens
- ✅ Notificações de usuários entrando/saindo
- ✅ Interface responsiva e moderna
- ✅ Suporte a múltiplos canais
- ✅ Timestamps das mensagens
- ✅ Avatares coloridos por usuário
- ✅ Mensagens de sistema

### Estrutura de Arquivos

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
└── README_CHAT_SETUP.md
```

### Configuração do Pusher

O cliente Flutter está configurado para usar:
- **App Key:** b395ac035994ca7af583
- **Cluster:** eu
- **Host:** api-eu.pusherapp.com
- **Port:** 443
- **Scheme:** https

### Testando

1. Execute o backend Laravel
2. Execute o app Flutter
3. Faça login e vá para a página home
4. Clique em "Abrir Chat" ou "Chat em Grupo"
5. Envie mensagens e veja em tempo real!

### Notas Importantes

- O chat funciona em tempo real usando WebSockets via Pusher
- Cada canal é independente
- Mensagens são armazenadas apenas em memória (não persistidas)
- Para persistência, implemente um banco de dados no backend
- O Pusher tem limites de mensagens gratuitas (200k/mês) 