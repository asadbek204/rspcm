import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class TeacherAllSubmissionsScreen extends StatefulWidget {
  const TeacherAllSubmissionsScreen({super.key});

  @override
  State<TeacherAllSubmissionsScreen> createState() =>
      _TeacherAllSubmissionsScreenState();
}

class _TeacherAllSubmissionsScreenState
    extends State<TeacherAllSubmissionsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;

  // Map: exam → list of submissions for that exam (PRACTICE)
  List<_ExamSubmissions> _groups = [];
  // Map: exam → list of attempts (QUESTION)
  List<_ExamAttempts> _attemptGroups = [];
  String _filter = 'ALL'; // ALL, SUBMITTED, GRADED, RETURNED

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final exams = await _api.getTeacherExams(size: 100);
    final practiceExams =
        exams.where((e) => e.type == 'PRACTICE' && e.status != 'CANCELLED').toList();
    final questionExams =
        exams.where((e) => e.type == 'QUESTION' && e.status != 'CANCELLED').toList();

    final subResults = await Future.wait(
      practiceExams.map((e) => _api.getSubmissionsByExam(e.id, size: 200)),
    );
    final attemptResults = await Future.wait(
      questionExams.map((e) => _api.getAttemptsByExam(e.id)),
    );

    final groups = <_ExamSubmissions>[];
    for (var i = 0; i < practiceExams.length; i++) {
      final subs = subResults[i];
      if (subs.isNotEmpty) {
        groups.add(_ExamSubmissions(exam: practiceExams[i], submissions: subs));
      }
    }

    final attemptGroups = <_ExamAttempts>[];
    for (var i = 0; i < questionExams.length; i++) {
      final attempts = attemptResults[i];
      if (attempts.isNotEmpty) {
        attemptGroups.add(_ExamAttempts(exam: questionExams[i], attempts: attempts));
      }
    }

    if (!mounted) return;
    setState(() {
      _groups = groups;
      _attemptGroups = attemptGroups;
      _loading = false;
    });
  }

  List<_ExamSubmissions> get _filtered {
    if (_filter == 'ALL') return _groups;
    return _groups
        .map((g) => _ExamSubmissions(
              exam: g.exam,
              submissions:
                  g.submissions.where((s) => s.status == _filter).toList(),
            ))
        .where((g) => g.submissions.isNotEmpty)
        .toList();
  }

  int get _totalCount {
    final subs = _groups.fold(0, (sum, g) => sum + g.submissions.length);
    final attempts = _attemptGroups.fold(0, (sum, g) => sum + g.attempts.length);
    return subs + attempts;
  }

  int _countByStatus(String status) {
    final subs = _groups.fold(
        0, (sum, g) => sum + g.submissions.where((s) => s.status == status).length);
    final attempts = _attemptGroups.fold(
        0, (sum, g) => sum + g.attempts.where((a) => a.status == status).length);
    return subs + attempts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    final filtered = _filtered;

    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          // ── Filter chips ──────────────────────────────────────────────────
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Все',
                    count: _totalCount,
                    selected: _filter == 'ALL',
                    color: theme.primaryColor,
                    onTap: () => setState(() => _filter = 'ALL'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'На проверке',
                    count: _countByStatus('SUBMITTED'),
                    selected: _filter == 'SUBMITTED',
                    color: Colors.blue,
                    onTap: () => setState(() => _filter = 'SUBMITTED'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Проверено',
                    count: _countByStatus('GRADED'),
                    selected: _filter == 'GRADED',
                    color: Colors.green,
                    onTap: () => setState(() => _filter = 'GRADED'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'На доработке',
                    count: _countByStatus('RETURNED'),
                    selected: _filter == 'RETURNED',
                    color: Colors.orange,
                    onTap: () => setState(() => _filter = 'RETURNED'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  List<_ExamAttempts> get _filteredAttempts {
    if (_filter == 'ALL') return _attemptGroups;
    return _attemptGroups
        .map((g) => _ExamAttempts(
              exam: g.exam,
              attempts: g.attempts.where((a) => a.status == _filter).toList(),
            ))
        .where((g) => g.attempts.isNotEmpty)
        .toList();
  }

  Widget _buildContent() {
    final filteredSubs = _filtered;
    final filteredAttempts = _filteredAttempts;
    if (filteredSubs.isEmpty && filteredAttempts.isEmpty) return _buildEmpty();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (filteredSubs.isNotEmpty) ...[
          _SectionLabel(label: 'Практические работы', icon: Icons.handyman_outlined),
          const SizedBox(height: 8),
          ...filteredSubs.map((g) => _ExamGroup(group: g, onRefresh: _load)),
        ],
        if (filteredAttempts.isNotEmpty) ...[
          _SectionLabel(label: 'Тесты (с вопросами)', icon: Icons.quiz_outlined),
          const SizedBox(height: 8),
          ...filteredAttempts.map((g) => _AttemptGroup(group: g, onRefresh: _load)),
        ],
      ],
    );
  }

  Widget _buildEmpty() {
    final msg = _filter == 'ALL'
        ? 'Нет сданных работ'
        : 'Нет работ с выбранным статусом';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ExamSubmissions {
  final TeacherExam exam;
  final List<TeacherSubmission> submissions;
  const _ExamSubmissions({required this.exam, required this.submissions});
}

class _ExamAttempts {
  final TeacherExam exam;
  final List<TeacherAttempt> attempts;
  const _ExamAttempts({required this.exam, required this.attempts});
}

// ── Exam group ────────────────────────────────────────────────────────────────

class _ExamGroup extends StatelessWidget {
  final _ExamSubmissions group;
  final VoidCallback onRefresh;

  const _ExamGroup({required this.group, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingCount =
        group.submissions.where((s) => s.status == 'SUBMITTED').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exam header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group.exam.title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (pendingCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$pendingCount на проверке',
                    style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        ...group.submissions.map(
          (s) => _SubmissionCard(submission: s, onRefresh: onRefresh),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Submission card ───────────────────────────────────────────────────────────

class _SubmissionCard extends StatelessWidget {
  final TeacherSubmission submission;
  final VoidCallback onRefresh;

  const _SubmissionCard({required this.submission, required this.onRefresh});

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
            builder: (_) => SubmissionReviewScreen(
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
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
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
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
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

// ── Submission review screen ──────────────────────────────────────────────────

class SubmissionReviewScreen extends StatefulWidget {
  final TeacherSubmission submission;
  final VoidCallback onRefresh;
  const SubmissionReviewScreen(
      {super.key, required this.submission, required this.onRefresh});

  @override
  State<SubmissionReviewScreen> createState() => _SubmissionReviewScreenState();
}

class _SubmissionReviewScreenState extends State<SubmissionReviewScreen> {
  final ApiService _api = ApiService();
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _commentCtrl.text = widget.submission.teacherComment;
  }

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

  Future<void> _doAction(
      Future<bool> Function() action, String successMsg) async {
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
          // ── Student info ──────────────────────────────────────────────────
          Container(
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
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          theme.primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        s.studentFirstName.isNotEmpty
                            ? s.studentFirstName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.studentFullName.isNotEmpty
                                ? s.studentFullName
                                : 'Студент',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(s.studentEmail,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (s.submittedAt != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Сдано: ${fmt.format(s.submittedAt!)}',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Submission content ────────────────────────────────────────────
          if (s.textAnswer.isNotEmpty) ...[
            Text('Ответ студента', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
              ),
              child: Text(s.textAnswer,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
            const SizedBox(height: 16),
          ],

          if (s.fileUrl.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file,
                      color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Прикреплённый файл',
                          style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (s.textAnswer.isEmpty && s.fileUrl.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Содержимое работы отсутствует',
                  style: TextStyle(color: Colors.grey[500])),
            ),
            const SizedBox(height: 16),
          ],

          // ── Comment ───────────────────────────────────────────────────────
          Text('Комментарий преподавателя',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            enabled: !isGraded,
            decoration: InputDecoration(
              hintText: isGraded
                  ? 'Работа уже проверена'
                  : 'Введите комментарий...',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // ── Actions ───────────────────────────────────────────────────────
          if (!isGraded) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _return,
                    icon: const Icon(Icons.undo_outlined),
                    label: const Text('На доработку'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
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
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Принять'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Работа принята',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.primaryColor),
        const SizedBox(width: 6),
        Text(label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Attempt group (QUESTION exams) ────────────────────────────────────────────

class _AttemptGroup extends StatelessWidget {
  final _ExamAttempts group;
  final VoidCallback onRefresh;
  const _AttemptGroup({required this.group, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingCount = group.attempts.where((a) => a.status == 'SUBMITTED').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(group.exam.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$pendingCount на проверке',
                      style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        ...group.attempts.map((a) =>
            _AttemptCard(exam: group.exam, attempt: a, onRefresh: onRefresh)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final TeacherExam exam;
  final TeacherAttempt attempt;
  final VoidCallback onRefresh;
  const _AttemptCard(
      {required this.exam,
      required this.attempt,
      required this.onRefresh});

  (Color, String) get _statusInfo {
    switch (attempt.status) {
      case 'SUBMITTED':
        return (Colors.blue.shade700, 'На проверке');
      case 'GRADED':
        return (Colors.green.shade700, 'Проверено');
      default:
        return (Colors.grey.shade600, attempt.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd.MM HH:mm', 'ru_RU');
    final (statusColor, statusLabel) = _statusInfo;
    final name =
        '${attempt.student.firstName} ${attempt.student.lastName}'.trim();

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
            builder: (_) => AttemptReviewScreen(
              exam: exam,
              attempt: attempt,
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
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : attempt.student.email,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (attempt.submittedAt != null)
                      Text('Сдано: ${fmt.format(attempt.submittedAt!)}',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12)),
                    if (attempt.openUngradedCount > 0)
                      Text(
                          'Открытых без оценки: ${attempt.openUngradedCount}',
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12)),
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
                  if (attempt.totalScore != null) ...[
                    const SizedBox(height: 4),
                    Text('${attempt.totalScore} б.',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
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

// ── Attempt review screen ─────────────────────────────────────────────────────

class AttemptReviewScreen extends StatefulWidget {
  final TeacherExam exam;
  final TeacherAttempt attempt;
  final VoidCallback onRefresh;
  const AttemptReviewScreen(
      {super.key,
      required this.exam,
      required this.attempt,
      required this.onRefresh});

  @override
  State<AttemptReviewScreen> createState() => _AttemptReviewScreenState();
}

class _AttemptReviewScreenState extends State<AttemptReviewScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<TeacherAttemptAnswer> _answers = [];
  // answerId → score controller
  final Map<int, TextEditingController> _scoreCtrl = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _scoreCtrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final answers = await _api.getAttemptAnswers(
        widget.exam.id, widget.attempt.attemptId);
    if (!mounted) return;
    for (final a in answers) {
      if (a.answerId != null) {
        _scoreCtrl.putIfAbsent(
            a.answerId!,
            () => TextEditingController(
                text: a.score != null ? '${a.score}' : ''));
      }
    }
    setState(() {
      _answers = answers;
      _loading = false;
    });
  }

  Future<void> _saveScore(int answerId, int maxScore) async {
    final raw = _scoreCtrl[answerId]?.text.trim() ?? '';
    final score = int.tryParse(raw);
    if (score == null || score < 0 || score > maxScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Введите число от 0 до $maxScore')),
      );
      return;
    }
    final ok = await _api.scoreAnswer(answerId, score);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Оценка сохранена')));
      widget.onRefresh();
      await _load();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ошибка сохранения')));
    }
  }

  void _finishReview() {
    final ungradedCount = _answers
        .where((a) => a.questionType == 'OPEN' && a.score == null)
        .length;

    if (ungradedCount > 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Не все вопросы проверены'),
          content: Text(
              'Осталось $ungradedCount открыт${ungradedCount == 1 ? 'ый вопрос без оценки' : 'ых вопроса без оценки'}. '
              'Поставьте баллы по всем открытым вопросам, чтобы завершить проверку.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }

    // All open questions graded — go back
    widget.onRefresh();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Проверка завершена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        '${widget.attempt.student.firstName} ${widget.attempt.student.lastName}'
            .trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : widget.attempt.student.email),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _answers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, i) => _buildAnswerCard(_answers[i], theme),
                  ),
                ),
                // ── Finish review button ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                        top: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.15))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _finishReview,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Завершить проверку'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAnswerCard(TeacherAttemptAnswer a, ThemeData theme) {
    final isOpen = a.questionType == 'OPEN';
    final isGraded = a.score != null;
    final statusColor =
        isGraded ? Colors.green.shade600 : Colors.orange.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${a.orderIndex}',
                    style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_questionTypeLabel(a.questionType),
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 12)),
              ),
              Text('Макс: ${a.maxScore} б.',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.questionText,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),

          // Student answer
          if (isOpen) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Text(
                  a.textAnswer?.isNotEmpty == true
                      ? a.textAnswer!
                      : '(нет ответа)',
                  style: TextStyle(
                      color: a.textAnswer?.isNotEmpty == true
                          ? null
                          : Colors.grey[400],
                      fontSize: 13,
                      height: 1.5)),
            ),
            const SizedBox(height: 10),
            // Score input for OPEN questions
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: a.answerId != null
                        ? _scoreCtrl[a.answerId!]
                        : null,
                    enabled: a.answerId != null,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Балл (0–${a.maxScore})',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: a.answerId != null
                      ? () => _saveScore(a.answerId!, a.maxScore)
                      : null,
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ] else ...[
            // Options for CLOSED/MULTIPLE_CHOICE
            ...a.options.map((opt) {
              final isSelected = a.selectedOptionIds.contains(opt.id);
              final isCorrect = opt.correct;
              Color? bg;
              if (isSelected && isCorrect) bg = Colors.green.withValues(alpha: 0.12);
              if (isSelected && !isCorrect) bg = Colors.red.withValues(alpha: 0.1);
              if (!isSelected && isCorrect) bg = Colors.green.withValues(alpha: 0.06);

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bg ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isCorrect
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color: isSelected
                          ? (isCorrect ? Colors.green : Colors.red)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(opt.text,
                            style: const TextStyle(fontSize: 13))),
                    if (isCorrect)
                      const Icon(Icons.verified,
                          size: 16, color: Colors.green),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 6),
          // Score badge
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  isGraded ? '${a.score} / ${a.maxScore} б.' : 'Не оценено',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _questionTypeLabel(String type) {
    switch (type) {
      case 'OPEN':
        return 'Открытый вопрос';
      case 'CLOSED':
        return 'Одиночный выбор';
      case 'MULTIPLE_CHOICE':
        return 'Множественный выбор';
      default:
        return type;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? color : Colors.grey.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? color : Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
