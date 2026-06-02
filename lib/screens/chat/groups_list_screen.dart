import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'chat_view_screen.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;

  // Categorised chat lists
  List<Map<String, dynamic>> _studentGroupChats = [];   // STUDENT_GROUP
  List<Map<String, dynamic>> _subjectGroupChats = [];   // SUBJECT_GROUP
  List<Map<String, dynamic>> _teacherGroupChats = [];   // TEACHER_GROUP

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _api.getChats();
    if (!mounted) return;
    setState(() {
      _studentGroupChats =
          all.where((c) => c['type'] == 'STUDENT_GROUP').toList();
      _subjectGroupChats =
          all.where((c) => c['type'] == 'SUBJECT_GROUP').toList();
      _teacherGroupChats =
          all.where((c) => c['type'] == 'TEACHER_GROUP').toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher =
        Provider.of<AuthProvider>(context, listen: false).isTeacher;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(context, isTeacher),
            ),
    );
  }

  Widget _buildBody(BuildContext context, bool isTeacher) {
    if (isTeacher) {
      // Teacher sees: SUBJECT_GROUP (со студентами) + TEACHER_GROUP (только препы)
      final empty =
          _subjectGroupChats.isEmpty && _teacherGroupChats.isEmpty;
      if (empty) return _buildEmpty();
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_subjectGroupChats.isNotEmpty) ...[
            _sectionHeader(
              context,
              icon: Icons.menu_book_outlined,
              label: 'По предметам (со студентами)',
              color: Colors.teal,
            ),
            ..._subjectGroupChats.map(
              (c) => _ChatTile(
                chat: c,
                type: _ChatKind.subject,
                onRefresh: _load,
              ),
            ),
          ],
          if (_teacherGroupChats.isNotEmpty) ...[
            _sectionHeader(
              context,
              icon: Icons.school_outlined,
              label: 'Преподавательские чаты',
              color: Colors.deepPurple,
            ),
            ..._teacherGroupChats.map(
              (c) => _ChatTile(
                chat: c,
                type: _ChatKind.teacher,
                onRefresh: _load,
              ),
            ),
          ],
        ],
      );
    } else {
      // Student sees: STUDENT_GROUP (общий) + SUBJECT_GROUP (по предметам)
      final empty =
          _studentGroupChats.isEmpty && _subjectGroupChats.isEmpty;
      if (empty) return _buildEmpty();
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_studentGroupChats.isNotEmpty) ...[
            _sectionHeader(
              context,
              icon: Icons.groups_outlined,
              label: 'Общий чат группы',
              color: Colors.blue,
            ),
            ..._studentGroupChats.map(
              (c) => _ChatTile(
                chat: c,
                type: _ChatKind.student,
                onRefresh: _load,
              ),
            ),
          ],
          if (_subjectGroupChats.isNotEmpty) ...[
            _sectionHeader(
              context,
              icon: Icons.menu_book_outlined,
              label: 'Чаты по предметам',
              color: Colors.teal,
            ),
            ..._subjectGroupChats.map(
              (c) => _ChatTile(
                chat: c,
                type: _ChatKind.subject,
                onRefresh: _load,
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Нет доступных групповых чатов',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Чаты создаются автоматически\nпри добавлении в группу',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Chat kinds ─────────────────────────────────────────────────────────────────

enum _ChatKind { student, subject, teacher }

extension _ChatKindX on _ChatKind {
  IconData get icon => switch (this) {
        _ChatKind.student => Icons.groups_rounded,
        _ChatKind.subject => Icons.menu_book_rounded,
        _ChatKind.teacher => Icons.school_rounded,
      };

  Color get color => switch (this) {
        _ChatKind.student => Colors.blue.shade600,
        _ChatKind.subject => Colors.teal.shade600,
        _ChatKind.teacher => Colors.deepPurple.shade500,
      };

  String get typeLabel => switch (this) {
        _ChatKind.student => 'Общий',
        _ChatKind.subject => 'По предмету',
        _ChatKind.teacher => 'Преподаватели',
      };
}

// ── Chat tile ──────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chat;
  final _ChatKind type;
  final VoidCallback onRefresh;

  const _ChatTile({
    required this.chat,
    required this.type,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (chat['title'] ?? '').toString();
    final lastMessage = (chat['lastMessage'] ?? '').toString();
    final memberCount = (chat['memberCount'] as num?)?.toInt() ?? 0;
    final onlineCount = (chat['onlineCount'] as num?)?.toInt() ?? 0;
    final color = type.color;

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(type.icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.typeLabel,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$memberCount участн.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  if (onlineCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$onlineCount онлайн',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.green),
                    ),
                  ],
                ],
              ),
              if (lastMessage.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
          trailing:
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          isThreeLine: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatViewScreen(
                chatId: chat['id'].toString(),
                title: title,
                isGroup: true,
                memberCount: memberCount,
                onlineCount: onlineCount,
              ),
            ),
          ).then((_) => onRefresh()),
        ),
        const Divider(height: 1, indent: 72),
      ],
    );
  }
}
