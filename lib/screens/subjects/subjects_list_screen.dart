import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class SubjectsListScreen extends StatefulWidget {
  const SubjectsListScreen({super.key});

  @override
  State<SubjectsListScreen> createState() => _SubjectsListScreenState();
}

class _SubjectsListScreenState extends State<SubjectsListScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<SubjectItem> _subjects = [];

  static const List<List<Color>> _gradients = [
    [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
    [Color(0xFF00BCD4), Color(0xFF26C6DA)],
    [Color(0xFF43A047), Color(0xFF66BB6A)],
    [Color(0xFFE91E63), Color(0xFFF06292)],
    [Color(0xFFFF9800), Color(0xFFFFB74D)],
    [Color(0xFF5C6BC0), Color(0xFF7986CB)],
    [Color(0xFF00897B), Color(0xFF26A69A)],
    [Color(0xFFD81B60), Color(0xFFEC407A)],
  ];

  static const List<IconData> _icons = [
    Icons.menu_book_rounded,
    Icons.science_rounded,
    Icons.calculate_rounded,
    Icons.history_edu_rounded,
    Icons.language_rounded,
    Icons.code_rounded,
    Icons.psychology_rounded,
    Icons.biotech_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getSubjects(size: 50);
    if (!mounted) return;
    setState(() {
      _subjects = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Предметы'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _subjects.isEmpty
                  ? _buildEmpty()
                  : _buildGrid(),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Предметы не найдены',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: _subjects.length,
      itemBuilder: (context, index) {
        final subject = _subjects[index];
        final gradientColors = _gradients[index % _gradients.length];
        final icon = _icons[index % _icons.length];
        return _SubjectCard(
          subject: subject,
          gradientColors: gradientColors,
          icon: icon,
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectItem subject;
  final List<Color> gradientColors;
  final IconData icon;

  const _SubjectCard({
    required this.subject,
    required this.gradientColors,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 38),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subject.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        subject.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: gradientColors[0].withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Предмет',
                      style: TextStyle(
                        fontSize: 10,
                        color: gradientColors[0],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
