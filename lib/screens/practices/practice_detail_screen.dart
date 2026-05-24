import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class PracticeDetailScreen extends StatefulWidget {
  final Practice practice;
  const PracticeDetailScreen({super.key, required this.practice});

  @override
  State<PracticeDetailScreen> createState() => _PracticeDetailScreenState();
}

class _PracticeDetailScreenState extends State<PracticeDetailScreen> {
  final ApiService _apiService = ApiService();
  PracticeTeamResponse? _teamData;
  bool _isLoadingTeam = false;
  String? _uploadedFileName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.practice.workMode == 'TEAM') {
      _fetchTeamData();
    }
  }

  Future<void> _fetchTeamData() async {
    setState(() => _isLoadingTeam = true);
    final data = await _apiService.getTeamByPractice(widget.practice.id);
    if (mounted) {
      setState(() {
        _teamData = data;
        _isLoadingTeam = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles();
    if (result != null) {
      setState(() {
        _uploadedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_uploadedFileName == null) return;
    
    setState(() => _isSubmitting = true);
    // Note: In a real app, you'd upload the file to a storage service first and get a URL/Path
    // Here we're simulating the link between the practice and a journal entry for the submission
    final success = await _apiService.createJournal(
      widget.practice.id, 
      'Final submission: $_uploadedFileName',
      teamId: _teamData?.id,
      filePath: _uploadedFileName, // Simplified
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission successful!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission failed. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Details')),
      body: RefreshIndicator(
        onRefresh: widget.practice.workMode == 'TEAM' ? _fetchTeamData : () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildInfoCard(theme),
              const SizedBox(height: 30),
              if (widget.practice.workMode == 'TEAM') ...[
                _buildTeamSection(theme),
                const SizedBox(height: 30),
              ],
              _buildUploadSection(theme),
              const SizedBox(height: 30),
              _buildTestSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.practice.title,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (widget.practice.resourceUrl != null)
                IconButton(
                  icon: Icon(Icons.open_in_new, color: theme.primaryColor),
                  onPressed: () => launchUrl(Uri.parse(widget.practice.resourceUrl!)),
                  tooltip: 'Open Resource',
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.practice.description.isNotEmpty 
                ? widget.practice.description 
                : 'No description provided.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (widget.practice.requirements != null && widget.practice.requirements!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 5),
            Text(widget.practice.requirements!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Deadline', DateFormat('dd MMM, yyyy').format(widget.practice.deadline), theme),
              _buildDetailItem('Work Mode', widget.practice.workMode, theme),
              _buildDetailItem('Team Size', '${widget.practice.teamSize}', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTeamSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _teamData != null ? 'Team: ${_teamData!.name}' : 'Team Members', 
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            ),
            if (_teamData == null && !_isLoadingTeam)
              TextButton.icon(
                onPressed: () => _showInviteDialog(context),
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Create Team'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoadingTeam)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_teamData == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: const Center(child: Text('You are not in a team for this practice yet.', style: TextStyle(color: Colors.grey))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _teamData!.members.length,
            itemBuilder: (context, index) {
              final member = _teamData!.members[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Text(member.firstName.length > 0 ? member.firstName.substring(0, 1) : '?', style: TextStyle(color: theme.primaryColor)),
                ),
                title: Text('${member.firstName} ${member.lastName}'),
                subtitle: Text(member.email),
              );
            },
          ),
      ],
    );
  }

  Widget _buildUploadSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Submit Results', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              if (_uploadedFileName == null) ...[
                Icon(Icons.cloud_upload_outlined, size: 48, color: theme.primaryColor),
                const SizedBox(height: 10),
                const Text('Upload your practice files'),
                const SizedBox(height: 15),
                ElevatedButton(onPressed: _pickFile, child: const Text('Browse Files')),
              ] else ...[
                const Icon(Icons.insert_drive_file, size: 48, color: Colors.green),
                const SizedBox(height: 10),
                Text(_uploadedFileName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(onPressed: _isSubmitting ? null : _pickFile, child: const Text('Change')),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit, 
                      child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit')
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.quiz_outlined, color: Colors.orange),
              SizedBox(width: 10),
              Text('Assessment Required', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Some practices require a mandatory test after completion.'),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, // Navigate to Assignment screen in future
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: const Text('View Assessments'),
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final nameController = TextEditingController();
    final membersController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Practice Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Team Name')),
            const SizedBox(height: 10),
            TextField(controller: membersController, decoration: const InputDecoration(labelText: 'Member IDs (comma separated)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final memberIds = membersController.text.split(',').map((e) => int.tryParse(e.trim()) ?? 0).where((e) => e != 0).toList();
              final success = await _apiService.createTeam(widget.practice.id, nameController.text, memberIds);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  _fetchTeamData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team created!')));
                }
              }
            }, 
            child: const Text('Create')
          ),
        ],
      ),
    );
  }
}
