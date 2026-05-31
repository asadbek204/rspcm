import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class TeacherExamDetailScreen extends StatefulWidget {
  final TeacherExam exam;
  const TeacherExamDetailScreen({super.key, required this.exam});

  @override
  State<TeacherExamDetailScreen> createState() =>
      _TeacherExamDetailScreenState();
}

class _TeacherExamDetailScreenState extends State<TeacherExamDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabs;

  bool _loading = true;
  List<TeacherExamPractice> _examPractices = [];
  List<TeacherSubmission> _submissions = [];
  List<TeacherPractice> _allPractices = [];
  late TeacherExam _exam;

  bool get _isPractice => _exam.type == 'PRACTICE';

  @override
  void initState() {
    super.initState();
    _exam = widget.exam;
    _tabs = TabController(length: _isPractice ? 2 : 1, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_isPractice) {
      final results = await Future.wait([
        _api.getTeacherExamPractices(_exam.id),
        _api.getSubmissionsByExam(_exam.id),
        _api.getTeacherPractices(),
      ]);
      if (!mounted) return;
      setState(() {
        _examPractices = results[0] as List<TeacherExamPractice>;
        _submissions = results[1] as List<TeacherSubmission>;
        _allPractices = results[2] as List<TeacherPractice>;
        _loading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Изменить статус?'),
        content: Text(_statusChangeText(newStatus)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Подтвердить')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _api.updateTeacherExamStatus(_exam.id, newStatus);
    if (!mounted) return;
    if (ok) {
      // Update local status
      setState(() => _exam = TeacherExam(
            id: _exam.id,
            title: _exam.title,
            description: _exam.description,
            startAt: _exam.startAt,
            endAt: _exam.endAt,
            maxScore: _exam.maxScore,
            taskLimit: _exam.taskLimit,
            type: _exam.type,
            status: newStatus,
            groups: _exam.groups,
            practiceCount: _exam.practiceCount,
            questionCount: _exam.questionCount,
          ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось изменить статус')),
      );
    }
  }

  String _statusChangeText(String s) {
    if (s == 'PUBLISHED') return 'Экзамен станет доступен студентам.';
    if (s == 'COMPLETED') return 'Экзамен будет завершён. Студенты не смогут сдавать.';
    if (s == 'CANCELLED') return 'Экзамен будет отменён.';
    return '';
  }

  Future<void> _addPractice() async {
    final alreadyAdded = _examPractices.map((e) => e.practiceId).toSet();
    final available =
        _allPractices.where((p) => !alreadyAdded.contains(p.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступных практик для добавления')),
      );
      return;
    }

    int? selectedId;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Добавить вариант практики'),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: available
                  .map(
                    (p) => RadioListTile<int>(
                      value: p.id,
                      groupValue: selectedId,
                      onChanged: (v) => setLocal(() => selectedId = v),
                      title: Text(p.name),
                      subtitle: Text(p.workMode == 'TEAM'
                          ? 'Командная'
                          : 'Индивидуальная'),
                      dense: true,
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена')),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () async {
                      final ok = await _api.addPracticeToExam(
                        _exam.id,
                        selectedId!,
                        _examPractices.length + 1,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (ok) {
                        _load();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Не удалось добавить практику')),
                        );
                      }
                    },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePractice(TeacherExamPractice ep) async {
    final ok = await _api.removePracticeFromExam(ep.id);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить вариант')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_exam.title, overflow: TextOverflow.ellipsis),
        bottom: _isPractice
            ? TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Варианты'),
                  Tab(text: 'Сдачи'),
                ],
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Status bar ───────────────────────────────────────────────
                _StatusBar(exam: _exam, onChangeStatus: _updateStatus),

                // ── Tabs / body ──────────────────────────────────────────────
                Expanded(
                  child: _isPractice
                      ? TabBarView(
                          controller: _tabs,
                          children: [
                            _PracticeVariantsTab(
                              examPractices: _examPractices,
                              onAdd: _addPractice,
                              onRemove: _removePractice,
                            ),
                            _SubmissionsTab(
                              submissions: _submissions,
                              examId: _exam.id,
                              onRefresh: _load,
                            ),
                          ],
                        )
                      : _QuestionExamInfoTab(exam: _exam),
                ),
              ],
            ),
    );
  }
}

// ── Status bar ───────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final TeacherExam exam;
  final void Function(String) onChangeStatus;
  const _StatusBar({required this.exam, required this.onChangeStatus});

  (Color, String) get _info {
    switch (exam.status) {
      case 'PUBLISHED':
        return (Colors.green.shade700, 'Открыт');
      case 'COMPLETED':
        return (Colors.grey.shade600, 'Завершён');
      case 'CANCELLED':
        return (Colors.red.shade600, 'Отменён');
      default:
        return (Colors.orange.shade700, 'Черновик');
    }
  }

  List<String> get _availableTransitions {
    switch (exam.status) {
      case 'PUBLISHED':
        return ['COMPLETED', 'CANCELLED'];
      case 'COMPLETED':
        return [];
      case 'CANCELLED':
        return [];
      default:
        return ['PUBLISHED', 'CANCELLED'];
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'PUBLISHED':
        return 'Открыть';
      case 'COMPLETED':
        return 'Завершить';
      case 'CANCELLED':
        return 'Отменить';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _info;
    final fmt = DateFormat('dd.MM.yyyy HH:mm', 'ru_RU');
    final transitions = _availableTransitions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withValues(alpha: 0.06),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (exam.startAt != null)
                  Text('С ${fmt.format(exam.startAt!)}',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                if (exam.endAt != null)
                  Text('До ${fmt.format(exam.endAt!)}',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          if (transitions.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: onChangeStatus,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Статус', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
              itemBuilder: (_) => transitions
                  .map((s) => PopupMenuItem(
                        value: s,
                        child: Text(_statusLabel(s)),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ── Practice variants tab ─────────────────────────────────────────────────────

class _PracticeVariantsTab extends StatelessWidget {
  final List<TeacherExamPractice> examPractices;
  final VoidCallback onAdd;
  final void Function(TeacherExamPractice) onRemove;
  const _PracticeVariantsTab(
      {required this.examPractices,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: examPractices.isEmpty
              ? Center(
                  child: Text('Варианты практики не добавлены',
                      style: TextStyle(color: Colors.grey[500])),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: examPractices.length,
                  itemBuilder: (ctx, i) {
                    final ep = examPractices[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ep.practiceName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                Text(
                                  ep.workMode == 'TEAM'
                                      ? 'Командная'
                                      : 'Индивидуальная',
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red, size: 22),
                            onPressed: () => onRemove(ep),
                            tooltip: 'Удалить вариант',
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Добавить вариант',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Submissions tab ───────────────────────────────────────────────────────────

class _SubmissionsTab extends StatelessWidget {
  final List<TeacherSubmission> submissions;
  final int examId;
  final VoidCallback onRefresh;
  const _SubmissionsTab(
      {required this.submissions,
      required this.examId,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (submissions.isEmpty) {
      return Center(
        child: Text('Нет сдач по этому экзамену',
            style: TextStyle(color: Colors.grey[500])),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: submissions.length,
      itemBuilder: (ctx, i) => _SubmissionCard(
        submission: submissions[i],
        onRefresh: onRefresh,
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final TeacherSubmission submission;
  final VoidCallback onRefresh;
  const _SubmissionCard(
      {required this.submission, required this.onRefresh});

  (Color, String) get _statusInfo {
    switch (submission.status) {
      case 'SUBMITTED':
        return (Colors.blue.shade700, 'На проверке');
      case 'GRADED':
        return (Colors.green.shade700, 'Проверено');
      case 'RETURNED':
        return (Colors.orange.shade700, 'На доработке');
      default:
        return (Colors.grey.shade600, submission.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd.MM HH:mm', 'ru_RU');
    final (statusColor, statusLabel) = _statusInfo;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _SubmissionDetailScreen(
              submission: submission,
              onRefresh: onRefresh,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Text(
                  submission.studentFirstName.isNotEmpty
                      ? submission.studentFirstName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.studentFullName.isNotEmpty
                          ? submission.studentFullName
                          : submission.studentEmail,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (submission.submittedAt != null)
                      Text(
                        'Сдано: ${fmt.format(submission.submittedAt!)}',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Submission detail + grading ───────────────────────────────────────────────

class _SubmissionDetailScreen extends StatefulWidget {
  final TeacherSubmission submission;
  final VoidCallback onRefresh;
  const _SubmissionDetailScreen(
      {required this.submission, required this.onRefresh});

  @override
  State<_SubmissionDetailScreen> createState() =>
      _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<_SubmissionDetailScreen> {
  final ApiService _api = ApiService();
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _grade() async {
    await _doAction(
      () => _api.gradeSubmission(widget.submission.id,
          comment: _commentCtrl.text.trim()),
      'Работа принята!',
    );
  }

  Future<void> _return() async {
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Укажите комментарий для возврата работы')),
      );
      return;
    }
    await _doAction(
      () => _api.returnSubmission(widget.submission.id,
          comment: _commentCtrl.text.trim()),
      'Работа отправлена на доработку',
    );
  }

  Future<void> _doAction(Future<bool> Function() action, String successMsg) async {
    setState(() => _saving = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMsg)));
      widget.onRefresh();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка. Попробуйте снова')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.submission;
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'ru_RU');
    final isGraded = s.status == 'GRADED';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            s.studentFullName.isNotEmpty ? s.studentFullName : s.studentEmail),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Student info
          _InfoCard(children: [
            _InfoRow(icon: Icons.person_outline, label: 'Студент',
                value: s.studentFullName.isNotEmpty ? s.studentFullName : '—'),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: s.studentEmail),
            if (s.submittedAt != null)
              _InfoRow(icon: Icons.schedule_outlined, label: 'Дата сдачи',
                  value: fmt.format(s.submittedAt!)),
            _StatusRow(status: s.status),
          ]),
          const SizedBox(height: 16),

          // Answer
          Text('Ответ студента',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            ),
            child: Text(
              s.textAnswer.isNotEmpty ? s.textAnswer : 'Текст не указан',
              style: TextStyle(
                color: s.textAnswer.isNotEmpty ? null : Colors.grey[400],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Previous comment
          if (s.teacherComment.isNotEmpty) ...[
            Text('Предыдущий комментарий',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(s.teacherComment,
                          style: const TextStyle(height: 1.4))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (!isGraded) ...[
            Text('Комментарий преподавателя',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Введите комментарий (обязателен при возврате)',
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _return,
                    icon: const Icon(Icons.undo_outlined),
                    label: const Text('Вернуть'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _grade,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Принять'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Работа принята',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Question exam info tab ────────────────────────────────────────────────────

class _QuestionExamInfoTab extends StatelessWidget {
  final TeacherExam exam;
  const _QuestionExamInfoTab({required this.exam});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(children: [
          _InfoRow(icon: Icons.list_alt_outlined, label: 'Вопросов',
              value: exam.questionCount.toString()),
          _InfoRow(icon: Icons.timer_outlined, label: 'Лимит времени',
              value: '${exam.taskLimit} минут'),
          _InfoRow(icon: Icons.stars_outlined, label: 'Макс. балл',
              value: exam.maxScore.toString()),
          _InfoRow(icon: Icons.group_outlined, label: 'Группы',
              value: exam.groups.map((g) => g.name).join(', ').ifEmpty('—')),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Управление вопросами доступно через веб-панель администратора.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 13))),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  const _StatusRow({required this.status});

  (Color, String) get _info {
    switch (status) {
      case 'SUBMITTED':
        return (Colors.blue, 'На проверке');
      case 'GRADED':
        return (Colors.green, 'Проверено');
      case 'RETURNED':
        return (Colors.orange, 'На доработке');
      default:
        return (Colors.grey, status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _info;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text('Статус',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

extension _StringExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
