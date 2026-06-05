import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../practices/practice_detail_screen.dart';
import '../exams/exams_list_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabSelected;
  const DashboardScreen({super.key, this.onTabSelected});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  StudentDashboardResponse? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated && auth.profile == null && !auth.isLoading) {
        auth.fetchProfile();
      }
    });
  }

  Future<void> _navigateToItem(BuildContext context, DashboardItem item) async {
    final nav = Navigator.of(context);
    if (item.type == 'PRACTICE') {
      final result = await _apiService.getMyParticipationByPracticeId(item.id);
      if (result != null && mounted) {
        nav.push(MaterialPageRoute(
          builder: (_) => PracticeDetailScreen(
            practice: result.practice,
            participationId: result.participationId,
            preloadedTeam: result.team,
          ),
        ));
      }
    } else {
      final exams = await _apiService.getMyExams();
      final matches = exams.where((e) => e.id == item.id);
      if (matches.isNotEmpty && mounted) {
        nav.push(MaterialPageRoute(
          builder: (_) => ExamDetailScreen(exam: matches.first),
        ));
      }
    }
  }

  Future<void> _load() async {
    final data = await _apiService.getStudentDashboard();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final practices = _data?.practices ?? [];
    final exams = _data?.exams ?? [];

    // Soonest unfinished practice deadline
    DashboardItem? urgentItem;
    final now = DateTime.now();
    final upcoming = [...practices, ...exams]
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    for (final item in upcoming) {
      if (item.deadline.isAfter(now)) {
        urgentItem = item;
        break;
      }
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, auth),
            const SizedBox(height: 24),
            urgentItem != null
                ? _buildUrgentCard(context, urgentItem)
                : _buildAllClearCard(context),
            const SizedBox(height: 28),
            _buildQuickStats(context, practices.length, exams.length),
            const SizedBox(height: 28),
            _buildSectionHeader(context, 'Мои практики', onTap: () => widget.onTabSelected?.call(1)),
            const SizedBox(height: 12),
            _buildItemList(context, practices, isPractice: true),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Мои экзамены', onTap: () => widget.onTabSelected?.call(3)),
            const SizedBox(height: 12),
            _buildItemList(context, exams, isPractice: false),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    final theme = Theme.of(context);
    final profile = auth.profile;
    final firstName = profile?.firstName ?? 'Студент';
    final lastName = profile?.lastName ?? '';
    final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
          child: Text(
            initials,
            style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('С возвращением,',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              Text(
                '$firstName $lastName'.trim(),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentCard(BuildContext context, DashboardItem item) {
    final theme = Theme.of(context);
    final daysLeft = item.deadline.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;

    return GestureDetector(
      onTap: () => _navigateToItem(context, item),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUrgent
                ? [Colors.red.shade600, Colors.red.shade400]
                : [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isUrgent ? Colors.red : theme.primaryColor)
                  .withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isUrgent ? 'Срочно!' : 'Ближайший срок',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Осталось $daysLeft дн.',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy', 'ru_RU').format(item.deadline),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Icon(
                  item.type == 'PRACTICE'
                      ? Icons.assignment_outlined
                      : Icons.fact_check_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  item.type == 'PRACTICE' ? 'Практика' : 'Экзамен',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllClearCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 26),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Всё в порядке',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 2),
              Text('Нет ближайших дедлайнов',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, int practiceCount, int examCount) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context: context,
            icon: Icons.assignment_outlined,
            label: 'Практики',
            value: '$practiceCount',
            color: theme.primaryColor,
            onTap: () => widget.onTabSelected?.call(1),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            context: context,
            icon: Icons.fact_check_outlined,
            label: 'Экзамены',
            value: '$examCount',
            color: Colors.blue.shade600,
            onTap: () => widget.onTabSelected?.call(3),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onTap,
          child: const Text('Все →', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildItemList(BuildContext context, List<DashboardItem> items,
      {required bool isPractice}) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          isPractice ? 'Нет активных практик' : 'Нет активных экзаменов',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }

    return Column(
      children: items.take(3).map((item) {
        final daysLeft = item.deadline.difference(DateTime.now()).inDays;
        final isOverdue = daysLeft < 0;

        return GestureDetector(
          onTap: () => _navigateToItem(context, item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPractice ? Icons.assignment_outlined : Icons.fact_check_outlined,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isOverdue
                            ? 'Просрочено'
                            : 'До ${DateFormat('dd MMM', 'ru_RU').format(item.deadline)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue
                              ? Colors.red
                              : daysLeft <= 3
                                  ? Colors.orange
                                  : Colors.grey.shade500,
                          fontWeight:
                              (isOverdue || daysLeft <= 3) ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade400, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
