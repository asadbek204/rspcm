import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final Function(int) onTabSelected;
  const TeacherDashboardScreen({super.key, required this.onTabSelected});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;

  List<TeacherExam> _exams = [];
  List<TeacherPractice> _practices = [];
  List<TeacherGroup> _groups = [];
  int _pendingSubmissions = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.getTeacherExams(),
      _api.getTeacherPractices(),
      _api.getTeacherGroups(),
    ]);

    final exams = results[0] as List<TeacherExam>;
    final practices = results[1] as List<TeacherPractice>;
    final groups = results[2] as List<TeacherGroup>;

    // Count pending (SUBMITTED) submissions across all published exams
    int pending = 0;
    for (final exam in exams.where((e) => e.status == 'PUBLISHED' && e.type == 'PRACTICE')) {
      final subs = await _api.getSubmissionsByExam(exam.id, status: 'SUBMITTED');
      pending += subs.length;
    }

    if (!mounted) return;
    setState(() {
      _exams = exams;
      _practices = practices;
      _groups = groups;
      _pendingSubmissions = pending;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── Greeting ─────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor.withValues(alpha: 0.85),
                        theme.primaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Добро пожаловать!',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              auth.displayName.isNotEmpty
                                  ? auth.displayName
                                  : 'Преподаватель',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (auth.teacherProfile != null &&
                                auth.teacherProfile!.academicDegree.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                auth.teacherProfile!.academicDegree,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          auth.displayName.isNotEmpty
                              ? auth.displayName[0].toUpperCase()
                              : 'П',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Stats row ────────────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.fact_check_outlined,
                      label: 'Экзамены',
                      value: _exams.length.toString(),
                      color: theme.primaryColor,
                      onTap: () => widget.onTabSelected(2),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.assignment_outlined,
                      label: 'Практики',
                      value: _practices.length.toString(),
                      color: Colors.teal,
                      onTap: () => widget.onTabSelected(1),
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.group_outlined,
                      label: 'Группы',
                      value: _groups.length.toString(),
                      color: Colors.indigo,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Pending submissions banner ────────────────────────────────
                if (_pendingSubmissions > 0)
                  GestureDetector(
                    onTap: () => widget.onTabSelected(2),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.pending_actions_outlined,
                                color: Colors.orange, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_pendingSubmissions ${_submissionWord(_pendingSubmissions)} ожидает проверки',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Перейдите в экзамены для проверки',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Colors.orange),
                        ],
                      ),
                    ),
                  ),

                // ── Active exams ─────────────────────────────────────────────
                const SizedBox(height: 4),
                _DashSectionHeader(
                  title: 'Активные экзамены',
                  icon: Icons.fact_check_outlined,
                  onMore: () => widget.onTabSelected(2),
                ),
                const SizedBox(height: 10),
                ..._exams
                    .where((e) => e.status == 'PUBLISHED')
                    .take(3)
                    .map((e) => _ExamRow(exam: e)),
                if (_exams.where((e) => e.status == 'PUBLISHED').isEmpty)
                  _EmptyHint(
                    text: 'Нет активных экзаменов',
                    onTap: () => widget.onTabSelected(2),
                  ),
                const SizedBox(height: 20),

                // ── Groups ───────────────────────────────────────────────────
                _DashSectionHeader(
                  title: 'Мои группы',
                  icon: Icons.group_outlined,
                ),
                const SizedBox(height: 10),
                ..._groups.take(4).map((g) => _GroupRow(group: g)),
                if (_groups.isEmpty)
                  _EmptyHint(text: 'Группы не назначены'),
              ],
            ),
    );
  }

  String _submissionWord(int n) {
    if (n == 1) return 'работа';
    if (n >= 2 && n <= 4) return 'работы';
    return 'работ';
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500]),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onMore;
  const _DashSectionHeader(
      {required this.title, required this.icon, this.onMore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        if (onMore != null)
          TextButton(
            onPressed: onMore,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Все →', style: TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}

class _ExamRow extends StatelessWidget {
  final TeacherExam exam;
  const _ExamRow({required this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPractice = exam.type == 'PRACTICE';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPractice ? Icons.handyman_outlined : Icons.quiz_outlined,
              size: 20,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  isPractice
                      ? '${exam.practiceCount} вариантов практики'
                      : '${exam.questionCount} вопросов',
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final TeacherGroup group;
  const _GroupRow({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.group_outlined,
                size: 20, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  '${group.students.length} студентов · ${group.language}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _EmptyHint({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(text,
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ),
      ),
    );
  }
}
