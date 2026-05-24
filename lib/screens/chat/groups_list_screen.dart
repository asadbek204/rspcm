import 'package:flutter/material.dart';
import 'chat_view_screen.dart';

class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView.separated(
        itemCount: 5,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
        itemBuilder: (context, index) {
          final groupNames = ['CS-2026 Official', 'Practice Web Group', 'Team Alpha', 'General Chat', 'Study Group 1'];
          return ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatViewScreen(title: groupNames[index], isGroup: true)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                  child: const Icon(Icons.group, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                    ),
                    width: 12,
                    height: 12,
                  ),
                ),
              ],
            ),
            title: Text(groupNames[index], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Teacher: Don\'t forget the deadline!', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Yesterday', style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 5),
                Icon(Icons.push_pin, size: 14, color: Colors.grey),
              ],
            ),
          );
        },
      ),
    );
  }
}
