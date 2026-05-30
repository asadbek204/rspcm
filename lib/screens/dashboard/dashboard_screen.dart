import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabSelected;
  const DashboardScreen({super.key, this.onTabSelected});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  StudentDashboardResponse? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated && auth.profile == null && !auth.isLoading) {
        auth.fetchProfile();
      }
    });
  }

  Future<void> _fetchDashboardData() async {
    final dashboardRes = await _apiService.getStudentDashboard();
    
    if (mounted) {
      setState(() {
        _dashboardData = dashboardRes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Determine nearest deadline
    DashboardItem? nearestDeadline;
    if (_dashboardData != null && _dashboardData!.practices.isNotEmpty) {
      nearestDeadline = _dashboardData!.practices.first; // Assuming backend sorts by deadline
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context, authProvider),
            const SizedBox(height: 30),
            if (nearestDeadline != null)
              GestureDetector(
                onTap: () => widget.onTabSelected?.call(2),
                child: _buildNearestDeadline(context, nearestDeadline)
              )
            else
              _buildNoDeadlineCard(context),
            const SizedBox(height: 30),
            _buildCalendarSummary(context),
            const SizedBox(height: 30),
            _buildRecentPractices(context, _dashboardData?.exams ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    final theme = Theme.of(context);
    final profile = auth.profile;
    final bool isProfileLoading = auth.isLoading && profile == null;
    final String firstName = profile?.firstName ?? (isProfileLoading ? '...' : 'Student');
    final String lastName = profile?.lastName ?? '';
    
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
          child: Text(
            firstName.isNotEmpty && firstName != '...' ? firstName.substring(0, 1).toUpperCase() : 'S',
            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'С возвращением,',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            Text(
              '$firstName $lastName',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNearestDeadline(BuildContext context, DashboardItem practice) {
    final theme = Theme.of(context);
    final daysLeft = practice.deadline.difference(DateTime.now()).inDays;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ближайший срок',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  daysLeft >= 0 ? 'Осталось $daysLeft дн.' : 'Просрочено',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            practice.title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              Text(
                DateFormat('MMM dd, yyyy').format(practice.deadline),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDeadlineCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
          SizedBox(height: 10),
          Text('Нет ближайших сроков', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Вы всё успеваете!', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCalendarSummary(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ваша активность',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => widget.onTabSelected?.call(1),
              child: const Text('Показать все'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.week,
            headerVisible: false,
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPractices(BuildContext context, List<DashboardItem> items) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Текущие экзамены',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        if (items.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Активных экзаменов нет', style: TextStyle(color: Colors.grey)),
          ))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final practice = items[index];
              return GestureDetector(
                onTap: () => widget.onTabSelected?.call(2),
                child: Container(
                  padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(Icons.assignment, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            practice.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Срок: ${DateFormat('dd MMM', 'ru_RU').format(practice.deadline)}',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                ),
              );
            },
          ),
      ],
    );
  }
}
