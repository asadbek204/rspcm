import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'practice_detail_screen.dart';

class PracticesListScreen extends StatefulWidget {
  const PracticesListScreen({super.key});

  @override
  State<PracticesListScreen> createState() => _PracticesListScreenState();
}

class _PracticesListScreenState extends State<PracticesListScreen> {
  final ApiService _api = ApiService();
  List<_ParticipationItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = ApiClient();
      final response = await client.get(ApiEndpoints.practiceParticipationsMe);
      final List raw = json.decode(response.body);
      final items = raw
          .cast<Map<String, dynamic>>()
          .where((item) => item['practice'] != null)
          .map((item) {
            final practice = Practice.fromJson(item['practice'] as Map<String, dynamic>);
            final participationId = item['participationId'] as int?;
            final status = item['status'] as String? ?? '';
            final submission = item['submission'] == null
                ? null
                : PracticeSubmission.fromJson(item['submission'] as Map<String, dynamic>);
            return _ParticipationItem(
              practice: practice,
              participationId: participationId,
              status: status,
              submission: submission,
            );
          })
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Нет активных практик',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Перейдите во вкладку «Экзамены»,\nоткройте экзамен и выберите вариант практики',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_downward,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Потяните вниз для обновления',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildCard(context, _items[index]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _ParticipationItem item) {
    final theme = Theme.of(context);
    final practice = item.practice;
    final daysLeft = practice.deadline.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;
    final submissionStatus = item.submission?.status;

    Color deadlineColor = isOverdue
        ? Colors.red
        : daysLeft <= 3
            ? Colors.orange
            : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PracticeDetailScreen(
              practice: practice,
              participationId: item.participationId,
            ),
          ),
        ).then((_) => _load()),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + submission status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      practice.workMode == 'TEAM'
                          ? Icons.group_outlined
                          : Icons.person_outlined,
                      color: theme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          practice.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (submissionStatus != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _submissionChip(submissionStatus),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Meta row
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: deadlineColor),
                  const SizedBox(width: 5),
                  Text(
                    isOverdue
                        ? 'Просрочено: ${DateFormat('dd MMM', 'ru_RU').format(practice.deadline)}'
                        : 'До ${DateFormat('dd MMM yyyy', 'ru_RU').format(practice.deadline)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: deadlineColor,
                        fontWeight: isOverdue || daysLeft <= 3
                            ? FontWeight.bold
                            : FontWeight.normal),
                  ),
                  const Spacer(),
                  if (practice.calendarRequired)
                    Row(
                      children: [
                        Icon(Icons.book_outlined, size: 14,
                            color: theme.primaryColor.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text('Дневник',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.primaryColor.withValues(alpha: 0.7))),
                      ],
                    ),
                ],
              ),

              // Days-left bar
              if (!isOverdue) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (daysLeft / 30).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.grey.withValues(alpha: 0.12),
                    color: deadlineColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _submissionChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'SUBMITTED':
        color = Colors.blue;
        label = 'На проверке';
        break;
      case 'GRADED':
        color = Colors.green;
        label = 'Проверено';
        break;
      case 'RETURNED':
        color = Colors.orange;
        label = 'На доработке';
        break;
      default:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _ParticipationItem {
  final Practice practice;
  final int? participationId;
  final String status;
  final PracticeSubmission? submission;

  _ParticipationItem({
    required this.practice,
    required this.participationId,
    required this.status,
    required this.submission,
  });
}
