import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'chat_view_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> _loadChats() async {
    final all = await _apiService.getChats();
    return all.where((c) => !(c['type']?.toString().contains('GROUP') ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const Center(child: Text('Нет чатов'));
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final title = (chat['title'] ?? 'Чат').toString();
              final lastMessage = (chat['lastMessage'] ?? '').toString();
              final memberCount = (chat['memberCount'] as num?)?.toInt() ?? 0;
              final onlineCount = (chat['onlineCount'] as num?)?.toInt() ?? 0;
              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatViewScreen(
                      chatId: chat['id'].toString(),
                      title: title,
                      isGroup: false,
                      memberCount: memberCount,
                      onlineCount: onlineCount,
                    ),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Text('${index + 1}', style: TextStyle(color: theme.primaryColor)),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            },
          );
        },
      ),
    );
  }
}
