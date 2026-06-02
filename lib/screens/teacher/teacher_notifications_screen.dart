import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'teacher_all_submissions_screen.dart';

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<NotificationItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _api.getMyNotifications(size: 100);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _markOneRead(NotificationItem item) async {
    if (item.read) return;
    final updated = await _api.markNotificationRead(item.id);
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        final idx = _items.indexWhere((n) => n.id == item.id);
        if (idx != -1) _items[idx] = updated;
      });
    }
  }

  Future<void> _markAllRead() async {
    await _api.markAllNotificationsRead();
    if (!mounted) return;
    setState(() {
      _items = _items.map((n) => n.copyWith(read: true)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _items.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Уведомления'),
            if (!_loading && unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        centerTitle: false,
        actions: [
          if (!_loading && unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Прочитать все'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _items.length,
                    separatorBuilder: (_, _i) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (ctx, i) =>
                        _buildItem(ctx, _items[i], theme),
                  ),
                ),
    );
  }

  Widget _buildItem(
      BuildContext context, NotificationItem item, ThemeData theme) {
    final iconData = _iconForType(item.type);
    final iconColor = _colorForType(item.type);
    final isSubmissionReceived = item.type == 'SUBMISSION_RECEIVED';

    return InkWell(
      onTap: () async {
        await _markOneRead(item);
        if (!mounted) return;
        if (isSubmissionReceived) {
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Сдачи работ')),
                body: const TeacherAllSubmissionsScreen(),
              ),
            ),
          ).then((_) => _load());
        }
      },
      child: Container(
        color: item.read
            ? Colors.transparent
            : theme.primaryColor.withValues(alpha: 0.05),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              if (!item.read)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.scaffoldBackgroundColor, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                item.body,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(item.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
          trailing: isSubmissionReceived
              ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
              : item.read
                  ? null
                  : Icon(Icons.circle,
                      size: 8, color: theme.colorScheme.primary),
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Нет уведомлений',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 18,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Сданные работы и напоминания\nпоявятся здесь',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'SUBMISSION_RECEIVED':
        return Icons.upload_file_outlined;
      case 'SUBMISSION_GRADED':
        return Icons.check_circle_outline;
      case 'SUBMISSION_RETURNED':
        return Icons.undo_outlined;
      case 'DEADLINE_REMINDER':
        return Icons.timer_outlined;
      case 'PRACTICE_REMINDER':
        return Icons.book_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'SUBMISSION_RECEIVED':
        return Colors.blue.shade600;
      case 'SUBMISSION_GRADED':
        return Colors.green.shade600;
      case 'SUBMISSION_RETURNED':
        return Colors.orange.shade700;
      case 'DEADLINE_REMINDER':
        return Colors.red.shade600;
      case 'PRACTICE_REMINDER':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин. назад';
    if (diff.inDays < 1) return '${diff.inHours} ч. назад';
    if (diff.inDays == 1) return 'Вчера в ${DateFormat('HH:mm').format(dt)}';
    return DateFormat('dd MMM, HH:mm', 'ru_RU').format(dt);
  }
}
