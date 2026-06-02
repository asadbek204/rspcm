import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'chat_view_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final all = await _apiService.getChats();
    if (!mounted) return;
    setState(() {
      _chats =
          all.where((c) => c['type']?.toString() == 'DIRECT').toList();
      _isLoading = false;
    });
  }

  String _initials(String title) {
    final parts = title.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return title.isNotEmpty ? title[0].toUpperCase() : '?';
  }

  void _openNewChatSheet() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final myUserId = auth.profile?.userId ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewChatSheet(
        apiService: _apiService,
        myUserId: myUserId,
        onChatOpened: (chatData) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatViewScreen(
                chatId: chatData['id'].toString(),
                title: (chatData['title'] ?? 'Чат').toString(),
                isGroup: false,
              ),
            ),
          ).then((_) => _load());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Личные чаты'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewChatSheet,
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _chats.isEmpty
                  ? _buildEmpty(context)
                  : ListView.separated(
                      itemCount: _chats.length,
                      separatorBuilder: (_, _i) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        final title = (chat['title'] ?? 'Чат').toString();
                        final lastMessage =
                            (chat['lastMessage'] ?? '').toString();
                        return ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatViewScreen(
                                chatId: chat['id'].toString(),
                                title: title,
                                isGroup: false,
                              ),
                            ),
                          ).then((_) => _load()),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                theme.primaryColor.withValues(alpha: 0.12),
                            child: Text(
                              _initials(title),
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          subtitle: lastMessage.isNotEmpty
                              ? Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13),
                                )
                              : Text(
                                  'Нет сообщений',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic),
                                ),
                          trailing: Icon(Icons.chevron_right,
                              color: Colors.grey.shade400, size: 20),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline,
                size: 36, color: theme.primaryColor),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет личных чатов',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите кнопку ниже, чтобы написать\nодногруппнику',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet for starting a new direct chat ────────────────────────────

class _NewChatSheet extends StatefulWidget {
  final ApiService apiService;
  final int myUserId;
  final void Function(Map<String, dynamic> chatData) onChatOpened;

  const _NewChatSheet({
    required this.apiService,
    required this.myUserId,
    required this.onChatOpened,
  });

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  bool _loading = true;
  List<StudentGroupMember> _allMembers = [];
  List<StudentGroupMember> _filtered = [];
  final _search = TextEditingController();
  String? _starting;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final groups = await widget.apiService.getStudentGroups();
    if (!mounted) return;

    final memberFutures =
        groups.map((g) => widget.apiService.getGroupMembers(g.id));
    final results = await Future.wait(memberFutures);
    if (!mounted) return;

    final seen = <int>{};
    final merged = <StudentGroupMember>[];
    for (final list in results) {
      for (final m in list) {
        if (m.id != widget.myUserId && seen.add(m.id)) {
          merged.add(m);
        }
      }
    }
    merged.sort((a, b) => a.fullName.compareTo(b.fullName));

    setState(() {
      _allMembers = merged;
      _filtered = merged;
      _loading = false;
    });
  }

  void _filter() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _allMembers
          : _allMembers
              .where((m) =>
                  m.fullName.toLowerCase().contains(q) ||
                  m.email.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _startChat(StudentGroupMember member) async {
    setState(() => _starting = member.email);
    final chat = await widget.apiService.createOrGetDirectChat(member.id);
    if (!mounted) return;
    setState(() => _starting = null);
    if (chat != null) {
      widget.onChatOpened(chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined, color: theme.primaryColor),
                    const SizedBox(width: 10),
                    Text(
                      'Новый чат',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Поиск одногруппников...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // List
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Одногруппники не найдены',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final member = _filtered[index];
                              final isStarting =
                                  _starting == member.email;
                              final initials = member.fullName.isNotEmpty
                                  ? member.fullName
                                      .split(' ')
                                      .take(2)
                                      .map((w) => w.isNotEmpty ? w[0] : '')
                                      .join()
                                      .toUpperCase()
                                  : '?';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.primaryColor
                                      .withValues(alpha: 0.12),
                                  child: isStarting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: theme.primaryColor,
                                          ),
                                        )
                                      : Text(
                                          initials,
                                          style: TextStyle(
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                ),
                                title: Text(
                                  member.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  member.email,
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12),
                                ),
                                onTap: isStarting
                                    ? null
                                    : () => _startChat(member),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
