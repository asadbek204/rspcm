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

  // Map: exam → list of submissions for that exam
  List<_ExamSubmissions> _groups = [];
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

    final results = await Future.wait(
      practiceExams.map((e) => _api.getSubmissionsByExam(e.id, size: 200)),
    );

    final groups = <_ExamSubmissions>[];
    for (var i = 0; i < practiceExams.length; i++) {
      final subs = results[i];
      if (subs.isNotEmpty) {
        groups.add(_ExamSubmissions(exam: practiceExams[i], submissions: subs));
      }
    }

    if (!mounted) return;
    setState(() {
      _groups = groups;
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
    return _groups.fold(0, (sum, g) => sum + g.submissions.length);
  }

  int _countByStatus(String status) {
    return _groups.fold(
        0, (sum, g) => sum + g.submissions.where((s) => s.status == status).length);
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
            child: filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final group = filtered[i];
                      return _ExamGroup(
                        group: group,
                        onRefresh: _load,
                      );
                    },
                  ),
          ),
        ],
      ),
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
