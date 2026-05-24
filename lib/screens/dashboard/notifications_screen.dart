import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final IconData icon;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.icon = Icons.notifications,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final List<NotificationModel> notifications = [
      NotificationModel(
        id: '1',
        title: 'New Practice Assigned',
        body: 'You have been assigned to "Cloud Computing Practice". Check your practices list.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        icon: Icons.assignment_late,
      ),
      NotificationModel(
        id: '2',
        title: 'Message from Teacher',
        body: 'Teacher Dono upgraded your journal entry for yesterday.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        icon: Icons.chat,
        isRead: true,
      ),
      NotificationModel(
        id: '3',
        title: 'Deadline Approaching',
        body: 'The deadline for "Mobile App Project" is in 2 days.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        icon: Icons.timer,
        isRead: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(theme)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(context, notification, theme);
              },
            ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel item, ThemeData theme) {
    return Container(
      color: item.isRead ? Colors.transparent : theme.primaryColor.withValues(alpha: 0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
          child: Icon(item.icon, color: theme.primaryColor, size: 20),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(item.body, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, hh:mm a').format(item.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }
}
