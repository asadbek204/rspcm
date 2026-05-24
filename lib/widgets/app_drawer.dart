import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../screens/chat/chats_list_screen.dart';
import '../screens/chat/groups_list_screen.dart';
import '../screens/subjects/subjects_list_screen.dart';
import '../screens/exams/exams_list_screen.dart';

class AppDrawer extends StatefulWidget {
  final Function(int) onTabSelected;
  const AppDrawer({super.key, required this.onTabSelected});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Profile is now managed by AuthProvider

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<AuthProvider>(context).profile;
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, profile),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.group_outlined,
                  title: 'Groups',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsListScreen())),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Chats',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatsListScreen())),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assignment_outlined,
                  title: 'Practices',
                  onTap: () {
                    Navigator.pop(context);
                    widget.onTabSelected(2);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.menu_book_outlined,
                  title: 'Subjects',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubjectsListScreen()),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.fact_check_outlined,
                  title: 'Exams',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExamsListScreen()),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildLogoutButton(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StudentProfileResponse? profile) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              (profile != null && profile.firstName.isNotEmpty) 
                  ? profile.firstName.substring(0, 1).toUpperCase() 
                  : 'S',
              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile != null ? '${profile.firstName} ${profile.lastName}' : 'Loading...',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profile?.studentNumber ?? 'Student ID: Fetching...',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      title: Text(title, style: theme.textTheme.bodyLarge),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title: const Text(
        'Logout',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
      onTap: () {
        Navigator.pop(context);
        Provider.of<AuthProvider>(context, listen: false).logout();
      },
    );
  }
}
