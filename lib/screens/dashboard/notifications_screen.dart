import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final IconData icon;
  final int? participationId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.icon = Icons.notifications,
    this.participationId,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final invitations = await _apiService.getMyTeamInvitations();
    final exams = await _apiService.getMyExams();

    final items = <NotificationModel>[
      ...invitations.map((inv) => NotificationModel(
            id: 'inv-${inv.participationId}',
            title: 'Приглашение в команду',
            body: '${inv.invitedByName.isEmpty ? 'Студент' : inv.invitedByName} пригласил(а) вас в практику ${inv.practiceName}.',
            timestamp: DateTime.now(),
            icon: Icons.group_add,
            participationId: inv.participationId,
          )),
      ...exams.where((e) => e.endAt != null).map((exam) => NotificationModel(
            id: 'exam-${exam.id}',
            title: 'Срок экзамена',
            body: '${exam.title} завершится ${DateFormat('dd MMM, HH:mm', 'ru_RU').format(exam.endAt!)}',
            timestamp: exam.endAt!,
            icon: Icons.timer,
            isRead: true,
          )),
    ];

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (!mounted) return;
    setState(() {
      _notifications = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState(theme)
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationItem(context, notification, theme);
                },
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _NotificationView extends StatelessWidget {
  final NotificationModel item;
  final ThemeData theme;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _NotificationView({
    required this.item,
    required this.theme,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
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
        trailing: item.participationId == null
            ? null
            : Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onDecline,
                    tooltip: 'Отклонить',
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, size: 18),
                    onPressed: onAccept,
                    tooltip: 'Принять',
                  ),
                ],
              ),
      ),
    );
  }
}

Widget _buildNotificationItem(BuildContext context, NotificationModel item, ThemeData theme) {
  final state = context.findAncestorStateOfType<_NotificationsScreenState>();
  return _NotificationView(
    item: item,
    theme: theme,
    onDecline: item.participationId == null || state == null
        ? null
        : () async {
            final ok = await state._apiService.declineTeamInvitation(item.participationId!);
            if (!state.mounted) return;
            if (ok) {
              await state._fetchNotifications();
            }
          },
    onAccept: item.participationId == null || state == null
        ? null
        : () async {
            final ok = await state._apiService.acceptTeamInvitation(item.participationId!);
            if (!state.mounted) return;
            if (ok) {
              await state._fetchNotifications();
            }
          },
  );
}

Widget _buildEmptyState(ThemeData theme) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 20),
        const Text('Пока нет уведомлений', style: TextStyle(color: Colors.grey, fontSize: 18)),
      ],
    ),
  );
}
