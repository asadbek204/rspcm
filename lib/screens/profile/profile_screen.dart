import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;

    if (authProvider.isLoading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => authProvider.fetchProfile(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileCard(context, profile),
          const SizedBox(height: 30),
          _buildInfoSection(theme, profile),
          const SizedBox(height: 30),
          Text(
            'Display Theme',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 1.1,
            children: [
              _buildThemeOption(context, AppThemeType.darkGold, 'Dark Gold', Colors.black, const Color(0xFFFFB300)),
              _buildThemeOption(context, AppThemeType.darkEmerald, 'Dark Emerald', Colors.black, const Color(0xFF2ECC71)),
              _buildThemeOption(context, AppThemeType.softLatte, 'Soft Latte', const Color(0xFFFFF8F3), const Color(0xFF795548)),
              _buildThemeOption(context, AppThemeType.softZinc, 'Soft Zinc', const Color(0xFFF9F9F9), const Color(0xFF18181B)),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, StudentProfileResponse? profile) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              (profile != null && profile.firstName.isNotEmpty) 
                  ? profile.firstName.substring(0, 1).toUpperCase() 
                  : 'S',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            '${profile?.firstName ?? 'Student'} ${profile?.lastName ?? ''}',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            profile?.studentNumber ?? 'No Student ID',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEditProfileDialog(context, profile),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, StudentProfileResponse? profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, 'Email', profile?.email ?? 'N/A', theme),
          const Divider(height: 30),
          _buildInfoRow(Icons.phone_outlined, 'Phone', profile?.phoneNumber ?? 'N/A', theme),
          const Divider(height: 30),
          _buildInfoRow(Icons.school_outlined, 'Course', '${profile?.course ?? 0} Year', theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: 20),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  void _showEditProfileDialog(BuildContext context, StudentProfileResponse? profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
              controller: TextEditingController(text: profile?.phoneNumber),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: 'Notes'),
              controller: TextEditingController(text: profile?.notes),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, AppThemeType type, String name, Color bg, Color iconColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSelected = themeProvider.themeType == type;

    return GestureDetector(
      onTap: () => themeProvider.setTheme(type),
      child: Container(
        decoration: BoxDecoration(
          color: themeProvider.themeData.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeProvider.themeData.primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Container(
                  width: 30,
                  height: 5,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(name, style: TextStyle(
              color: themeProvider.themeData.textTheme.bodyMedium?.color, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
            )),
          ],
        ),
      ),
    );
  }
}
