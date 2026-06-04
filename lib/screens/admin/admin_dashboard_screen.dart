import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;

  AdminDashboardStats? _stats;
  List<AdminRecentReport> _reports = [];
  List<AdminGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.getAdminDashboardStats(),
      _api.getAdminRecentReports(size: 5),
      _api.getAdminGroups(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = results[0] as AdminDashboardStats?;
      _reports = results[1] as List<AdminRecentReport>;
      _groups = results[2] as List<AdminGroup>;
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
                // ── Header ─────────────────────────────────────────────────
                _buildHeader(theme, auth),
                const SizedBox(height: 20),

                // ── Stats ──────────────────────────────────────────────────
                if (_stats != null) ...[
                  _buildStatsRow(theme, _stats!),
                  const SizedBox(height: 12),
                  if (_stats!.pendingReports > 0)
                    _buildPendingBanner(theme, _stats!.pendingReports),
                  const SizedBox(height: 8),
                ],

                // ── Recent reports ─────────────────────────────────────────
                _DashSectionHeader(
                  title: 'Последние сдачи',
                  icon: Icons.history_edu_outlined,
                ),
                const SizedBox(height: 10),
                if (_reports.isEmpty)
                  _EmptyHint(text: 'Нет последних сдач')
                else
                  ..._reports.map((r) => _ReportRow(report: r)),

                const SizedBox(height: 20),

                // ── Groups ─────────────────────────────────────────────────
                _DashSectionHeader(
                  title: 'Учебные группы',
                  icon: Icons.group_outlined,
                ),
                const SizedBox(height: 10),
                if (_groups.isEmpty)
                  _EmptyHint(text: 'Группы не назначены')
                else
                  ..._groups.take(5).map((g) => _AdminGroupRow(group: g)),
              ],
            ),
    );
  }

  Widget _buildHeader(ThemeData theme, AuthProvider auth) {
    final name = auth.displayName.isNotEmpty ? auth.displayName : 'Администратор';
    final initial = name[0].toUpperCase();
    return Container(
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
                const Text(
                  'Панель администратора',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, AdminDashboardStats s) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.people_outline,
          label: 'Студенты',
          value: s.totalStudents.toString(),
          color: theme.primaryColor,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.pending_actions_outlined,
          label: 'На проверке',
          value: s.pendingReports.toString(),
          color: Colors.orange,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.group_outlined,
          label: 'Группы',
          value: s.totalStudyGroups.toString(),
          color: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildPendingBanner(ThemeData theme, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
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
                  '$count работ ожидает проверки',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Требуется действие преподавателей',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
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
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DashSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _DashSectionHeader({required this.title, required this.icon});

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
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final AdminRecentReport report;
  const _ReportRow({required this.report});

  (Color, String) get _statusInfo {
    switch (report.status) {
      case 'SUBMITTED':
        return (Colors.blue.shade600, 'На проверке');
      case 'GRADED':
        return (Colors.green.shade600, 'Принято');
      case 'RETURNED':
        return (Colors.orange.shade700, 'Возвращено');
      default:
        return (Colors.grey.shade500, report.status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd.MM HH:mm', 'ru_RU');
    final (statusColor, statusLabel) = _statusInfo;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.assignment_outlined, size: 20, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.examTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  report.studentName.isNotEmpty
                      ? report.studentName
                      : report.studentEmail,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(fmt.format(report.submittedAt.toLocal()),
                  style:
                      TextStyle(color: Colors.grey[400], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminGroupRow extends StatelessWidget {
  final AdminGroup group;
  const _AdminGroupRow({required this.group});

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
                  '${group.studentCount} студентов · ${group.language}',
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
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
