import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/routes/app_router.dart';
import '../bloc/chat_bloc.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = getIt<ChatBloc>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatBloc.close();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;

    if (q.isEmpty) {
      setState(() { _results = []; _loading = false; });
      return;
    }

    setState(() => _loading = true);

    _chatBloc.add(SearchUsersRequested(query: q));
    _chatBloc.stream.firstWhere((s) => s is UserSearchResults || s is ChatError).then((s) {
      if (!mounted) return;
      if (s is UserSearchResults) {
        setState(() { _results = s.users; _loading = false; });
      } else {
        setState(() { _loading = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova conversa'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (v) => _search(v),
            ),
          ),
          if (_loading)
            const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty && !_loading
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Digite para buscar usuários'
                          : 'Nenhum usuário encontrado',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (ctx, i) {
                      final user = _results[i];
                      final name = user['name'] as String? ?? 'Usuário';
                      final email = user['email'] as String? ?? '';
                      final userId = (user['id'] ?? '').toString();
                      final lastSeen = user['last_seen_at'] as String?;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          lastSeen != null ? _formatLastSeen(lastSeen) : email,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          AppRouter.navigateToChat(
                            context,
                            otherUserId: int.tryParse(userId),
                            otherUserType: 'user',
                            chatName: name,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(String raw) {
    try {
      final dt = DateTime.parse(raw.replaceAll(' ', 'T'));
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 2) return 'Online agora';
      if (diff.inMinutes < 60) return 'Visto há ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'Visto há ${diff.inHours}h';
      return 'Visto há ${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}
