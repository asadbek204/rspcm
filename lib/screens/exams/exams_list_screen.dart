import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Exam list
// ─────────────────────────────────────────────────────────────────────────────

class ExamsListScreen extends StatefulWidget {
  const ExamsListScreen({super.key});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<StudentExam> _exams = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _api.getMyExams();
    if (!mounted) return;
    setState(() {
      _exams = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: _exams.isEmpty
          ? const Center(child: Text('Экзамены не назначены'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: _exams.length,
              itemBuilder: (ctx, i) => _ExamCard(
                exam: _exams[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExamDetailScreen(exam: _exams[i]),
                  ),
                ).then((_) => _load()),
              ),
            ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final StudentExam exam;
  final VoidCallback onTap;

  const _ExamCard({required this.exam, required this.onTap});

  bool get _isPractice => exam.type == 'PRACTICE';

  Color _accent(BuildContext context) {
    if (exam.status == 'COMPLETED') return Colors.grey.shade600;
    if (exam.status == 'CANCELLED') return Colors.red.shade600;
    return _isPractice
        ? Colors.orange.shade700
        : Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final fmt = DateFormat('dd MMM', 'ru_RU');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accent.withValues(alpha: 0.25)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isPractice
                        ? Icons.handyman_outlined
                        : Icons.quiz_outlined,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              exam.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: exam.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPractice
                            ? 'Практический экзамен'
                            : 'Тестовый экзамен',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isPractice)
                        Row(
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${exam.practiceCount} ${_variantLabel(exam.practiceCount)}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12.5),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.list_alt_outlined,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${exam.questionCount} ${_questionLabel(exam.questionCount)}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12.5),
                            ),
                            if (exam.taskLimit > 0) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.timer_outlined,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '${exam.taskLimit} мин',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12.5),
                              ),
                            ],
                          ],
                        ),
                      if (exam.startAt != null || exam.endAt != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (exam.startAt != null) ...[
                              Icon(Icons.play_circle_outline,
                                  size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(fmt.format(exam.startAt!),
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12)),
                              const SizedBox(width: 10),
                            ],
                            if (exam.endAt != null) ...[
                              Icon(Icons.stop_circle_outlined,
                                  size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Text(fmt.format(exam.endAt!),
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12)),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _variantLabel(int n) {
    if (n == 1) return 'вариант';
    if (n >= 2 && n <= 4) return 'варианта';
    return 'вариантов';
  }

  String _questionLabel(int n) {
    if (n == 1) return 'вопрос';
    if (n >= 2 && n <= 4) return 'вопроса';
    return 'вопросов';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exam detail — dispatches to practice or question body
// ─────────────────────────────────────────────────────────────────────────────

class ExamDetailScreen extends StatelessWidget {
  final StudentExam exam;

  const ExamDetailScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exam.title)),
      body: exam.type == 'PRACTICE'
          ? _PracticeExamBody(exam: exam)
          : _QuestionExamBody(exam: exam),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Practice exam
// ─────────────────────────────────────────────────────────────────────────────

class _PracticeExamBody extends StatefulWidget {
  final StudentExam exam;
  const _PracticeExamBody({required this.exam});

  @override
  State<_PracticeExamBody> createState() => _PracticeExamBodyState();
}

class _PracticeExamBodyState extends State<_PracticeExamBody> {
  final ApiService _api = ApiService();
  bool _loading = true;
  List<ExamPracticeOption> _options = [];
  MyExamParticipation? _participation;
  final _submissionCtrl = TextEditingController();

  StudentExam get exam => widget.exam;
  bool get _isGraded => _participation?.submission?.status == 'GRADED';

  bool _isLeader(BuildContext context) {
    final myId = Provider.of<AuthProvider>(context, listen: false).profile?.userId;
    if (myId == null || _participation == null) return false;
    return _participation!.members.any((m) => m.user.id == myId && m.isLeader);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _submissionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.getExamPractices(exam.id),
      _api.getMyExamParticipation(exam.id),
    ]);
    if (!mounted) return;
    setState(() {
      _options = results[0] as List<ExamPracticeOption>;
      _participation = results[1] as MyExamParticipation?;
      _loading = false;
    });
  }

  Future<void> _selectPractice(int examPracticeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Выбрать этот вариант?'),
        content: const Text(
            'После выбора вы сможете пригласить участников и сдать работу.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Выбрать')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _api.selectExamPractice(exam.id, examPracticeId);
    if (!mounted || !ok) return;
    await _load();
  }

  Future<void> _inviteMembers() async {
    if (_participation == null) return;
    final available =
        await _api.getAvailableStudentsForInvite(_participation!.participationId);
    if (!mounted || available.isEmpty) return;
    final selected = <int>{};
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пригласить в команду'),
        content: StatefulBuilder(
          builder: (_, setLocal) => SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: available
                  .map((s) => CheckboxListTile(
                        value: selected.contains(s.id),
                        onChanged: (v) => setLocal(() {
                          if (v == true) {
                            selected.add(s.id);
                          } else {
                            selected.remove(s.id);
                          }
                        }),
                        title: Text('${s.firstName} ${s.lastName}'),
                        subtitle: Text(s.email),
                      ))
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: selected.isEmpty
                ? null
                : () async {
                    await _api.inviteTeamMembersByParticipation(
                        _participation!.participationId, selected.toList());
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    await _load();
                  },
            child: const Text('Пригласить'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveTeam() async {
    if (_participation == null) return;
    final ok = await _api.leaveTeam(_participation!.participationId);
    if (!mounted || !ok) return;
    await _load();
  }

  Future<void> _cancelParticipation() async {
    final ok = await _api.cancelExamParticipation(exam.id);
    if (!mounted || !ok) return;
    await _load();
  }

  Future<void> _removeMember(StudentSummary member) async {
    if (_participation == null) return;
    final ok =
        await _api.removeTeamMember(_participation!.participationId, member.id);
    if (!mounted || !ok) return;
    await _load();
  }

  Future<void> _submit() async {
    if (_participation == null) return;
    final ok = await _api.submitPracticeSubmission(
      _participation!.participationId,
      textAnswer: _submissionCtrl.text.trim(),
    );
    if (!mounted || !ok) return;
    _submissionCtrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ExamHeaderCard(exam: exam),
          const SizedBox(height: 20),
          if (exam.status != 'PUBLISHED')
            _InfoBanner(
              icon: Icons.lock_outline,
              color: Colors.orange,
              text:
                  'Экзамен пока недоступен. Статус: ${_statusLabel(exam.status)}',
            )
          else if (_participation == null)
            _buildSelectionSection()
          else
            _buildParticipationSection(),
        ],
      ),
    );
  }

  Widget _buildSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
            title: 'Выберите вариант практики',
            icon: Icons.assignment_outlined),
        const SizedBox(height: 12),
        if (_options.isEmpty)
          const _InfoBanner(
            icon: Icons.info_outline,
            color: Colors.amber,
            text: 'Варианты практики для этого экзамена ещё не добавлены.',
          )
        else
          ..._options.map(
            (opt) => _PracticeOptionCard(
              option: opt,
              exam: exam,
              onSelect: () => _selectPractice(opt.id),
            ),
          ),
      ],
    );
  }

  Widget _buildParticipationSection() {
    final p = _participation!;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'ru_RU');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chosen practice ──────────────────────────────────────────────────
        const _SectionHeader(
            title: 'Выбранная практика', icon: Icons.check_circle_outline),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        p.practice.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ParticipationBadge(status: p.status),
                  ],
                ),
                if (p.practice.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(p.practice.description,
                      style:
                          TextStyle(color: Colors.grey[700], height: 1.35)),
                ],
                if (exam.endAt != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.alarm,
                          size: 15, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Сдать до: ${dateFmt.format(exam.endAt!)}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Team ─────────────────────────────────────────────────────────────
        const _SectionHeader(title: 'Команда', icon: Icons.group_outlined),
        const SizedBox(height: 10),
        Builder(builder: (ctx) {
          final isLeader = _isLeader(ctx);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.members.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('Участники ещё не добавлены.',
                      style: TextStyle(color: Colors.grey[600])),
                )
              else
                ...p.members.map((m) {
                  final name = '${m.user.firstName} ${m.user.lastName}'.trim();
                  final initial = m.user.firstName.isNotEmpty ? m.user.firstName[0] : '?';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: CircleAvatar(child: Text(initial)),
                      title: Row(
                        children: [
                          Text(name),
                          const SizedBox(width: 8),
                          if (m.isLeader)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
                              ),
                              child: Text('Лидер',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade800)),
                            ),
                        ],
                      ),
                      subtitle: Text(m.user.email, style: const TextStyle(fontSize: 12)),
                      trailing: isLeader && !m.isLeader
                          ? IconButton(
                              icon: const Icon(Icons.person_remove_alt_1_outlined, size: 20),
                              onPressed: () => _removeMember(m.user),
                              tooltip: 'Удалить из команды',
                            )
                          : null,
                    ),
                  );
                }),
              const SizedBox(height: 12),
              // Кнопки для лидера
              if (isLeader) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _inviteMembers,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('Пригласить участника'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Кнопки для всех участников
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _leaveTeam,
                      icon: const Icon(Icons.exit_to_app_outlined, size: 18),
                      label: const Text('Покинуть'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelParticipation,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Отменить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
        const SizedBox(height: 24),

        // ── Submission ───────────────────────────────────────────────────────
        const _SectionHeader(
            title: 'Сдача работы', icon: Icons.upload_file_outlined),
        const SizedBox(height: 10),
        if (_isGraded)
          const _InfoBanner(
            icon: Icons.check_circle,
            color: Colors.green,
            text: 'Работа проверена. Редактирование недоступно.',
          )
        else
          Builder(builder: (ctx) {
            final isLeader = _isLeader(ctx);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isLeader)
                  const _InfoBanner(
                    icon: Icons.info_outline,
                    color: Colors.blue,
                    text: 'Только лидер команды может отправить работу на проверку.',
                  )
                else ...[
                  TextField(
                    controller: _submissionCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'Опишите выполненную работу...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Отправить на проверку'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
        if (p.submission != null) ...[
          const SizedBox(height: 12),
          _SubmissionCard(submission: p.submission!),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Question exam
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionExamBody extends StatefulWidget {
  final StudentExam exam;
  const _QuestionExamBody({required this.exam});

  @override
  State<_QuestionExamBody> createState() => _QuestionExamBodyState();
}

class _QuestionExamBodyState extends State<_QuestionExamBody> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _starting = false;
  StudentExamAttemptInfo? _attempt;

  StudentExam get exam => widget.exam;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final attempt = await _api.getMyExamAttempt(exam.id);
    if (!mounted) return;
    setState(() {
      _attempt = attempt;
      _loading = false;
    });
  }

  Future<void> _startOrContinue() async {
    final hasStarted = _attempt?.status == 'STARTED';
    if (!hasStarted) {
      setState(() => _starting = true);
      final ok = await _api.startExamAttempt(exam.id);
      if (!mounted) return;
      setState(() => _starting = false);
      if (!ok) return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuestionTestScreen(exam: exam)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final isSubmitted =
        _attempt?.status == 'SUBMITTED' || _attempt?.status == 'GRADED';
    final hasStarted = _attempt?.status == 'STARTED';

    // Question type breakdown from pre-loaded list (may be empty before attempt)
    final total = exam.questions.length;
    final open =
        exam.questions.where((q) => q.questionType == 'OPEN').length;
    final closed =
        exam.questions.where((q) => q.questionType == 'CLOSED').length;
    final multi = exam.questions
        .where((q) => q.questionType == 'MULTIPLE_CHOICE')
        .length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ExamHeaderCard(exam: exam),
          const SizedBox(height: 20),
          if (exam.status != 'PUBLISHED')
            _InfoBanner(
              icon: Icons.lock_outline,
              color: Colors.orange,
              text:
                  'Экзамен пока недоступен. Статус: ${_statusLabel(exam.status)}',
            )
          else ...[
            const _SectionHeader(
                title: 'О тесте', icon: Icons.info_outline),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question stats
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatChip(
                          label: 'Всего',
                          value: exam.questionCount > 0
                              ? exam.questionCount.toString()
                              : total.toString(),
                          icon: Icons.list_alt_outlined,
                        ),
                        if (open > 0)
                          _StatChip(
                            label: 'Открытые',
                            value: open.toString(),
                            icon: Icons.edit_outlined,
                          ),
                        if (closed > 0)
                          _StatChip(
                            label: 'Закрытые',
                            value: closed.toString(),
                            icon: Icons.radio_button_checked_outlined,
                          ),
                        if (multi > 0)
                          _StatChip(
                            label: 'Мн. выбор',
                            value: multi.toString(),
                            icon: Icons.checklist_outlined,
                          ),
                      ],
                    ),
                    if (exam.taskLimit > 0) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Ограничение по времени: ${exam.taskLimit} мин',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (_attempt != null) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      _AttemptStatus(attempt: _attempt!),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            isSubmitted || _starting ? null : _startOrContinue,
                        icon: _starting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              )
                            : Icon(isSubmitted
                                ? Icons.check_circle_outline
                                : Icons.play_arrow_rounded),
                        label: Text(
                          isSubmitted
                              ? 'Тест сдан'
                              : (hasStarted
                                  ? 'Продолжить тест'
                                  : 'Начать тест'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Question test screen
// ─────────────────────────────────────────────────────────────────────────────

class QuestionTestScreen extends StatefulWidget {
  final StudentExam exam;

  const QuestionTestScreen({super.key, required this.exam});

  @override
  State<QuestionTestScreen> createState() => _QuestionTestScreenState();
}

class _QuestionTestScreenState extends State<QuestionTestScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  int _index = 0;
  List<ExamQuestionItem> _questions = [];
  final _textCtrl = TextEditingController();
  final Set<int> _selectedIds = {};
  bool _isDirty = false;
  int? _lastSavedId;
  StudentExamAttemptInfo? _attempt;
  Timer? _timer;
  int? _remaining;
  bool _timeoutSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final questions = await _api.getMyExamQuestions(widget.exam.id);
    final attempt = await _api.getMyExamAttempt(widget.exam.id);
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _attempt = attempt;
      _remaining = attempt?.remainingSeconds;
      _loading = false;
    });
    _startTimer();
    _syncState();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_attempt?.status != 'STARTED' || _remaining == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final cur = _remaining;
      if (cur == null) return;
      if (cur <= 0) {
        _timer?.cancel();
        if (_timeoutSubmitting) return;
        _timeoutSubmitting = true;
        await _autoSubmit();
        _timeoutSubmitting = false;
        return;
      }
      setState(() => _remaining = cur - 1);
    });
  }

  Future<void> _autoSubmit() async {
    if (_isDirty) await _save();
    if (!mounted) return;
    final ok = await _api.submitExamAttempt(widget.exam.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Время вышло. Тест отправлен автоматически.')),
      );
      Navigator.pop(context);
    } else {
      await _load();
    }
  }

  void _syncState() {
    if (_questions.isEmpty || _index >= _questions.length) return;
    final q = _questions[_index];
    _textCtrl.text = q.textAnswer;
    _selectedIds
      ..clear()
      ..addAll(q.selectedOptionIds);
  }

  double get _progress =>
      _questions.isEmpty ? 0 : (_index + 1) / _questions.length;

  int get _answeredCount {
    var count = 0;
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final isCurrent = i == _index;
      final answered = isCurrent
          ? _textCtrl.text.trim().isNotEmpty || _selectedIds.isNotEmpty
          : q.textAnswer.trim().isNotEmpty || q.selectedOptionIds.isNotEmpty;
      if (answered) count++;
    }
    return count;
  }

  Future<void> _save() async {
    if (_questions.isEmpty) return;
    final q = _questions[_index];
    setState(() => _saving = true);
    final ok = await _api.saveExamAnswer(
      widget.exam.id,
      q.id,
      textAnswer: _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim(),
      selectedOptionIds: _selectedIds.toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _lastSavedId = q.id;
      _isDirty = false;
      await _load();
    }
  }

  Future<void> _submitTest() async {
    if (_isDirty) await _save();
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Отправить тест?'),
        content: const Text(
            'После отправки изменить ответы будет невозможно.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Отправить')),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _api.submitExamAttempt(widget.exam.id);
    if (mounted && ok) Navigator.pop(context);
  }

  Future<bool> _confirmLeave() async {
    if (!_isDirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Выйти без сохранения текущего ответа?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Остаться')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Выйти')),
        ],
      ),
    );
    return leave == true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.exam.title)),
        body: const Center(child: Text('Вопросы отсутствуют')),
      );
    }

    final q = _questions[_index];
    final isOpen = q.questionType == 'OPEN';
    final isMulti = q.questionType == 'MULTIPLE_CHOICE';

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_isDirty) return;
        final nav = Navigator.of(context);
        final leave = await _confirmLeave();
        if (mounted && leave) nav.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Тест: ${widget.exam.title}'),
          actions: [
            if (_remaining != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (_remaining ?? 0) <= 60
                          ? Colors.red.withValues(alpha: 0.14)
                          : Colors.green.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _fmtDuration(_remaining!),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: (_remaining ?? 0) <= 60
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            TextButton(
                onPressed: _submitTest,
                child: const Text('Завершить')),
          ],
        ),
        bottomNavigationBar: _buildNavBar(isOpen, isMulti),
        body: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress header
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Вопрос ${_index + 1} из ${_questions.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    minHeight: 7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Save state indicator
                          Tooltip(
                            message: _lastSavedId == q.id && !_isDirty
                                ? 'Сохранено'
                                : (_isDirty
                                    ? 'Есть несохранённые изменения'
                                    : 'Ещё не сохранено'),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _lastSavedId == q.id && !_isDirty
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : (_isDirty
                                        ? Colors.orange.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.1)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _lastSavedId == q.id && !_isDirty
                                    ? Icons.check
                                    : (_isDirty
                                        ? Icons.edit_outlined
                                        : Icons.circle_outlined),
                                size: 16,
                                color: _lastSavedId == q.id && !_isDirty
                                    ? Colors.green.shade700
                                    : (_isDirty
                                        ? Colors.orange.shade700
                                        : Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Отвечено: $_answeredCount из ${_questions.length}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12.5),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isOpen
                                  ? 'Открытый'
                                  : (isMulti
                                      ? 'Мн. выбор'
                                      : 'Закрытый'),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Question text
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    q.questionText,
                    style:
                        const TextStyle(fontSize: 16, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Answer area
              if (isOpen)
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: (_) => setState(() => _isDirty = true),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Введите ответ...',
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: q.options.map((opt) {
                      final selected = _selectedIds.contains(opt.id);
                      if (isMulti) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: selected
                                ? BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.6))
                                : BorderSide.none,
                          ),
                          child: CheckboxListTile(
                            value: selected,
                            onChanged: (v) => setState(() {
                              _isDirty = true;
                              if (v == true) {
                                _selectedIds.add(opt.id);
                              } else {
                                _selectedIds.remove(opt.id);
                              }
                            }),
                            title: Text(opt.text),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                      // Single-choice (CLOSED)
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: selected
                              ? BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.6))
                              : BorderSide.none,
                        ),
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.05)
                            : null,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() {
                            _isDirty = true;
                            _selectedIds
                              ..clear()
                              ..add(opt.id);
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: selected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(opt.text)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(bool isOpen, bool isMulti) {
    final isLast = _index == _questions.length - 1;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
              top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _index == 0 || _saving
                    ? null
                    : () async {
                        await _save();
                        if (!mounted) return;
                        setState(() => _index -= 1);
                        _syncState();
                      },
                child: const Text('Назад'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        await _save();
                        if (!mounted) return;
                        if (isLast) {
                          await _submitTest();
                          return;
                        }
                        setState(() => _index += 1);
                        _syncState();
                      },
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isLast ? 'Отправить тест' : 'Сохранить и далее'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDuration(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ExamHeaderCard extends StatelessWidget {
  final StudentExam exam;
  const _ExamHeaderCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm', 'ru_RU');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exam.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: exam.status),
              ],
            ),
            if (exam.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(exam.description,
                  style: const TextStyle(height: 1.4)),
            ],
            if (exam.startAt != null || exam.endAt != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (exam.startAt != null)
                _DateRow(
                    icon: Icons.play_circle_outline,
                    label: 'Начало',
                    value: fmt.format(exam.startAt!)),
              if (exam.endAt != null)
                _DateRow(
                    icon: Icons.stop_circle_outlined,
                    label: 'Окончание',
                    value: fmt.format(exam.endAt!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DateRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoBanner(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}

class _PracticeOptionCard extends StatelessWidget {
  final ExamPracticeOption option;
  final StudentExam exam;
  final VoidCallback onSelect;
  const _PracticeOptionCard(
      {required this.option, required this.exam, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final p = option.practice;
    final fmt = DateFormat('dd.MM HH:mm', 'ru_RU');
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isTeam = p.workMode == 'TEAM';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isTeam ? Icons.group_outlined : Icons.person_outlined,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (p.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          p.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Chips ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (isTeam)
                  _InfoChip(
                    icon: Icons.people_outline,
                    label: 'Команда · ${p.teamSize} чел.',
                    color: Colors.indigo,
                  ),
                _InfoChip(
                  icon: p.calendarRequired
                      ? Icons.book_outlined
                      : Icons.menu_book_outlined,
                  label: p.calendarRequired ? 'Дневник нужен' : 'Дневник не нужен',
                  color: p.calendarRequired ? Colors.teal : Colors.grey,
                ),
              ],
            ),
          ),

          // ── Requirements ──────────────────────────────────────────────────
          if ((p.requirements ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.checklist_outlined,
                        size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.requirements!.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey[700], fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Dates ─────────────────────────────────────────────────────────
          if (exam.startAt != null || exam.endAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  if (exam.startAt != null) ...[
                    Icon(Icons.play_circle_outline,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(fmt.format(exam.startAt!),
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12.5)),
                    const SizedBox(width: 12),
                  ],
                  if (exam.endAt != null) ...[
                    Icon(Icons.stop_circle_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(fmt.format(exam.endAt!),
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12.5)),
                  ],
                ],
              ),
            ),

          // ── Select button ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onSelect,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  'Выбрать этот вариант',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  (Color, String) get _info {
    switch (status) {
      case 'PUBLISHED':
        return (Colors.green.shade700, 'Открыт');
      case 'COMPLETED':
        return (Colors.grey.shade600, 'Завершён');
      case 'CANCELLED':
        return (Colors.red.shade700, 'Отменён');
      default:
        return (Colors.orange.shade700, 'Не открыт');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _ParticipationBadge extends StatelessWidget {
  final String status;
  const _ParticipationBadge({required this.status});

  (Color, String) get _info {
    switch (status) {
      case 'PRACTICE_CHOSEN':
        return (Colors.green.shade700, 'Выбрано');
      case 'READY_TO_CHOOSE':
        return (Colors.blue.shade700, 'Готово к выбору');
      case 'WAITING_MEMBERS':
        return (Colors.orange.shade700, 'Ждём команду');
      default:
        return (Colors.grey.shade600, 'Формирование');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final PracticeSubmission submission;
  const _SubmissionCard({required this.submission});

  (Color, String, IconData) get _info {
    switch (submission.status) {
      case 'GRADED':
        return (Colors.green.shade700, 'Проверено', Icons.check_circle);
      case 'RETURNED':
        return (
          Colors.orange.shade700,
          'Возвращено на доработку',
          Icons.replay_outlined
        );
      default:
        return (Colors.blue.shade700, 'На проверке', Icons.hourglass_top_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _info;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          if (submission.teacherComment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Комментарий преподавателя: ${submission.teacherComment}',
                style: TextStyle(color: Colors.grey[700])),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text('$label: $value',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

class _AttemptStatus extends StatelessWidget {
  final StudentExamAttemptInfo attempt;
  const _AttemptStatus({required this.attempt});

  (Color, String) get _info {
    switch (attempt.status) {
      case 'STARTED':
        return (Colors.blue.shade700, 'Начат');
      case 'SUBMITTED':
        return (Colors.orange.shade700, 'На проверке');
      case 'GRADED':
        return (Colors.green.shade700, 'Проверен');
      default:
        return (Colors.grey.shade600, attempt.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Статус: ', style: TextStyle(color: Colors.grey[600])),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        if (attempt.status == 'SUBMITTED') ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_top_outlined, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Text('Ожидается проверка открытых вопросов',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 13)),
              ],
            ),
          ),
        ],
        if (attempt.status == 'GRADED' && attempt.totalScore != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text('Итоговый балл: ',
                    style: TextStyle(color: Colors.green.shade700, fontSize: 14)),
                Text('${attempt.totalScore}',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

String _statusLabel(String status) {
  switch (status) {
    case 'DRAFT':
      return 'Черновик';
    case 'PUBLISHED':
      return 'Опубликован';
    case 'COMPLETED':
      return 'Завершён';
    case 'CANCELLED':
      return 'Отменён';
    default:
      return status;
  }
}
