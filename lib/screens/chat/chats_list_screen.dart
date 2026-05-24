import 'package:flutter/material.dart';
import 'chat_view_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.separated(
        itemCount: 10,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatViewScreen(title: 'Student ${index + 1}', isGroup: false)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              child: Text('${index + 1}', style: TextStyle(color: theme.primaryColor)),
            ),
            title: Text('Student ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Hello! How is your practice going?', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('10:45 AM', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 5),
                if (index < 2)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                    child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
