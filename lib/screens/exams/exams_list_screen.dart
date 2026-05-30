import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class ExamsListScreen extends StatefulWidget {
  const ExamsListScreen({super.key});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<StudentExam> _exams = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _apiService.getMyExams();
    if (!mounted) return;
    setState(() {
      _exams = data;
      _isLoading = false;
    });
  }

  String _studentStatusLabel(StudentExam exam) {
    if (exam.status == 'PUBLISHED') return 'Доступен';
    if (exam.status == 'COMPLETED' || exam.status == 'CANCELLED') {
      return 'Закрыт';
    }
    return 'Не открыт';
  }

  String _examTypeLabel(String type) {
    switch (type) {
      case 'QUESTION':
        return 'Тест';
      case 'PRACTICE':
        return 'Практический экзамен';
      default:
        return type;
    }
  }

  Color _statusColor(StudentExam exam) {
    if (exam.status == 'PUBLISHED') return Colors.green;
    if (exam.status == 'COMPLETED') return Colors.grey;
    if (exam.status == 'CANCELLED') return Colors.red;
    return Colors.orange;
  }

  IconData _statusIcon(StudentExam exam) {
    if (exam.status == 'PUBLISHED') return Icons.check_circle;
    if (exam.status == 'COMPLETED') return Icons.task_alt;
    if (exam.status == 'CANCELLED') return Icons.cancel;
    return Icons.schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои экзамены')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _exams.isEmpty
                  ? const Center(child: Text('Экзамены не найдены'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      itemCount: _exams.length,
                      itemBuilder: (context, index) {
                        final exam = _exams[index];
                        final dateText = exam.endAt != null
                            ? 'Срок: ${DateFormat('dd MMM yyyy, HH:mm', 'ru_RU').format(exam.endAt!)}'
                            : null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExamParticipationScreen(exam: exam),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      child: Icon(
                                        exam.type == 'QUESTION'
                                            ? Icons.help_outline
                                            : Icons.build_outlined,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exam.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                _statusIcon(exam),
                                                size: 16,
                                                color: _statusColor(exam),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _studentStatusLabel(exam),
                                                style: TextStyle(
                                                  color: _statusColor(exam),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _examTypeLabel(exam.type),
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (dateText != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              dateText,
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Icon(
                                              Icons.arrow_circle_right_outlined,
                                              size: 22,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class ExamParticipationScreen extends StatefulWidget {
  final StudentExam exam;

  const ExamParticipationScreen({super.key, required this.exam});

  @override
  State<ExamParticipationScreen> createState() =>
      _ExamParticipationScreenState();
}

class _ExamParticipationScreenState extends State<ExamParticipationScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<ExamPracticeOption> _options = [];
  MyExamParticipation? _participation;
  final TextEditingController _submissionTextController =
      TextEditingController();
  bool _startingTest = false;
  StudentExamAttemptInfo? _attempt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final isPracticeExam = widget.exam.type == 'PRACTICE';
    final options = isPracticeExam
        ? await _apiService.getExamPractices(widget.exam.id)
        : <ExamPracticeOption>[];
    final participation = await _apiService.getMyExamParticipation(
      widget.exam.id,
    );
    final attempt = widget.exam.type == 'QUESTION'
        ? await _apiService.getMyExamAttempt(widget.exam.id)
        : null;
    if (!mounted) return;
    setState(() {
      _options = options;
      _participation = participation;
      _attempt = attempt;
      _isLoading = false;
    });
  }

  Future<void> _selectPractice(int examPracticeId) async {
    final confirmed = await _confirmPracticeSelection();
    if (!confirmed) return;

    final ok = await _apiService.selectExamPractice(
      widget.exam.id,
      examPracticeId,
    );
    if (!mounted) return;
    if (ok) {
      await _load();
    }
  }

  Future<bool> _confirmPracticeSelection() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите выбрать эту практику?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да, выбрать'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _cancelParticipation() async {
    final ok = await _apiService.cancelExamParticipation(widget.exam.id);
    if (!mounted) return;
    if (ok) {
      await _load();
    }
  }

  Future<void> _inviteMembers() async {
    if (_participation == null) return;
    final available = await _apiService.getAvailableStudentsForInvite(
      _participation!.participationId,
    );
    if (!mounted || available.isEmpty) return;
    final selected = <int>{};
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пригласить участников'),
        content: StatefulBuilder(
          builder: (context, setLocalState) => SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: available.map((student) {
                return CheckboxListTile(
                  value: selected.contains(student.id),
                  onChanged: (value) {
                    setLocalState(() {
                      if (value == true) {
                        selected.add(student.id);
                      } else {
                        selected.remove(student.id);
                      }
                    });
                  },
                  title: Text('${student.firstName} ${student.lastName}'),
                  subtitle: Text(student.email),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: selected.isEmpty
                ? null
                : () async {
                    await _apiService.inviteTeamMembersByParticipation(
                      _participation!.participationId,
                      selected.toList(),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await _load();
                  },
            child: const Text('Пригласить'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(StudentSummary member) async {
    if (_participation == null) return;
    final ok = await _apiService.removeTeamMember(
      _participation!.participationId,
      member.id,
    );
    if (!mounted) return;
    if (ok) {
      await _load();
    }
  }

  Future<void> _leaveTeam() async {
    if (_participation == null) return;
    final ok = await _apiService.leaveTeam(_participation!.participationId);
    if (!mounted) return;
    if (ok) {
      await _load();
    }
  }

  Future<void> _submitPractice() async {
    if (_participation == null) return;
    final ok = await _apiService.submitPracticeSubmission(
      _participation!.participationId,
      textAnswer: _submissionTextController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _submissionTextController.clear();
      await _load();
    }
  }

  String _examTypeLabel(String type) {
    switch (type) {
      case 'QUESTION':
        return 'Тест';
      case 'PRACTICE':
        return 'Практический экзамен';
      default:
        return type;
    }
  }

  IconData _examTypeIcon(String type) {
    switch (type) {
      case 'QUESTION':
        return Icons.quiz_outlined;
      case 'PRACTICE':
        return Icons.handyman_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  String _workModeLabel(String workMode) {
    switch (workMode) {
      case 'TEAM':
        return 'Командный';
      case 'INDIVIDUAL':
        return 'Индивидуальный';
      default:
        return workMode;
    }
  }

  String _examStatusLabel(String status) {
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

  String _participationStatusLabel(String status) {
    switch (status) {
      case 'FORMING':
        return 'Формирование';
      case 'WAITING_MEMBERS':
        return 'Ожидание участников';
      case 'READY_TO_CHOOSE':
        return 'Готово к выбору';
      case 'PRACTICE_CHOSEN':
        return 'Практика выбрана';
      default:
        return status;
    }
  }

  String _submissionStatusLabel(String status) {
    switch (status) {
      case 'SUBMITTED':
        return 'Отправлено';
      case 'RETURNED':
        return 'Возвращено';
      case 'GRADED':
        return 'Проверено';
      default:
        return status;
    }
  }

  String _attemptStatusLabel(String status) {
    switch (status) {
      case 'STARTED':
        return 'Начат';
      case 'SUBMITTED':
        return 'Отправлен';
      case 'GRADED':
        return 'Проверен';
      default:
        return status;
    }
  }

  String _examStatusSymbol(String status) {
    switch (status) {
      case 'PUBLISHED':
        return '✓';
      case 'COMPLETED':
        return '■';
      case 'CANCELLED':
        return '×';
      case 'DRAFT':
        return '•';
      default:
        return '?';
    }
  }

  Color _examStatusForeground(String status) {
    switch (status) {
      case 'PUBLISHED':
        return Colors.green.shade700;
      case 'COMPLETED':
        return Colors.grey.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      case 'DRAFT':
        return Colors.orange.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  void dispose() {
    _submissionTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final shortDateFmt = DateFormat('dd.MM HH:mm');
    final isPracticeGraded = _participation?.submission?.status == 'GRADED';
    final canChangePractice =
        _participation != null &&
        !isPracticeGraded &&
        _participation!.status != 'PRACTICE_CHOSEN';
    return Scaffold(
      appBar: AppBar(title: Text(widget.exam.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              widget.exam.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.exam.description.isNotEmpty) ...[
                            Text(
                              widget.exam.description,
                              style: const TextStyle(height: 1.35),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Compact metadata chips: type, calendar/scheduled, workmode(s), team size(s), subject (if known)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text(_examTypeLabel(widget.exam.type))),
                              Tooltip(
                                message: _examStatusLabel(widget.exam.status),
                                child: Chip(
                                  label: Text(
                                    _examStatusSymbol(widget.exam.status),
                                    style: TextStyle(
                                      color: _examStatusForeground(widget.exam.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: _examStatusForeground(widget.exam.status).withValues(alpha: 0.12),
                                ),
                              ),

                              // If we have practice options loaded, show aggregated practice metadata
                              if (_options.isNotEmpty) ...[
                                Chip(
                                  avatar: const Icon(Icons.calendar_month_outlined, size: 16),
                                  label: Text(_options.any((o) => o.practice.calendarRequired) ? 'План: нужен' : 'План: не нужен'),
                                ),
                                Chip(
                                  avatar: const Icon(Icons.groups_outlined, size: 16),
                                  label: Text(_workModeLabel(_options.first.practice.workMode) + (_options.length > 1 ? '…' : '')),
                                ),
                                Chip(
                                  avatar: const Icon(Icons.people_outline, size: 16),
                                  label: Text('Команда: ${_options.map((o) => o.practice.teamSize).toSet().join(', ')}'),
                                ),
                              ] else ...[
                                // Fallbacks when no options loaded
                                Chip(
                                  avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                                  label: Text(widget.exam.startAt != null || widget.exam.endAt != null ? 'Запланировано' : 'Без даты'),
                                ),
                              ],
                            ],
                          ),

                          // Small muted start/end line
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.exam.startAt != null ? 'Начало: ${shortDateFmt.format(widget.exam.startAt!)}' : 'Начало: -',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.exam.endAt != null ? 'Окончание: ${shortDateFmt.format(widget.exam.endAt!)}' : 'Окончание: -',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.exam.status != 'PUBLISHED')
                    Card(
                      color: Colors.orange.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Этот экзамен пока недоступен. Он откроется после публикации. Текущий статус: ${_examStatusLabel(widget.exam.status)}.',
                        ),
                      ),
                    )
                  else if (widget.exam.type == 'QUESTION') ...[
                    const Text(
                      'Тестовый экзамен',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildQuestionExamSummaryCard(),
                  ] else ...[
                    if (_participation == null) ...[
                      const Text(
                        'Выбор практики',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_options.isEmpty)
                        Card(
                          color: Colors.amber.withValues(alpha: 0.08),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Для этого экзамена не настроены варианты практики.',
                            ),
                          ),
                        )
                      else
                        ..._options.map(
                          (option) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.practice.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    option.practice.description,
                                    style: TextStyle(color: Colors.grey[800]),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Chip(
                                        avatar: Icon(
                                          _examTypeIcon(widget.exam.type),
                                          size: 16,
                                        ),
                                        label: Text(_examTypeLabel(widget.exam.type)),
                                      ),
                                      Chip(
                                        avatar: const Icon(Icons.groups_outlined, size: 16),
                                        label: Text(_workModeLabel(option.practice.workMode)),
                                      ),
                                      Chip(
                                        avatar: const Icon(Icons.people_outline, size: 16),
                                        label: Text('Команда: ${option.practice.teamSize}'),
                                      ),
                                      Chip(
                                        avatar: const Icon(Icons.calendar_month_outlined, size: 16),
                                        label: Text(option.practice.calendarRequired ? 'План: нужен' : 'План: не нужен'),
                                      ),
                                    ],
                                  ),
                                  if ((option.practice.requirements ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Требования: ${option.practice.requirements!.trim()}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${widget.exam.startAt != null ? shortDateFmt.format(widget.exam.startAt!) : '-'}  •  ${widget.exam.endAt != null ? shortDateFmt.format(widget.exam.endAt!) : '-'}',
                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _selectPractice(option.id),
                                        child: const Text('Выбрать'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ] else ...[
                      if (canChangePractice)
                        Card(
                          color: Colors.blue.withValues(alpha: 0.06),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Чтобы выбрать другую практику, сначала выйдите из текущей команды.',
                            ),
                          ),
                        ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  if (_participation != null) ...[
                    const Text(
                      'Мое участие',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.blue.withValues(alpha: 0.03),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.12),
                                  child: Icon(
                                    Icons.group,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _participation!.practice.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _participation!.submission == null
                                            ? 'Отправка не сделана'
                                            : 'Отправка: ${_submissionStatusLabel(_participation!.submission!.status)}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message:
                                      'Статус участия: ${_participationStatusLabel(_participation!.status)}',
                                  child: Chip(
                                    label: Text(
                                      _participation!.status ==
                                              'PRACTICE_CHOSEN'
                                          ? '✓'
                                          : _participation!.status ==
                                                'READY_TO_CHOOSE'
                                          ? '▲'
                                          : _participation!.status ==
                                                'WAITING_MEMBERS'
                                          ? '…'
                                          : '•',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    backgroundColor:
                                        _participation!.status ==
                                            'PRACTICE_CHOSEN'
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : _participation!.status ==
                                              'READY_TO_CHOOSE'
                                        ? Colors.blue.withValues(alpha: 0.12)
                                        : _participation!.status ==
                                              'WAITING_MEMBERS'
                                        ? Colors.orange.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (widget.exam.endAt != null)
                              Text(
                                'Отправить до: ${dateFmt.format(widget.exam.endAt!)}',
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: canChangePractice
                                  ? [
                                      OutlinedButton(
                                        onPressed: _inviteMembers,
                                        child: const Text('Пригласить'),
                                      ),
                                      OutlinedButton(
                                        onPressed: _leaveTeam,
                                        child: const Text('Покинуть команду'),
                                      ),
                                      OutlinedButton(
                                        onPressed: _cancelParticipation,
                                        child: const Text('Отменить участие'),
                                      ),
                                    ]
                                  : const [],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Участники',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            ..._participation!.members.map((member) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 2,
                                  ),
                                  leading: CircleAvatar(
                                    child: Text(
                                      member.firstName.isNotEmpty
                                          ? member.firstName[0]
                                          : '?',
                                    ),
                                  ),
                                  title: Text(
                                    '${member.firstName} ${member.lastName}',
                                  ),
                                  subtitle: Text(member.email),
                                  trailing: isPracticeGraded
                                      ? null
                                      : IconButton(
                                          onPressed: () =>
                                              _removeMember(member),
                                          icon: const Icon(
                                            Icons.person_remove_alt_1_outlined,
                                          ),
                                        ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Отправка практики',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (widget.exam.type != 'PRACTICE')
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Отправка доступна только для практических экзаменов.',
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _submissionTextController,
                      maxLines: 4,
                      enabled: !isPracticeGraded,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Введите текст отправки',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          widget.exam.type == 'PRACTICE' && !isPracticeGraded
                          ? _submitPractice
                          : null,
                      child: const Text('Отправить'),
                    ),
                    if (_participation!.submission != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Текущий статус: ${_submissionStatusLabel(_participation!.submission!.status)}',
                      ),
                      if (_participation!.submission!.teacherComment.isNotEmpty)
                        Text(
                          'Комментарий преподавателя: ${_participation!.submission!.teacherComment}',
                        ),
                      if (isPracticeGraded)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Работа проверена. Редактирование и действия с командой недоступны.',
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildQuestionExamSummaryCard() {
    final total = widget.exam.questions.length;
    final open = widget.exam.questions
        .where((q) => q.questionType == 'OPEN')
        .length;
    final closed = widget.exam.questions
        .where((q) => q.questionType == 'CLOSED')
        .length;
    final multi = widget.exam.questions
        .where((q) => q.questionType == 'MULTIPLE_CHOICE')
        .length;

    final isSubmitted =
        _attempt?.status == 'SUBMITTED' || _attempt?.status == 'GRADED';
    final hasStarted = _attempt?.status == 'STARTED';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statChip('Всего', total.toString()),
                _statChip('Открытые', open.toString()),
                _statChip('Закрытые', closed.toString()),
                _statChip('Мн. выбор', multi.toString()),
              ],
            ),
            if (widget.exam.taskLimit > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Лимит: ${widget.exam.taskLimit} мин',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            if (_attempt != null) ...[
              const SizedBox(height: 10),
              Text('Попытка: ${_attemptStatusLabel(_attempt!.status)}'),
              if (_attempt!.status == 'STARTED' &&
                  _attempt!.remainingSeconds != null)
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_bottom,
                      size: 18,
                      color: _attempt!.remainingSeconds! <= 60
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Осталось: ${_formatDuration(_attempt!.remainingSeconds!)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _attempt!.remainingSeconds! <= 60
                            ? Colors.red
                            : null,
                      ),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startingTest || isSubmitted
                    ? null
                    : () async {
                        setState(() => _startingTest = true);
                        final ok = hasStarted
                            ? true
                            : await _apiService.startExamAttempt(
                                widget.exam.id,
                              );
                        if (!mounted) return;
                        setState(() => _startingTest = false);
                        if (!ok) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                QuestionTestScreen(exam: widget.exam),
                          ),
                        );
                      },
                child: _startingTest
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isSubmitted
                            ? 'Уже отправлено'
                            : (hasStarted ? 'Продолжить тест' : 'Начать тест'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class QuestionTestScreen extends StatefulWidget {
  final StudentExam exam;

  const QuestionTestScreen({super.key, required this.exam});

  @override
  State<QuestionTestScreen> createState() => _QuestionTestScreenState();
}

class _QuestionTestScreenState extends State<QuestionTestScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  int _index = 0;
  List<ExamQuestionItem> _questions = [];
  final TextEditingController _textController = TextEditingController();
  final Set<int> _selectedOptionIds = {};
  bool _isDirty = false;
  int? _lastSavedQuestionId;
  StudentExamAttemptInfo? _attemptInfo;
  Timer? _timer;
  int? _remainingSeconds;
  bool _timeoutSubmitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _apiService.getMyExamQuestions(widget.exam.id);
    final attempt = await _apiService.getMyExamAttempt(widget.exam.id);
    if (!mounted) return;
    setState(() {
      _questions = data;
      _attemptInfo = attempt;
      _remainingSeconds = attempt?.remainingSeconds;
      _isLoading = false;
    });
    _setupTimer();
    _syncQuestionState();
  }

  void _setupTimer() {
    _timer?.cancel();
    if (_attemptInfo?.status != 'STARTED' || _remainingSeconds == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      final current = _remainingSeconds;
      if (current == null) return;
      if (current <= 0) {
        timer.cancel();
        if (_timeoutSubmitting) return;
        _timeoutSubmitting = true;
        await _submitByTimeout();
        _timeoutSubmitting = false;
        return;
      }
      setState(() => _remainingSeconds = current - 1);
    });
  }

  Future<void> _submitByTimeout() async {
    if (_isDirty) {
      await _saveCurrentAnswer();
      if (!mounted) return;
    }
    final ok = await _apiService.submitExamAttempt(widget.exam.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Время вышло. Тест отправлен автоматически.'),
        ),
      );
      Navigator.pop(context);
    } else {
      await _load();
    }
  }

  void _syncQuestionState() {
    if (_questions.isEmpty || _index >= _questions.length) return;
    final current = _questions[_index];
    _textController.text = current.textAnswer;
    _selectedOptionIds
      ..clear()
      ..addAll(current.selectedOptionIds);
  }

  double _questionProgress() {
    if (_questions.isEmpty) return 0;
    return (_index + 1) / _questions.length;
  }

  int _answeredCount() {
    if (_questions.isEmpty) return 0;
    var count = 0;
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final isCurrent = i == _index;
      final hasAnswer = isCurrent
          ? _textController.text.trim().isNotEmpty ||
                _selectedOptionIds.isNotEmpty
          : question.textAnswer.trim().isNotEmpty ||
                question.selectedOptionIds.isNotEmpty;
      if (hasAnswer) count++;
    }
    return count;
  }

  Widget _buildBottomBar({required bool isOpen, required bool isMultiple}) {
    final isLast = _index == _questions.length - 1;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _index == 0 || _isSaving
                    ? null
                    : () async {
                        await _saveCurrentAnswer();
                        if (!mounted) return;
                        setState(() => _index -= 1);
                        _syncQuestionState();
                      },
                child: const Text('Назад'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        await _saveCurrentAnswer();
                        if (!mounted) return;
                        if (isLast) {
                          await _submitTest();
                          return;
                        }
                        setState(() => _index += 1);
                        _syncQuestionState();
                      },
                child: _isSaving
                    ? const Text('Сохранение...')
                    : Text(
                        isLast
                            ? 'Отправить тест'
                            : (isOpen
                                  ? 'Сохранить и дальше'
                                  : (isMultiple
                                        ? 'Сохранить и дальше'
                                        : 'Сохранить и дальше')),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCurrentAnswer() async {
    if (_questions.isEmpty) return;
    final current = _questions[_index];
    setState(() => _isSaving = true);
    final ok = await _apiService.saveExamAnswer(
      widget.exam.id,
      current.id,
      textAnswer: _textController.text.trim().isEmpty
          ? null
          : _textController.text.trim(),
      selectedOptionIds: _selectedOptionIds.toList(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      _lastSavedQuestionId = current.id;
      _isDirty = false;
      await _load();
    }
  }

  Future<void> _submitTest() async {
    if (_isDirty) {
      await _saveCurrentAnswer();
      if (!mounted) return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отправить тест'),
        content: const Text(
          'Вы уверены, что хотите отправить? После отправки ответы изменить нельзя.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _apiService.submitExamAttempt(widget.exam.id);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Несохраненные изменения'),
        content: const Text(
          'У вас есть несохраненные изменения. Выйти без сохранения?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    return shouldLeave == true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
    final isMultiple = q.questionType == 'MULTIPLE_CHOICE';

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_isDirty) return;
        final shouldLeave = await _onWillPop();
        if (!mounted) return;
        if (shouldLeave) Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Тест: ${widget.exam.title}'),
          actions: [
            if (_remainingSeconds != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (_remainingSeconds ?? 0) <= 60
                          ? Colors.red.withValues(alpha: 0.14)
                          : Colors.green.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _formatDuration(_remainingSeconds!),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: (_remainingSeconds ?? 0) <= 60
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            TextButton(onPressed: _submitTest, child: const Text('Отправить')),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(
          isOpen: isOpen,
          isMultiple: isMultiple,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Card(
                  color: Colors.blue.withValues(alpha: 0.03),
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
                                    'Вопрос ${_index + 1}/${_questions.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: _questionProgress(),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Tooltip(
                              message: _lastSavedQuestionId == q.id && !_isDirty
                                  ? 'Сохранено'
                                  : (_isDirty
                                        ? 'Есть несохраненные изменения'
                                        : 'Еще не сохранено'),
                              child: Chip(
                                label: Text(
                                  _lastSavedQuestionId == q.id && !_isDirty
                                      ? '✓'
                                      : (_isDirty ? '!' : '•'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Отвечено: ${_answeredCount()} из ${_questions.length}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      q.questionText,
                      style: const TextStyle(fontSize: 16, height: 1.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isOpen)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _textController,
                      maxLines: 6,
                      onChanged: (_) => setState(() => _isDirty = true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Введите ответ',
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: q.options.map((opt) {
                      final selected = _selectedOptionIds.contains(opt.id);
                      if (isMultiple) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: CheckboxListTile(
                            value: selected,
                            onChanged: (value) {
                              setState(() {
                                _isDirty = true;
                                if (value == true) {
                                  _selectedOptionIds.add(opt.id);
                                } else {
                                  _selectedOptionIds.remove(opt.id);
                                }
                              });
                            },
                            title: Text(opt.text),
                          ),
                        );
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          selected: selected,
                          selectedTileColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.06),
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                          title: Text(opt.text),
                          onTap: () {
                            setState(() {
                              _isDirty = true;
                              _selectedOptionIds
                                ..clear()
                                ..add(opt.id);
                            });
                          },
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

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
