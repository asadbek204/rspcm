import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PracticeDetailScreen extends StatefulWidget {
  final Practice practice;
  /// Participation ID, if already known from the list screen.
  final int? participationId;
  /// Pre-loaded team data — skips the /practice-participations/me call if provided.
  final PracticeTeamResponse? preloadedTeam;
  /// Which tab to open initially (0 = Задание и сдача, 1 = История сдач, 2 = Дневник)
  final int initialTab;

  const PracticeDetailScreen({
    super.key,
    required this.practice,
    this.participationId,
    this.preloadedTeam,
    this.initialTab = 0,
  });

  @override
  State<PracticeDetailScreen> createState() => _PracticeDetailScreenState();
}

class _PracticeDetailScreenState extends State<PracticeDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  // State
  PracticeTeamResponse? _team;
  PracticeSubmission? _submission;
  List<PracticeJournal> _journals = [];
  List<PracticeSubmissionAttemptItem> _history = [];
  bool _loading = true;
  bool _historyLoading = false;

  // Submission form
  final _submissionController = TextEditingController();
  final _resourceUrlController = TextEditingController();
  bool _submitting = false;

  // Journal form
  final _journalController = TextEditingController();
  bool _savingJournal = false;

  @override
  void initState() {
    super.initState();
    // Задание и сдача | История | [Дневник]
    final tabs = widget.practice.calendarRequired ? 3 : 2;
    final initial = widget.initialTab.clamp(0, tabs - 1);
    _tabController = TabController(length: tabs, vsync: this, initialIndex: initial);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _submissionController.dispose();
    _resourceUrlController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final futures = <Future>[
      if (widget.practice.workMode == 'TEAM' && widget.preloadedTeam == null)
        _api.getTeamByPractice(widget.practice.id),
      _api.getMyJournals(),
    ];

    if (widget.participationId != null) {
      futures.add(_api.getPracticeSubmissionByParticipation(widget.participationId!));
    }

    final results = await Future.wait(futures.map((f) => f.catchError((_) => null)));

    if (!mounted) return;
    setState(() {
      int idx = 0;
      if (widget.practice.workMode == 'TEAM') {
        _team = widget.preloadedTeam ?? results[idx++] as PracticeTeamResponse?;
      }
      final allJournals = results[idx++] as List<PracticeJournal>? ?? [];
      _journals = allJournals
          .where((j) => j.practiceId == widget.practice.id)
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      if (widget.participationId != null) {
        _submission = results[idx] as PracticeSubmission?;
        if (_submission != null) {
          _submissionController.text = _submission!.textAnswer;
          _resourceUrlController.text = _submission!.fileUrl;
        }
      }
      _loading = false;
    });

    // Load submission history separately (non-blocking)
    if (_submission != null) {
      setState(() => _historyLoading = true);
      try {
        final history = await _api.getSubmissionHistory(_submission!.id);
        if (mounted) setState(() { _history = history; _historyLoading = false; });
      } catch (_) {
        if (mounted) setState(() => _historyLoading = false);
      }
    }
  }

  Future<void> _submitWork() async {
    if (widget.participationId == null) return;
    final text = _submissionController.text.trim();
    final url = _resourceUrlController.text.trim();
    if (text.isEmpty && url.isEmpty) {
      _showSnack('Введите текст работы или ссылку на ресурс', error: true);
      return;
    }
    if (url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath != true) {
      _showSnack('Некорректная ссылка. Укажите полный URL (https://...)', error: true);
      return;
    }
    setState(() => _submitting = true);
    final ok = await _api.submitPracticeSubmission(
      widget.participationId!,
      textAnswer: text.isEmpty ? null : text,
      fileUrl: url.isEmpty ? null : url,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _showSnack('Работа успешно отправлена');
      _load();
    } else {
      _showSnack('Не удалось отправить работу', error: true);
    }
  }

  Future<void> _saveJournalEntry() async {
    final content = _journalController.text.trim();
    if (content.isEmpty) {
      _showSnack('Введите текст записи', error: true);
      return;
    }
    setState(() => _savingJournal = true);
    final ok = await _api.createJournal(widget.practice.id, content);
    if (!mounted) return;
    setState(() => _savingJournal = false);
    if (ok) {
      _journalController.clear();
      _showSnack('Запись сохранена');
      _load();
    } else {
      _showSnack('Не удалось сохранить запись', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasJournal = widget.practice.calendarRequired;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.practice.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.practice.resourceUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Открыть ресурс',
              onPressed: () => launchUrl(Uri.parse(widget.practice.resourceUrl!)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Задание и сдача'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('История сдач'),
                  if (_history.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_history.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasJournal) const Tab(text: 'Дневник'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskAndSubmitTab(theme),
                _buildHistoryTab(theme),
                if (hasJournal) _buildJournalTab(theme),
              ],
            ),
    );
  }

  // ─── Tab 1: Task info + Submit ────────────────────────────────────────────

  Widget _buildTaskAndSubmitTab(ThemeData theme) {
    final canSubmit = widget.participationId != null;
    final isGraded = _submission?.status == 'GRADED';
    final isSubmitted = _submission?.status == 'SUBMITTED';
    final isReturned = _submission?.status == 'RETURNED';

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Meta card ──
            _buildMetaCard(theme),

            if (widget.practice.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection(theme, 'Описание', widget.practice.description),
            ],
            if ((widget.practice.requirements ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection(theme, 'Требования', widget.practice.requirements!),
            ],
            if (widget.practice.workMode == 'TEAM') ...[
              const SizedBox(height: 20),
              _buildTeamSection(theme),
            ],

            // ── Submission section ──
            const SizedBox(height: 28),
            Divider(color: Colors.grey.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 24),

            if (!canSubmit)
              _buildLockedCard(theme)
            else if (isGraded)
              _buildGradedResultCard(theme, _submission!)
            else if (isSubmitted)
              _buildOnReviewCard(theme, _submission!)
            else ...[
              // ── Editable form (no submission yet, or RETURNED) ──
              if (isReturned) ...[
                _buildReturnedBanner(theme, _submission!),
                const SizedBox(height: 20),
              ],
              Text('Текст работы',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _submissionController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Опишите выполненную работу...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              Text('Ссылка на ресурс (необязательно)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('GitHub, Google Drive, Figma, YouTube и т.д.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 10),
              TextField(
                controller: _resourceUrlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link_outlined, color: Colors.grey[500]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitWork,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          isReturned ? 'Отправить повторно' : 'Отправить работу',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Submission state cards ────────────────────────────────────────────────

  Widget _buildLockedCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Сдача доступна после выбора практики в экзамене.',
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradedResultCard(ThemeData theme, PracticeSubmission submission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Result header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 36),
              ),
              const SizedBox(height: 12),
              const Text(
                'Работа принята',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Преподаватель проверил вашу работу',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // ── Teacher comment ──
        if (submission.teacherComment.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 16, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Комментарий преподавателя',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(submission.teacherComment, style: const TextStyle(height: 1.5, fontSize: 14)),
              ],
            ),
          ),
        ],

        // ── Submitted content ──
        if (submission.textAnswer.isNotEmpty || submission.fileUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'Ваша сданная работа',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (submission.textAnswer.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(submission.textAnswer,
                      style: TextStyle(height: 1.5, color: Colors.grey.shade700)),
                ],
                if (submission.fileUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(submission.fileUrl);
                      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.link_outlined, size: 14, color: theme.primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            submission.fileUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.primaryColor,
                              decoration: TextDecoration.underline,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        if (submission.attemptCount > 1) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Попыток сдачи: ${submission.attemptCount}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOnReviewCard(ThemeData theme, PracticeSubmission submission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_outline_rounded, color: Colors.blue.shade600, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'Работа принята',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Оценка ещё не выставлена',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // ── Submitted content preview ──
        if (submission.textAnswer.isNotEmpty || submission.fileUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'Отправленная работа',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (submission.textAnswer.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(submission.textAnswer,
                      style: TextStyle(height: 1.5, color: Colors.grey.shade700)),
                ],
                if (submission.fileUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(submission.fileUrl);
                      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.link_outlined, size: 14, color: theme.primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            submission.fileUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.primaryColor,
                              decoration: TextDecoration.underline,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReturnedBanner(ThemeData theme, PracticeSubmission submission) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply_rounded, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 10),
              Text(
                'Работа возвращена на доработку',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (submission.teacherComment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Комментарий:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(submission.teacherComment,
                style: const TextStyle(height: 1.4, fontSize: 14)),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildMetaCard(ThemeData theme) {
    final daysLeft = widget.practice.deadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.practice.title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _chip(
            isOverdue ? 'Просрочено' : 'Активна',
            isOverdue ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 16),
          _metaRow(theme, Icons.calendar_today_outlined,
            'Срок: ${DateFormat('dd MMM yyyy', 'ru_RU').format(widget.practice.deadline)}',
            isOverdue ? Colors.red : null,
          ),
          const SizedBox(height: 8),
          _metaRow(theme,
            widget.practice.workMode == 'TEAM' ? Icons.group_outlined : Icons.person_outline,
            widget.practice.workMode == 'TEAM'
                ? 'Командная работа · макс. ${widget.practice.teamSize} чел.'
                : 'Индивидуальная работа',
          ),
          if (widget.practice.calendarRequired) ...[
            const SizedBox(height: 8),
            _metaRow(theme, Icons.book_outlined, 'Требуется вести дневник практики',
              theme.primaryColor),
          ],
          if (!isOverdue) ...[
            const SizedBox(height: 16),
            _deadlineProgress(theme, daysLeft),
          ],
        ],
      ),
    );
  }

  Widget _deadlineProgress(ThemeData theme, int daysLeft) {
    const total = 30;
    final fraction = (daysLeft / total).clamp(0.0, 1.0);
    final color = daysLeft <= 3
        ? Colors.red
        : daysLeft <= 7
            ? Colors.orange
            : theme.primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Осталось дней', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text('$daysLeft', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTeamSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Команда',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_team == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.group_add_outlined, color: Colors.grey.shade500),
                const SizedBox(width: 12),
                Text('Вы ещё не в команде для этой практики',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          )
        else
          ..._team!.members.map(
            (m) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  m.firstName.isNotEmpty ? m.firstName[0].toUpperCase() : '?',
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text('${m.firstName} ${m.lastName}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(m.email, style: TextStyle(color: Colors.grey.shade600)),
            ),
          ),
      ],
    );
  }


  Widget _buildHistoryTab(ThemeData theme) {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_submission == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Вы ещё не сдавали работу',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
            ],
          ),
        ),
      );
    }
    if (_history.isEmpty) {
      return Center(
        child: Text('Нет записей', style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _history.length,
        itemBuilder: (_, i) => _buildAttemptItem(theme, _history[i]),
      ),
    );
  }

  Widget _buildAttemptItem(ThemeData theme, PracticeSubmissionAttemptItem a) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'ru_RU');
    final isLast = a.attemptNumber == _history.length;
    final studentColor = isLast ? theme.primaryColor : Colors.grey.shade500;
    final hasTeacherComment = a.teacherComment.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: studentColor.withValues(alpha: isLast ? 0.15 : 0.08),
                  border: Border.all(color: studentColor.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    '${a.attemptNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: studentColor,
                    ),
                  ),
                ),
              ),
              if (a.attemptNumber < _history.length)
                Container(
                  width: 2,
                  height: hasTeacherComment ? 90 : 50,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student submission card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isLast
                        ? theme.primaryColor.withValues(alpha: 0.06)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLast
                          ? theme.primaryColor.withValues(alpha: 0.25)
                          : Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text('Отправлено ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          Icon(Icons.schedule, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              fmt.format(a.submittedAt.toLocal()),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLast)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Текущая',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (a.textAnswer.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          a.textAnswer,
                          style: const TextStyle(height: 1.4, fontSize: 13),
                        ),
                      ],
                      if (a.fileUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.tryParse(a.fileUrl);
                            if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          child: Row(
                            children: [
                              Icon(Icons.link_outlined, size: 13, color: theme.primaryColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  a.fileUrl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Teacher comment card (if exists)
                if (hasTeacherComment) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.rate_review_outlined, size: 13, color: Colors.orange.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Комментарий преподавателя',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                a.teacherComment,
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (a.attemptNumber < _history.length)
                  const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ─── Tab 3: Journal / Logbook ─────────────────────────────────────────────

  Widget _buildJournalTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Prompt banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.book_outlined, color: theme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Дневник практики',
                          style: TextStyle(
                              color: theme.primaryColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Ежедневно записывайте, что вы делали по практике. Это поможет составить итоговый отчёт.',
                        style: TextStyle(height: 1.4, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // New entry form
          Text('Запись за сегодня',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _journalController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Что вы сделали сегодня по практике?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _savingJournal ? null : _saveJournalEntry,
              icon: _savingJournal
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Сохранить запись',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 28),

          if (_journals.isNotEmpty) ...[
            Text('История записей (${_journals.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._journals.map((j) => _buildJournalCard(theme, j)),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text('Записей пока нет',
                    style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(ThemeData theme, PracticeJournal journal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMM yyyy, HH:mm', 'ru_RU').format(journal.submittedAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(journal.content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _metaRow(ThemeData theme, IconData icon, String text, [Color? color]) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color ?? Colors.grey.shade700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
