import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'practice_detail_screen.dart';
import 'package:intl/intl.dart';

class PracticesListScreen extends StatefulWidget {
  const PracticesListScreen({super.key});

  @override
  State<PracticesListScreen> createState() => _PracticesListScreenState();
}

class _PracticesListScreenState extends State<PracticesListScreen> {
  final ApiService _apiService = ApiService();
  List<Practice> _practices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPractices();
  }

  Future<void> _fetchPractices() async {
    final data = await _apiService.getPractices();
    if (mounted) {
      setState(() {
        _practices = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_practices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No practices found', style: TextStyle(color: Colors.grey, fontSize: 18)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetchPractices, child: const Text('Refresh')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPractices,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _practices.length,
        itemBuilder: (context, index) {
          final practice = _practices[index];
          return _buildPracticeCard(context, practice);
        },
      ),
    );
  }

  Widget _buildPracticeCard(BuildContext context, Practice practice) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PracticeDetailScreen(practice: practice)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      practice.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusChip(
                    practice.deadline.isAfter(DateTime.now()) ? 'Active' : 'Expired', 
                    theme
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Icon(Icons.calendar_month, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 5),
                  Text(
                    'Deadline: ${DateFormat('dd MMM yyyy').format(practice.deadline)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        practice.workMode == 'TEAM' ? Icons.group : Icons.person,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        practice.workMode,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color color = theme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
