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
  final Color iconColor;
  final int? participationId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.icon = Icons.notifications,
    this.iconColor = Colors.blue,
    this.participationId,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final results = await Future.wait([
      _api.getMyTeamInvitations().catchError((_) => []),
      _api.getMyExams().catchError((_) => []),
    ]);

    final invitations = results[0] as List;
    final exams = results[1] as List;

    final items = <NotificationModel>[
      ...invitations.map((inv) => NotificationModel(
            id: 'inv-${inv.participationId}',
            title: 'Приглашение в команду',
            body:
                '${inv.invitedByName.isEmpty ? 'Студент' : inv.invitedByName} пригласил(а) вас в практику «${inv.practiceName}».',
            timestamp: DateTime.now(),
            icon: Icons.group_add_outlined,
            iconColor: Colors.deepPurple,
            isRead: false,
            participationId: inv.participationId,
          )),
      ...exams
          .where((e) => e.endAt != null)
          .map((exam) => NotificationModel(
                id: 'exam-${exam.id}',
                title: 'Срок экзамена',
                body:
                    '«${exam.title}» завершится ${DateFormat('dd MMM, HH:mm', 'ru_RU').format(exam.endAt!)}',
                timestamp: exam.endAt!,
                icon: Icons.timer_outlined,
                iconColor: Colors.orange,
                isRead: true,
              )),
    ];

    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (!mounted) return;
    setState(() {
      _notifications = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmpty(theme)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) =>
                        _buildItem(context, _notifications[index], theme),
                  ),
                ),
    );
  }

  Widget _buildItem(
      BuildContext context, NotificationModel item, ThemeData theme) {
    return Dismissible(
      key: Key(item.id),
      direction: item.participationId != null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _notifications.removeWhere((n) => n.id == item.id));
      },
      child: Container(
        color: item.isRead
            ? Colors.transparent
            : theme.primaryColor.withValues(alpha: 0.04),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: item.iconColor.withValues(alpha: 0.12),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(item.body,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
              const SizedBox(height: 6),
              Text(
                DateFormat('dd MMM, HH:mm', 'ru_RU').format(item.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
          trailing: item.participationId == null
              ? null
              : _buildInvitationActions(context, item),
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _buildInvitationActions(BuildContext context, NotificationModel item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, color: Colors.red, size: 20),
          tooltip: 'Отклонить',
          onPressed: () async {
            final ok = await _api.declineTeamInvitation(item.participationId!);
            if (!mounted) return;
            if (ok) _load();
          },
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.check, color: Colors.green, size: 20),
          tooltip: 'Принять',
          onPressed: () async {
            final ok = await _api.acceptTeamInvitation(item.participationId!);
            if (!mounted) return;
            if (ok) _load();
          },
        ),
      ],
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Нет уведомлений',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Приглашения в команды и\nдедлайны появятся здесь',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}
