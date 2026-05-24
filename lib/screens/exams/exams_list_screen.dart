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
                            '${exam.type} • ${exam.status}'
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final options = await _apiService.getExamPractices(widget.exam.id);
    final participation = await _apiService.getMyExamParticipation(widget.exam.id);
    if (!mounted) return;
    setState(() {
      _options = options;
      _participation = participation;
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
                  const Text('Available Practices', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_options.isEmpty)
                    Card(
                      color: Colors.amber.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          widget.exam.type != 'PRACTICE'
                              ? 'No practices because this exam type is ${widget.exam.type}.'
                              : widget.exam.status != 'PUBLISHED'
                                  ? 'No practices yet because exam status is ${widget.exam.status}.'
                                  : 'No practice options found for this exam.',
                        ),
                      ),
                    ),
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
                        child: Text('Submission is available only for PRACTICE exams.'),
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
}
