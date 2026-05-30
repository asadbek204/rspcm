import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
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
        _isLoading = false;
      });
    }
  }

  void _buildEventMap() {
    _events.clear();
    
    // Add Practice Deadlines
    for (var p in _practices) {
      final date = DateTime(p.deadline.year, p.deadline.month, p.deadline.day);
      _events.update(
        date,
        (list) => list..add('Срок: ${p.title}'),
        ifAbsent: () => ['Срок: ${p.title}'],
      );
    }

    // Add Journals
    for (var j in _journals) {
      final date = DateTime(j.submittedAt.year, j.submittedAt.month, j.submittedAt.day);
      _events.update(
        date,
        (list) => list..add('Записано: ${j.content}'),
        ifAbsent: () => ['Записано: ${j.content}'],
      );
    }
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

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildCalendar(theme),
          const Divider(),
          Expanded(
            child: _buildEventList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return TableCalendar(
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
        setState(() {
          _calendarFormat = format;
        });
      },
      eventLoader: _getEventsForDay,
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
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];
    
    if (selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            const Text('На этот день нет задач или сроков', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        final event = selectedEvents[index];
        final isDeadline = event.startsWith('Срок:');
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isDeadline ? theme.primaryColor.withValues(alpha: 0.1) : theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isDeadline ? theme.primaryColor : Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(
                isDeadline ? Icons.error_outline : Icons.check_circle_outline,
                color: isDeadline ? theme.primaryColor : Colors.green,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  event,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isDeadline ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    if (_practices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет активных практик для записи задачи.')));
      return;
    }

    final controller = TextEditingController();
    int selectedPracticeId = _practices.first.id;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Добавить задачу на день'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedPracticeId,
                items: _practices.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title))).toList(),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final success = await _apiService.createJournal(selectedPracticeId, controller.text);
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
