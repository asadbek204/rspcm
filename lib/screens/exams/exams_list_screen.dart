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
    if (exam.status == 'PUBLISHED') return 'Available';
    if (exam.status == 'COMPLETED' || exam.status == 'CANCELLED') return 'Closed';
    return 'Not Open';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Exams')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _exams.isEmpty
                  ? const Center(child: Text('No exams found'))
                  : ListView.builder(
                      itemCount: _exams.length,
                      itemBuilder: (context, index) {
                        final exam = _exams[index];
                        return ListTile(
                          title: Text(exam.title),
                          subtitle: Text(
                            '${exam.type} • ${_studentStatusLabel(exam)}'
                            '${exam.endAt != null ? '\nDeadline: ${DateFormat('dd MMM yyyy, HH:mm').format(exam.endAt!)}' : ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ExamParticipationScreen(exam: exam)),
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
  State<ExamParticipationScreen> createState() => _ExamParticipationScreenState();
}

class _ExamParticipationScreenState extends State<ExamParticipationScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<ExamPracticeOption> _options = [];
  MyExamParticipation? _participation;
  final TextEditingController _submissionTextController = TextEditingController();
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
    final options = isPracticeExam ? await _apiService.getExamPractices(widget.exam.id) : <ExamPracticeOption>[];
    final participation = await _apiService.getMyExamParticipation(widget.exam.id);
    final attempt = widget.exam.type == 'QUESTION' ? await _apiService.getMyExamAttempt(widget.exam.id) : null;
    if (!mounted) return;
    setState(() {
      _options = options;
      _participation = participation;
      _attempt = attempt;
      _isLoading = false;
    });
  }

  Future<void> _selectPractice(int examPracticeId) async {
    final ok = await _apiService.selectExamPractice(widget.exam.id, examPracticeId);
    if (!mounted) return;
    if (ok) {
      await _load();
    }
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
    final available = await _apiService.getAvailableStudentsForInvite(_participation!.participationId);
    if (!mounted || available.isEmpty) return;
    final selected = <int>{};
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Members'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(StudentSummary member) async {
    if (_participation == null) return;
    final ok = await _apiService.removeTeamMember(_participation!.participationId, member.id);
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

  @override
  void dispose() {
    _submissionTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
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
                          Text(widget.exam.description.isEmpty ? 'No description' : widget.exam.description),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text('Type: ${widget.exam.type}')),
                              Chip(label: Text('Status: ${widget.exam.status}')),
                              if (widget.exam.startAt != null)
                                Chip(label: Text('Start: ${dateFmt.format(widget.exam.startAt!)}')),
                              if (widget.exam.endAt != null)
                                Chip(label: Text('End: ${dateFmt.format(widget.exam.endAt!)}')),
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
                          'This exam is not available yet. It will open when published. Current status: ${widget.exam.status}.',
                        ),
                      ),
                    )
                  else if (widget.exam.type == 'QUESTION') ...[
                    const Text('Question Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildQuestionExamSummaryCard(),
                  ] else ...[
                    if (_participation == null) ...[
                      const Text('Practice Choices', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_options.isEmpty)
                        Card(
                          color: Colors.amber.withValues(alpha: 0.08),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No practice options are configured for this exam.'),
                          ),
                        )
                      else
                        ..._options.map((option) => Card(
                              child: ListTile(
                                title: Text(option.practice.title),
                                subtitle: Text(option.practice.description),
                                trailing: ElevatedButton(
                                  onPressed: () => _selectPractice(option.id),
                                  child: const Text('Select'),
                                ),
                              ),
                            )),
                    ] else ...[
                      Card(
                        color: Colors.blue.withValues(alpha: 0.06),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Practice is already selected. To choose another one, first leave team or cancel participation.',
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  if (_participation != null) ...[
                    const Text('My Participation', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Practice: ${_participation!.practice.title}'),
                            Text('Status: ${_participation!.status}'),
                            Text(
                              _participation!.submission == null
                                  ? 'Submission: not submitted'
                                  : 'Submission: ${_participation!.submission!.status}',
                            ),
                            if (widget.exam.endAt != null)
                              Text('Submit before: ${dateFmt.format(widget.exam.endAt!)}'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(onPressed: _inviteMembers, child: const Text('Invite Members')),
                                OutlinedButton(onPressed: _leaveTeam, child: const Text('Leave Team')),
                                OutlinedButton(onPressed: _cancelParticipation, child: const Text('Cancel Participation')),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text('Members:', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            ..._participation!.members.map((member) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('${member.firstName} ${member.lastName}'),
                                  subtitle: Text(member.email),
                                  trailing: IconButton(
                                    onPressed: () => _removeMember(member),
                                    icon: const Icon(Icons.person_remove_alt_1_outlined),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Practice Submission', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (widget.exam.type != 'PRACTICE')
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Submission is available only for practice exams.'),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _submissionTextController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter submission text',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: widget.exam.type == 'PRACTICE' ? _submitPractice : null,
                      child: const Text('Submit'),
                    ),
                    if (_participation!.submission != null) ...[
                      const SizedBox(height: 8),
                      Text('Current status: ${_participation!.submission!.status}'),
                      if (_participation!.submission!.teacherComment.isNotEmpty)
                        Text('Teacher comment: ${_participation!.submission!.teacherComment}'),
                    ]
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildQuestionExamSummaryCard() {
    final total = widget.exam.questions.length;
    final open = widget.exam.questions.where((q) => q.questionType == 'OPEN').length;
    final closed = widget.exam.questions.where((q) => q.questionType == 'CLOSED').length;
    final multi = widget.exam.questions.where((q) => q.questionType == 'MULTIPLE_CHOICE').length;

    final isSubmitted = _attempt?.status == 'SUBMITTED' || _attempt?.status == 'GRADED';
    final hasStarted = _attempt?.status == 'STARTED';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total questions: $total'),
            const SizedBox(height: 6),
            Text('Open: $open'),
            Text('Closed: $closed'),
            Text('Multiple choice: $multi'),
            if (widget.exam.taskLimit > 0) ...[
              const SizedBox(height: 6),
              Text('Time limit: ${widget.exam.taskLimit} min'),
            ],
            if (_attempt != null) ...[
              const SizedBox(height: 6),
              Text('Attempt: ${_attempt!.status}'),
              if (_attempt!.status == 'STARTED' && _attempt!.remainingSeconds != null)
                Text('Time left: ${_formatDuration(_attempt!.remainingSeconds!)}'),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startingTest || isSubmitted
                    ? null
                    : () async {
                        setState(() => _startingTest = true);
                        final ok = hasStarted ? true : await _apiService.startExamAttempt(widget.exam.id);
                        if (!mounted) return;
                        setState(() => _startingTest = false);
                        if (!ok) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuestionTestScreen(exam: widget.exam),
                          ),
                        );
                      },
                child: _startingTest
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isSubmitted ? 'Already Submitted' : (hasStarted ? 'Resume Test' : 'Start Test')),
              ),
            )
          ],
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
        const SnackBar(content: Text('Time is over. Test submitted automatically.')),
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

  Future<void> _saveCurrentAnswer() async {
    if (_questions.isEmpty) return;
    final current = _questions[_index];
    setState(() => _isSaving = true);
    final ok = await _apiService.saveExamAnswer(
      widget.exam.id,
      current.id,
      textAnswer: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
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
        title: const Text('Submit Test'),
        content: const Text('Are you sure you want to submit? You will not be able to edit answers after submit.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
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
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Leave without saving?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
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
        body: const Center(child: Text('No questions available')),
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
        title: Text('Test: ${widget.exam.title}'),
        actions: [
          if (_remainingSeconds != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _formatDuration(_remainingSeconds!),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          TextButton(
            onPressed: _submitTest,
            child: const Text('Submit'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${_index + 1}/${_questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              _lastSavedQuestionId == q.id && !_isDirty ? 'Saved' : (_isDirty ? 'Unsaved changes' : 'Not saved yet'),
              style: TextStyle(
                color: _isDirty ? Colors.orange : Colors.green,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(q.questionText),
            const SizedBox(height: 12),
            if (isOpen)
              TextField(
                controller: _textController,
                maxLines: 6,
                onChanged: (_) => setState(() => _isDirty = true),
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Type your answer'),
              )
            else
              Expanded(
                child: ListView(
                  children: q.options.map((opt) {
                    final selected = _selectedOptionIds.contains(opt.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) {
                        setState(() {
                          _isDirty = true;
                          if (isMultiple) {
                            if (value == true) {
                              _selectedOptionIds.add(opt.id);
                            } else {
                              _selectedOptionIds.remove(opt.id);
                            }
                          } else {
                            _selectedOptionIds
                              ..clear()
                              ..add(opt.id);
                          }
                        });
                      },
                      title: Text(opt.text),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _index == 0
                      ? null
                      : () async {
                          await _saveCurrentAnswer();
                          if (!mounted) return;
                          setState(() => _index -= 1);
                          _syncQuestionState();
                        },
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          await _saveCurrentAnswer();
                          if (!mounted) return;
                          if (_index < _questions.length - 1) {
                            setState(() => _index += 1);
                            _syncQuestionState();
                          }
                        },
                  child: _isSaving ? const Text('Saving...') : const Text('Save & Next'),
                ),
              ],
            )
          ],
        ),
      ),
    ));
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
