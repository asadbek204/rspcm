import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

// WebSocket base URL — must use wss:// when REST API is on https://
const String _wsBaseUrl = 'wss://api.rspcm.uz/ws';

class ChatViewScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final bool isGroup;
  final String chatType;
  final int? memberCount;
  final int? onlineCount;
  const ChatViewScreen({
    super.key,
    required this.chatId,
    required this.title,
    required this.isGroup,
    this.chatType = '',
    this.memberCount,
    this.onlineCount,
  });

  @override
  State<ChatViewScreen> createState() => _ChatViewScreenState();
}

class _ChatViewScreenState extends State<ChatViewScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  int _onlineCount = 0;
  StompClient? _stompClient;
  bool _stompConnected = false;

  @override
  void initState() {
    super.initState();
    _onlineCount = widget.onlineCount ?? 0;
    _loadMessages();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return;

    _stompClient = StompClient(
      config: StompConfig(
        url: _wsBaseUrl,
        onConnect: _onStompConnected,
        onDisconnect: (_) {
          if (mounted) setState(() => _stompConnected = false);
        },
        onWebSocketError: (e) => debugPrint('WS error: $e'),
        onStompError: (f) => debugPrint('STOMP error: ${f.body}'),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _stompClient!.activate();
  }

  void _onStompConnected(StompFrame frame) {
    if (!mounted) return;
    setState(() => _stompConnected = true);

    // Subscribe to the chat topic — this registers presence on the backend
    _stompClient!.subscribe(
      destination: '/topic/chats/${widget.chatId}',
      callback: (frame) {
        if (!mounted || frame.body == null) return;
        try {
          final msg = json.decode(frame.body!) as Map<String, dynamic>;
          setState(() {
            _messages.add({...msg, 'isMe': false});
          });
          _scrollToBottom();
        } catch (_) {}
      },
    );

    // After subscribing (presence is now registered), fetch fresh online count
    _refreshOnlineCount();
  }

  Future<void> _refreshOnlineCount() async {
    final count = await _apiService.getChatOnlineCount(widget.chatId);
    if (mounted) setState(() => _onlineCount = count);
  }

  Future<void> _loadMessages() async {
    final messages = await _apiService.getChatMessages(widget.chatId);
    final normalized = messages
        .map((m) => {
              ...m,
              'isMe': (m['mine'] ?? false) == true,
            })
        .toList();
    if (!mounted) return;
    setState(() {
      _messages = normalized;
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Send via REST; also push via STOMP if connected (backend will broadcast)
    final ok = await _apiService.sendMessage(widget.chatId, text);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      await _loadMessages();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canAddMembers {
    final isTeacher =
        Provider.of<AuthProvider>(context, listen: false).isTeacher;
    return isTeacher &&
        (widget.chatType == 'SUBJECT_GROUP' ||
            widget.chatType == 'TEACHER_GROUP');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int members = widget.memberCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showMembersSheet(context),
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 16)),
              Row(
                children: [
                  if (_stompConnected) ...[
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Text(
                    widget.isGroup
                        ? '$members участников, $_onlineCount онлайн'
                        : (_onlineCount > 0 ? 'в сети' : 'не в сети'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.grey.shade100,
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(15),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return _buildMessageBubble(msg, theme);
                      },
                    ),
            ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  void _showMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MembersSheet(
        chatId: widget.chatId,
        apiService: _apiService,
        canAddMembers: _canAddMembers,
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, ThemeData theme) {
    final isMe = (msg['isMe'] ?? false) == true;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? theme.primaryColor
              : (theme.brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isGroup && !isMe)
              Text(
                (msg['senderName'] ?? '').toString(),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            Text(
              (msg['content'] ?? '').toString(),
              style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : (theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '12:00',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: theme.cardColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, size: 22),
              onPressed: () {},
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Сообщение',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Members bottom sheet ───────────────────────────────────────────────────────

class _MembersSheet extends StatefulWidget {
  final String chatId;
  final ApiService apiService;
  final bool canAddMembers;

  const _MembersSheet({
    required this.chatId,
    required this.apiService,
    required this.canAddMembers,
  });

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final members = await widget.apiService.getChatMembers(widget.chatId);
    if (!mounted) return;
    setState(() {
      _members = members;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      _loading
                          ? 'Участники'
                          : 'Участники · ${_members.length}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (widget.canAddMembers)
                      TextButton.icon(
                        onPressed: () => _showAddMemberSheet(context),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Добавить'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _members.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.group_outlined,
                                    size: 48,
                                    color: Colors.grey.withValues(alpha: 0.5)),
                                const SizedBox(height: 10),
                                const Text('Нет участников',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              return _MemberTile(
                                  member: _members[index], theme: theme);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMemberSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMemberSheet(
        chatId: widget.chatId,
        apiService: widget.apiService,
        onAdded: _load,
      ),
    );
  }
}

// ── Single member tile ────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final Map<String, dynamic> member;
  final ThemeData theme;

  const _MemberTile({required this.member, required this.theme});

  @override
  Widget build(BuildContext context) {
    final firstName = (member['firstName'] ?? '').toString();
    final lastName = (member['lastName'] ?? '').toString();
    final role = (member['role'] ?? '').toString();
    final isTeacher = role == 'TEACHER';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
    final initials = firstName.isNotEmpty && lastName.isNotEmpty
        ? '${firstName[0]}${lastName[0]}'.toUpperCase()
        : initial;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: isTeacher
            ? Colors.deepPurple.withValues(alpha: 0.15)
            : theme.primaryColor.withValues(alpha: 0.12),
        child: Text(
          initials,
          style: TextStyle(
            color: isTeacher ? Colors.deepPurple : theme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        '$firstName $lastName',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: isTeacher
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Преподаватель',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }
}

// ── Add member sheet ──────────────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  final String chatId;
  final ApiService apiService;
  final VoidCallback onAdded;

  const _AddMemberSheet({
    required this.chatId,
    required this.apiService,
    required this.onAdded,
  });

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();
  Set<int> _adding = {};

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final available =
        await widget.apiService.getAvailableChatMembers(widget.chatId);
    if (!mounted) return;
    setState(() {
      _all = available;
      _filtered = available;
      _loading = false;
    });
  }

  void _filter() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((m) {
              final name =
                  '${m['firstName']} ${m['lastName']}'.toLowerCase();
              return name.contains(q);
            }).toList();
    });
  }

  Future<void> _add(Map<String, dynamic> member) async {
    final id = (member['userId'] as num).toInt();
    setState(() => _adding.add(id));
    final ok = await widget.apiService.addChatMember(widget.chatId, id);
    if (!mounted) return;
    setState(() => _adding.remove(id));
    if (ok) {
      setState(() {
        _all.remove(member);
        _filtered.remove(member);
      });
      widget.onAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined,
                        color: theme.primaryColor),
                    const SizedBox(width: 10),
                    Text(
                      'Добавить участника',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? Center(
                            child: Text(
                              'Все участники группы уже добавлены',
                              style:
                                  TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final m = _filtered[index];
                              final firstName =
                                  (m['firstName'] ?? '').toString();
                              final lastName =
                                  (m['lastName'] ?? '').toString();
                              final id = (m['userId'] as num).toInt();
                              final isAdding = _adding.contains(id);
                              final initials =
                                  '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                                      .toUpperCase();
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme.primaryColor
                                      .withValues(alpha: 0.12),
                                  child: isAdding
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
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
                                  '$firstName $lastName',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                                trailing: isAdding
                                    ? null
                                    : Icon(Icons.add_circle_outline,
                                        color: theme.primaryColor),
                                onTap: isAdding ? null : () => _add(m),
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
