import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class TeacherQuestionsScreen extends StatefulWidget {
  const TeacherQuestionsScreen({super.key});

  @override
  State<TeacherQuestionsScreen> createState() => _TeacherQuestionsScreenState();
}

class _TeacherQuestionsScreenState extends State<TeacherQuestionsScreen> {
  final ApiService _api = ApiService();
  List<TeacherQuestion> _questions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.getTeacherQuestions();
    if (!mounted) return;
    setState(() {
      _questions = list;
      _loading = false;
    });
  }

  Future<void> _deleteQuestion(TeacherQuestion q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить вопрос?'),
        content: Text(
          '«${q.text.length > 60 ? '${q.text.substring(0, 60)}…' : q.text}» будет удалён без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _api.deleteTeacherQuestion(q.id);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить вопрос')),
      );
    }
  }

  Future<void> _openForm({TeacherQuestion? question}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _QuestionFormScreen(question: question),
      ),
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
      body: _questions.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _questions.length,
                itemBuilder: (ctx, i) => _QuestionCard(
                  question: _questions[i],
                  onEdit: () => _openForm(question: _questions[i]),
                  onDelete: () => _deleteQuestion(_questions[i]),
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
          Icon(Icons.quiz_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Нет вопросов',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте первый вопрос с помощью кнопки ниже',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final TeacherQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _typeColor {
    switch (question.type) {
      case 'OPEN':
        return Colors.blue;
      case 'CLOSED':
        return Colors.orange;
      case 'MULTIPLE_CHOICE':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String get _typeLabel {
    switch (question.type) {
      case 'OPEN':
        return 'Открытый';
      case 'CLOSED':
        return 'Закрытый';
      case 'MULTIPLE_CHOICE':
        return 'Множественный выбор';
      default:
        return question.type;
    }
  }

  IconData get _typeIcon {
    switch (question.type) {
      case 'OPEN':
        return Icons.edit_note_outlined;
      case 'CLOSED':
        return Icons.radio_button_checked_outlined;
      case 'MULTIPLE_CHOICE':
        return Icons.checklist_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _typeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.text,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Удалить',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (question.subjectName != null)
                  _Tag(
                    icon: Icons.menu_book_outlined,
                    label: question.subjectName!,
                    color: Colors.deepPurple,
                  ),
                _Tag(
                  icon: _typeIcon,
                  label: _typeLabel,
                  color: color,
                ),
                if (question.options.isNotEmpty)
                  _Tag(
                    icon: Icons.list_outlined,
                    label: '${question.options.length} вар.',
                    color: Colors.teal,
                  ),
              ],
            ),
          ),
          // Options preview for non-open questions
          if (question.options.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: question.options.take(4).map((opt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          opt.correct
                              ? Icons.check_circle_outline
                              : Icons.radio_button_unchecked,
                          size: 15,
                          color: opt.correct ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            opt.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: opt.correct
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Question form (create / edit)
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionFormScreen extends StatefulWidget {
  final TeacherQuestion? question;
  const _QuestionFormScreen({this.question});

  @override
  State<_QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<_QuestionFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _loadingSubjects = true;

  late final TextEditingController _text;
  String _type = 'OPEN';
  List<SubjectSummaryModel> _subjects = [];
  int? _selectedSubjectId;

  // Options for CLOSED / MULTIPLE_CHOICE
  final List<Map<String, dynamic>> _options = [];

  bool get _isEdit => widget.question != null;
  bool get _needsOptions => _type == 'CLOSED' || _type == 'MULTIPLE_CHOICE';

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _text = TextEditingController(text: q?.text ?? '');
    _type = q?.type ?? 'OPEN';
    if (q != null) {
      _selectedSubjectId = q.subjectId;
      _options.addAll(
        q.options.map((o) => {
              'text': TextEditingController(text: o.text),
              'correct': o.correct,
            }),
      );
    }
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _api.getTeacherOwnSubjects();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      if (subjects.length == 1 && _selectedSubjectId == null) {
        _selectedSubjectId = subjects.first.id;
      }
      _loadingSubjects = false;
    });
  }

  @override
  void dispose() {
    _text.dispose();
    for (final o in _options) {
      (o['text'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add({'text': TextEditingController(), 'correct': false});
    });
  }

  void _removeOption(int index) {
    final ctrl = _options[index]['text'] as TextEditingController;
    ctrl.dispose();
    setState(() => _options.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите предмет')),
      );
      return;
    }
    if (_needsOptions && _options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один вариант ответа')),
      );
      return;
    }
    if (_needsOptions && !_options.any((o) => o['correct'] == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отметьте хотя бы один правильный вариант')),
      );
      return;
    }

    setState(() => _saving = true);

    final optionsList = _needsOptions
        ? _options
            .map((o) => {
                  'text': (o['text'] as TextEditingController).text.trim(),
                  'correct': o['correct'] as bool,
                })
            .toList()
        : <Map<String, dynamic>>[];

    final body = {
      'text': _text.text.trim(),
      'type': _type,
      'subjectId': _selectedSubjectId,
      'options': optionsList,
    };

    final ok = _isEdit
        ? await _api.updateTeacherQuestion(widget.question!.id, body)
        : await _api.createTeacherQuestion(body);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при сохранении вопроса')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактировать вопрос' : 'Новый вопрос'),
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
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Subject picker ─────────────────────────────────────────────
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
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: Colors.orange, size: 18),
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
                    onTap: () =>
                        setState(() => _selectedSubjectId = s.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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
                            color: selected
                                ? theme.primaryColor
                                : Colors.grey,
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

            // ── Question type ──────────────────────────────────────────────
            Text('Тип вопроса', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Открытый',
                    icon: Icons.edit_note_outlined,
                    selected: _type == 'OPEN',
                    color: Colors.blue,
                    onTap: () => setState(() {
                      _type = 'OPEN';
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeButton(
                    label: 'Закрытый',
                    icon: Icons.radio_button_checked_outlined,
                    selected: _type == 'CLOSED',
                    color: Colors.orange,
                    onTap: () => setState(() {
                      _type = 'CLOSED';
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeButton(
                    label: 'Мн. выбор',
                    icon: Icons.checklist_outlined,
                    selected: _type == 'MULTIPLE_CHOICE',
                    color: Colors.purple,
                    onTap: () => setState(() {
                      _type = 'MULTIPLE_CHOICE';
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Question text ──────────────────────────────────────────────
            TextFormField(
              controller: _text,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Текст вопроса *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Введите текст вопроса' : null,
            ),
            const SizedBox(height: 20),

            // ── Options (for CLOSED / MULTIPLE_CHOICE) ─────────────────────
            if (_needsOptions) ...[
              Row(
                children: [
                  Text('Варианты ответов', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_options.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Добавьте варианты ответов',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                )
              else
                ..._options.asMap().entries.map((entry) {
                  final i = entry.key;
                  final opt = entry.value;
                  final isCorrect = opt['correct'] as bool;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withValues(alpha: 0.06)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Correct toggle
                        IconButton(
                          icon: Icon(
                            isCorrect
                                ? Icons.check_circle
                                : (_type == 'MULTIPLE_CHOICE'
                                    ? Icons.check_box_outline_blank
                                    : Icons.radio_button_unchecked),
                            color:
                                isCorrect ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_type == 'CLOSED') {
                                // Only one correct for CLOSED
                                for (final o in _options) {
                                  o['correct'] = false;
                                }
                              }
                              opt['correct'] = !isCorrect;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller:
                                opt['text'] as TextEditingController,
                            decoration: InputDecoration(
                              hintText: 'Вариант ${i + 1}',
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.red, size: 20),
                          onPressed: () => _removeOption(i),
                        ),
                      ],
                    ),
                  );
                }),
              if (_type == 'CLOSED')
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'Нажмите на кружок чтобы отметить правильный ответ (только один)',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                )
              else if (_type == 'MULTIPLE_CHOICE')
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'Можно отметить несколько правильных ответов',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _isEdit ? 'Сохранить изменения' : 'Создать вопрос',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
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
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? color : Colors.grey,
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
