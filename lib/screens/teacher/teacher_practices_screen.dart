import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class TeacherPracticesScreen extends StatefulWidget {
  const TeacherPracticesScreen({super.key});

  @override
  State<TeacherPracticesScreen> createState() => _TeacherPracticesScreenState();
}

class _TeacherPracticesScreenState extends State<TeacherPracticesScreen> {
  final ApiService _api = ApiService();
  List<TeacherPractice> _practices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.getTeacherPractices();
    if (!mounted) return;
    setState(() {
      _practices = list;
      _loading = false;
    });
  }

  Future<void> _deletePractice(TeacherPractice p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить практику?'),
        content: Text('«${p.name}» будет удалена без возможности восстановления.'),
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
    final ok = await _api.deleteTeacherPractice(p.id);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить практику')),
      );
    }
  }

  Future<void> _openForm({TeacherPractice? practice}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PracticeFormScreen(practice: practice),
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
      body: _practices.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _practices.length,
                itemBuilder: (ctx, i) => _PracticeCard(
                  practice: _practices[i],
                  onEdit: () => _openForm(practice: _practices[i]),
                  onDelete: () => _deletePractice(_practices[i]),
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
          Icon(Icons.assignment_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Нет практик',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Создайте первую практику с помощью кнопки ниже',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PracticeCard extends StatelessWidget {
  final TeacherPractice practice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PracticeCard(
      {required this.practice, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTeam = practice.workMode == 'TEAM';

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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isTeam
                        ? Icons.group_outlined
                        : Icons.person_outlined,
                    color: theme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        practice.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (practice.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          practice.description,
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
                            leading: Icon(Icons.delete_outline,
                                color: Colors.red),
                            title: Text('Удалить',
                                style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                            dense: true)),
                  ],
                ),
              ],
            ),
          ),

          // Tags
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (practice.subjectName != null)
                  _Tag(
                    icon: Icons.menu_book_outlined,
                    label: practice.subjectName!,
                    color: Colors.deepPurple,
                  ),
                _Tag(
                  icon: isTeam ? Icons.people_outline : Icons.person_outline,
                  label: isTeam ? 'Командная' : 'Индивидуальная',
                  color: isTeam ? Colors.indigo : Colors.teal,
                ),
                if (practice.calendarRequired)
                  _Tag(
                    icon: Icons.book_outlined,
                    label: 'Дневник',
                    color: Colors.teal,
                  ),
              ],
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
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Practice form (create / edit)
// ─────────────────────────────────────────────────────────────────────────────

class _PracticeFormScreen extends StatefulWidget {
  final TeacherPractice? practice;
  const _PracticeFormScreen({this.practice});

  @override
  State<_PracticeFormScreen> createState() => _PracticeFormScreenState();
}

class _PracticeFormScreenState extends State<_PracticeFormScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _loadingSubjects = true;

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _requirements;
  late final TextEditingController _resourceUrl;

  String _workMode = 'INDIVIDUAL';
  bool _calendarRequired = false;

  List<SubjectSummaryModel> _subjects = [];
  int? _selectedSubjectId;

  bool get _isEdit => widget.practice != null;

  @override
  void initState() {
    super.initState();
    final p = widget.practice;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _requirements = TextEditingController(text: p?.requirements ?? '');
    _resourceUrl = TextEditingController(text: p?.resourceUrl ?? '');
    _workMode = p?.workMode ?? 'INDIVIDUAL';
    _calendarRequired = p?.calendarRequired ?? false;
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _api.getTeacherOwnSubjects();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      // If editing and only one subject, pre-select it
      if (subjects.length == 1) _selectedSubjectId = subjects.first.id;
      _loadingSubjects = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _requirements.dispose();
    _resourceUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите предмет')),
      );
      return;
    }
    setState(() => _saving = true);

    final body = {
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'requirements': _requirements.text.trim(),
      'resourceUrl': _resourceUrl.text.trim().isEmpty
          ? null
          : _resourceUrl.text.trim(),
      'workMode': _workMode,
      'schedulingRequired': _calendarRequired,
      'allowedSubmissionTypes': ['TEXT'],
      'subjectId': _selectedSubjectId,
    };

    final ok = _isEdit
        ? await _api.updateTeacherPractice(widget.practice!.id, body)
        : await _api.createTeacherPractice(body);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при сохранении практики')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактировать практику' : 'Новая практика'),
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
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
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

            // ── Name ─────────────────────────────────────────────────────────
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Название *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Введите название' : null,
            ),
            const SizedBox(height: 14),

            // ── Description ──────────────────────────────────────────────────
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // ── Requirements ─────────────────────────────────────────────────
            TextFormField(
              controller: _requirements,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Требования к работе',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.checklist_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // ── Resource URL ─────────────────────────────────────────────────
            TextFormField(
              controller: _resourceUrl,
              decoration: const InputDecoration(
                labelText: 'Ссылка на ресурс',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),

            // ── Work mode ────────────────────────────────────────────────────
            Text('Режим выполнения', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Индивидуальная',
                    icon: Icons.person_outlined,
                    selected: _workMode == 'INDIVIDUAL',
                    onTap: () => setState(() => _workMode = 'INDIVIDUAL'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    label: 'Командная',
                    icon: Icons.group_outlined,
                    selected: _workMode == 'TEAM',
                    onTap: () => setState(() => _workMode = 'TEAM'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Calendar required ────────────────────────────────────────────
            SwitchListTile(
              value: _calendarRequired,
              onChanged: (v) => setState(() => _calendarRequired = v),
              title: const Text('Требуется дневник'),
              subtitle: const Text('Студенты будут вести ежедневный журнал'),
              secondary: const Icon(Icons.book_outlined),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                    _isEdit ? 'Сохранить изменения' : 'Создать практику',
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

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton(
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
            color: selected ? theme.primaryColor : Colors.grey.withValues(alpha: 0.3),
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
