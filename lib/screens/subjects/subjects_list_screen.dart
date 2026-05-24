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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _apiService.getSubjects();
    if (!mounted) return;
    setState(() {
      _subjects = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _subjects.isEmpty
                  ? const Center(child: Text('No subjects found'))
                  : ListView.separated(
                      itemCount: _subjects.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        return ListTile(
                          title: Text(subject.name),
                          subtitle: subject.description.isEmpty ? null : Text(subject.description),
                        );
                      },
                    ),
            ),
    );
  }
}
