import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/services/chat_service.dart' as chat_service;

class ChatWidget extends StatefulWidget {
  final String? chatId;
  final int? otherUserId;
  final String? otherUserType;
  final String? chatName;

  const ChatWidget({
    super.key,
    this.chatId,
    this.otherUserId,
    this.otherUserType,
    this.chatName,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  chat_service.ChatMessage? _replyingTo;
  chat_service.ChatMessage? _editingMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.chatId != null) {
        context.read<ChatBloc>().add(const MarkChatAsRead());
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (_editingMessage != null) {
      context.read<ChatBloc>().add(EditMessageRequested(
        messageId: _editingMessage!.id,
        newContent: content,
      ));
      setState(() { _editingMessage = null; });
    } else {
      context.read<ChatBloc>().add(MessageSent(
        content: content,
        chatId: widget.chatId,
        otherUserId: widget.otherUserId,
        otherUserType: widget.otherUserType,
      ));
    }

    _messageController.clear();
    setState(() { _replyingTo = null; });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessageActions(
    BuildContext context,
    chat_service.ChatMessage message,
    bool isOwnMessage,
  ) {
    if (message.isDeleted) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _replyingTo = message;
                  _editingMessage = null;
                });
                FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
            if (isOwnMessage) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessage = message;
                    _replyingTo = null;
                    _messageController.text = message.content;
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: message.content.length),
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Apagar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, chat_service.ChatMessage message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar mensagem?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(DeleteMessageRequested(messageId: message.id));
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red,
          ));
        } else if (state is ChatConnected) {
          _scrollToBottom();
        }
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro ao conectar', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ChatBloc>().add(ChatInitialized(chatId: widget.chatId)),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is ChatConnected) {
            final authState = context.read<AuthBloc>().state;
            final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;

            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: state.messages.isEmpty
                      ? const Center(
                          child: Text('Nenhuma mensagem ainda', style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: state.messages.length,
                          itemBuilder: (ctx, index) {
                            final message = state.messages[index];
                            final isOwn = currentUserId != null && message.senderId == currentUserId;
                            return GestureDetector(
                              onLongPress: () => _showMessageActions(context, message, isOwn),
                              child: _buildMessageBubble(message, isOwn),
                            );
                          },
                        ),
                ),
                _buildInputArea(context),
              ],
            );
          }

          return const Center(child: Text('Estado desconhecido'));
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Icon(Icons.chat_bubble_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.chatName ?? (widget.chatId != null ? 'Chat #${widget.chatId}' : 'Chat'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            onPressed: () => context.read<ChatBloc>().add(ChatDisconnected()),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Container(width: 3, height: 36, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Respondendo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text(
                        _replyingTo!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _replyingTo = null),
                ),
              ],
            ),
          ),
        if (_editingMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.amber[50],
            child: Row(
              children: [
                Container(width: 3, height: 36, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Editando mensagem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                      Text(
                        _editingMessage!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _editingMessage = null;
                      _messageController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: _editingMessage != null ? 'Editar mensagem...' : 'Digite sua mensagem...',
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _sendMessage,
                mini: true,
                child: Icon(_editingMessage != null ? Icons.check : Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(chat_service.ChatMessage message, bool isOwnMessage) {
    final senderLabel = message.senderType == 'admin' ? 'Admin' : 'Usuário';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _getAvatarColor(message.senderType),
              child: Text(
                senderLabel[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isOwnMessage ? Theme.of(context).primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isOwnMessage) ...[
                    Text(
                      senderLabel,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _getAvatarColor(message.senderType)),
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Reply preview
                  if (message.replyContent != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOwnMessage ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: isOwnMessage ? Colors.white : Colors.grey, width: 3)),
                      ),
                      child: Text(
                        message.replyContent!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isOwnMessage ? Colors.white70 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  // Message content
                  if (message.isDeleted)
                    Text(
                      'Mensagem apagada',
                      style: TextStyle(
                        color: isOwnMessage ? Colors.white54 : Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      message.content,
                      style: TextStyle(color: isOwnMessage ? Colors.white : Colors.black87),
                    ),
                  const SizedBox(height: 4),
                  // Timestamp + edited label + read ticks
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isOwnMessage ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                      if (message.editedAt != null && !message.isDeleted) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(editado)',
                          style: TextStyle(
                            fontSize: 10,
                            color: isOwnMessage ? Colors.white60 : Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (isOwnMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead ? Colors.lightBlueAccent : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Color _getAvatarColor(String senderType) {
    const colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.indigo];
    return colors[senderType.hashCode % colors.length];
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inHours > 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m atrás';
    }
    return 'Agora';
  }
}
