import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  List<Practice> _practices = [];
  List<PracticeJournal> _journals = [];
  final Map<DateTime, List<String>> _events = {};

  // practiceId → set of dates (day-only) with a journal entry
  final Map<int, Set<DateTime>> _writtenDays = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final practices = await _apiService.getPractices();
    final journals = await _apiService.getMyJournals();

    if (mounted) {
      setState(() {
        _practices = practices;
        _journals = journals;
        _buildEventMap();
        _buildWrittenDays();
        _isLoading = false;
      });
    }
  }

  void _buildEventMap() {
    _events.clear();
    for (var p in _practices) {
      final date = DateTime(p.deadline.year, p.deadline.month, p.deadline.day);
      _events.update(
        date,
        (list) => list..add('Срок: ${p.title}'),
        ifAbsent: () => ['Срок: ${p.title}'],
      );
    }
    for (var j in _journals) {
      final date = DateTime(j.submittedAt.year, j.submittedAt.month, j.submittedAt.day);
      _events.update(
        date,
        (list) => list..add('Записано: ${j.content}'),
        ifAbsent: () => ['Записано: ${j.content}'],
      );
    }
  }

  void _buildWrittenDays() {
    _writtenDays.clear();
    for (final j in _journals) {
      final day = DateTime(j.submittedAt.year, j.submittedAt.month, j.submittedAt.day);
      _writtenDays.putIfAbsent(j.practiceId, () => {}).add(day);
    }
  }

  /// Returns missed days in focused month for each calendarRequired practice.
  /// A day is "missed" if it's a past day in the current month (not today),
  /// within the practice deadline, and has no journal entry.
  Map<Practice, List<DateTime>> _computeMissedDays() {
    final result = <Practice, List<DateTime>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    // Last day to check: yesterday (today isn't over) or end of month
    final lastDay = DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0, // last day of focused month
    );
    final checkUntil = today.isBefore(lastDay) ? today.subtract(const Duration(days: 1)) : lastDay;

    if (checkUntil.isBefore(monthStart)) return result;

    final calPractices = _practices.where((p) => p.calendarRequired).toList();
    if (calPractices.isEmpty) return result;

    for (final p in calPractices) {
      final deadline = DateTime(p.deadline.year, p.deadline.month, p.deadline.day);
      // Only check days within the practice deadline
      final rangeEnd = deadline.isBefore(checkUntil) ? deadline : checkUntil;
      if (rangeEnd.isBefore(monthStart)) continue;

      final written = _writtenDays[p.id] ?? {};
      final missed = <DateTime>[];

      var day = monthStart;
      while (!day.isAfter(rangeEnd)) {
        if (!written.contains(day)) {
          missed.add(day);
        }
        day = day.add(const Duration(days: 1));
      }

      if (missed.isNotEmpty) result[p] = missed;
    }
    return result;
  }

  List<String> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final missedDays = _computeMissedDays();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildCalendar(theme),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Events for selected day ──
                _buildEventList(theme),

                // ── Missed journal days ──
                if (missedDays.isNotEmpty) ...[
                  const Divider(height: 1),
                  _buildMissedDaysSection(theme, missedDays),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return TableCalendar(
      locale: 'ru_RU',
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() => _calendarFormat = format);
      },
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
      },
      eventLoader: _getEventsForDay,
      daysOfWeekHeight: 24,
      calendarBuilders: CalendarBuilders(
        // Highlight missed days in red
        defaultBuilder: (context, day, focusedDay) {
          final d = DateTime(day.year, day.month, day.day);
          final today = DateTime.now();
          final todayNorm = DateTime(today.year, today.month, today.day);
          if (d.isBefore(todayNorm)) {
            for (final entry in _computeMissedDays().entries) {
              if (entry.value.contains(d)) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                );
              }
            }
          }
          return null;
        },
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
        selectedDecoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonDecoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        formatButtonTextStyle: TextStyle(color: theme.primaryColor),
      ),
    );
  }

  Widget _buildEventList(ThemeData theme) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <String>[];

    if (selectedEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
              const SizedBox(height: 8),
              const Text('На этот день нет задач или сроков',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: selectedEvents.map((event) {
          final isDeadline = event.startsWith('Срок:');
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDeadline ? theme.primaryColor.withValues(alpha: 0.1) : theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDeadline ? theme.primaryColor : Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  isDeadline ? Icons.flag_outlined : Icons.check_circle_outline,
                  color: isDeadline ? theme.primaryColor : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(event,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isDeadline ? FontWeight.bold : FontWeight.normal)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMissedDaysSection(ThemeData theme, Map<Practice, List<DateTime>> missed) {
    final fmt = DateFormat('d MMM', 'ru_RU');
    final totalMissed = missed.values.fold(0, (s, l) => s + l.length);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Пропущенные записи дневника',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalMissed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'В эти дни не была сделана запись в дневнике практики',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),
          ...missed.entries.map((entry) {
            final practice = entry.key;
            final days = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.book_outlined, size: 15, color: Colors.red.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          practice.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      Text(
                        '${days.length} ${_dayWord(days.length)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: days.map((day) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        fmt.format(day),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _dayWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'дня';
    return 'дней';
  }

  void _showAddTaskDialog(BuildContext context) {
    if (_practices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет активных практик для записи задачи.')));
      return;
    }

    final controller = TextEditingController();
    int selectedPracticeId = _practices.first.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Добавить запись в дневник'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedPracticeId,
                items: _practices
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.title)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedPracticeId = val);
                },
                decoration: const InputDecoration(labelText: 'Выберите практику'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Над чем вы работали сегодня?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final success =
                      await _apiService.createJournal(selectedPracticeId, controller.text);
                  if (success) {
                    _fetchData();
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
