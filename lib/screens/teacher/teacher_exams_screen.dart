import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'teacher_exam_detail_screen.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen> {
  final ApiService _api = ApiService();
  List<TeacherExam> _exams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.getTeacherExams();
    if (!mounted) return;
    setState(() {
      _exams = list;
      _loading = false;
    });
  }

  Future<void> _deleteExam(TeacherExam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить экзамен?'),
        content: Text('«${exam.title}» будет удалён без возможности восстановления.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _api.deleteTeacherExam(exam.id);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить экзамен')),
      );
    }
  }

  Future<void> _openForm({TeacherExam? exam}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _ExamFormScreen(exam: exam)),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Создать'),
      ),
      body: _exams.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _exams.length,
                itemBuilder: (ctx, i) => _ExamCard(
                  exam: _exams[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherExamDetailScreen(exam: _exams[i]),
                    ),
                  ).then((_) => _load()),
                  onEdit: () => _openForm(exam: _exams[i]),
                  onDelete: () => _deleteExam(_exams[i]),
                ),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Нет экзаменов',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Создайте первый экзамен с помощью кнопки ниже',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exam card
// ─────────────────────────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final TeacherExam exam;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ExamCard({
    required this.exam,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  (Color, String) get _statusInfo {
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

  bool get _isPractice => exam.type == 'PRACTICE';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd MMM yyyy', 'ru_RU');
    final (statusColor, statusLabel) = _statusInfo;
    final accent = _isPractice ? Colors.orange.shade700 : theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
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
                        Text(
                          exam.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isPractice
                              ? 'Практический экзамен'
                              : 'Тестовый экзамен',
                          style: TextStyle(
                              color: accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Редактировать'),
                              contentPadding: EdgeInsets.zero,
                              dense: true)),
                      const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                              leading:
                                  Icon(Icons.delete_outline, color: Colors.red),
                              title: Text('Удалить',
                                  style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                              dense: true)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Subject tag
              if (exam.subjectName != null) ...[
                Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 13, color: Colors.deepPurple.shade400),
                    const SizedBox(width: 4),
                    Text(
                      exam.subjectName!,
                      style: TextStyle(
                        color: Colors.deepPurple.shade400,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Meta row
              Row(
                children: [
                  // Status
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  // Count
                  Icon(
                    _isPractice
                        ? Icons.assignment_outlined
                        : Icons.list_alt_outlined,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPractice
                        ? '${exam.practiceCount} вариантов'
                        : '${exam.questionCount} вопросов',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 12.5),
                  ),
                  const Spacer(),
                  // Groups
                  if (exam.groups.isNotEmpty) ...[
                    Icon(Icons.group_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      exam.groups.map((g) => g.name).join(', '),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),

              // Dates
              if (exam.startAt != null || exam.endAt != null) ...[
                const SizedBox(height: 8),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exam form (create / edit)
// ─────────────────────────────────────────────────────────────────────────────

class _ExamFormScreen extends StatefulWidget {
  final TeacherExam? exam;
  const _ExamFormScreen({this.exam});

  @override
  State<_ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends State<_ExamFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _loadingSubjects = true;

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _maxScore;
  late final TextEditingController _taskLimit;

  String _type = 'PRACTICE';
  DateTime? _startAt;
  DateTime? _endAt;

  List<TeacherGroup> _groups = [];
  final Set<int> _selectedGroupIds = {};

  List<SubjectSummaryModel> _subjects = [];
  int? _selectedSubjectId;

  bool get _isEdit => widget.exam != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exam;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _maxScore = TextEditingController(text: e?.maxScore.toString() ?? '100');
    _taskLimit = TextEditingController(text: e?.taskLimit.toString() ?? '60');
    _type = e?.type ?? 'PRACTICE';
    _startAt = e?.startAt;
    _endAt = e?.endAt;
    _selectedSubjectId = e?.subjectId;
    if (e != null) {
      _selectedGroupIds.addAll(e.groups.map((g) => g.id));
    }
    _loadGroups();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _api.getTeacherOwnSubjects();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      if (_selectedSubjectId == null && subjects.length == 1) {
        _selectedSubjectId = subjects.first.id;
      }
      _loadingSubjects = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _maxScore.dispose();
    _taskLimit.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final groups = await _api.getTeacherGroups();
    if (!mounted) return;
    setState(() => _groups = groups);
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startAt ?? now)
          : (_endAt ?? now.add(const Duration(days: 7))),
      firstDate: isStart ? now.subtract(const Duration(days: 1)) : (isStart ? now : now),
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('ru', 'RU'),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;
    final dt = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
    setState(() {
      if (isStart) {
        _startAt = dt;
      } else {
        _endAt = dt;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите предмет')),
      );
      return;
    }
    if (_startAt == null || _endAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите даты начала и окончания')),
      );
      return;
    }

    setState(() => _saving = true);

    final body = {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'startAt': _startAt!.toIso8601String(),
      'endAt': _endAt!.toIso8601String(),
      'maxScore': int.tryParse(_maxScore.text.trim()) ?? 100,
      'taskLimit': int.tryParse(_taskLimit.text.trim()) ?? 60,
      'type': _type,
      'groupIds': _selectedGroupIds.toList(),
      'studentIds': <int>[],
      'subjectId': _selectedSubjectId,
    };

    final ok = _isEdit
        ? await _api.updateTeacherExam(widget.exam!.id, body)
        : await _api.createTeacherExam(body);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при сохранении экзамена')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd.MM.yyyy HH:mm', 'ru_RU');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактировать экзамен' : 'Новый экзамен'),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(
                onPressed: _save,
                child: const Text('Сохранить',
                    style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Subject picker ───────────────────────────────────────────────
            Text('Предмет *', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_loadingSubjects)
              const Center(child: CircularProgressIndicator())
            else if (_subjects.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Вам не назначены предметы. Обратитесь к администратору.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _subjects.map((s) {
                  final selected = _selectedSubjectId == s.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSubjectId = s.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.primaryColor.withValues(alpha: 0.12)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? theme.primaryColor
                              : Colors.grey.withValues(alpha: 0.3),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 16,
                            color: selected ? theme.primaryColor : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.name,
                            style: TextStyle(
                              color: selected ? theme.primaryColor : null,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Название *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Введите название' : null,
            ),
            const SizedBox(height: 14),

            // Description
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Type
            Text('Тип экзамена', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Практика',
                    icon: Icons.handyman_outlined,
                    selected: _type == 'PRACTICE',
                    onTap: () => setState(() => _type = 'PRACTICE'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeButton(
                    label: 'Тест',
                    icon: Icons.quiz_outlined,
                    selected: _type == 'QUESTION',
                    onTap: () => setState(() => _type = 'QUESTION'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dates
            Text('Сроки', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Начало',
                    value: _startAt != null ? fmt.format(_startAt!) : 'Выбрать',
                    icon: Icons.play_circle_outline,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateTile(
                    label: 'Окончание',
                    value: _endAt != null ? fmt.format(_endAt!) : 'Выбрать',
                    icon: Icons.stop_circle_outlined,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Max score + task limit
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxScore,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Макс. балл *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.stars_outlined),
                    ),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                        ? 'Введите балл > 0'
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _taskLimit,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Лимит (мин) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                        ? 'Введите лимит > 0'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Groups
            Text('Группы', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_groups.isEmpty)
              Text('Нет доступных групп',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13))
            else
              ..._groups.map((g) => CheckboxListTile(
                    value: _selectedGroupIds.contains(g.id),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selectedGroupIds.add(g.id);
                      } else {
                        _selectedGroupIds.remove(g.id);
                      }
                    }),
                    title: Text(g.name),
                    subtitle: Text(
                        '${g.students.length} студентов · ${g.language}'),
                    secondary: const Icon(Icons.group_outlined),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isEdit ? 'Сохранить изменения' : 'Создать экзамен',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.primaryColor : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected ? theme.primaryColor : Colors.grey.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _DateTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
