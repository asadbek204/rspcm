import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.profile == null && !authProvider.isLoading) {
        authProvider.fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;
    final l = AppLocalizations.of(context);

    if (authProvider.isLoading && profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.profileLoadError),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => authProvider.fetchProfile(),
                child: Text(l.profileRetry),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => authProvider.fetchProfile(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileCard(context, profile, l),
          const SizedBox(height: 30),
          _buildInfoSection(theme, profile, l),
          const SizedBox(height: 30),
          Text(
            l.profileTheme,
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
              _buildThemeOption(context, AppThemeType.darkGold, l.profileThemeDarkGold, Colors.black, const Color(0xFFFFB300)),
              _buildThemeOption(context, AppThemeType.darkEmerald, l.profileThemeDarkEmerald, Colors.black, const Color(0xFF2ECC71)),
              _buildThemeOption(context, AppThemeType.softLatte, l.profileThemeLatte, const Color(0xFFFFF8F3), const Color(0xFF795548)),
              _buildThemeOption(context, AppThemeType.softZinc, l.profileThemeZinc, const Color(0xFFF9F9F9), const Color(0xFF18181B)),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            l.profileLanguage,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildLanguageSwitcher(context),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context, l),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
              ),
              child: Text(l.profileLogout, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher(BuildContext context) {
    final theme = Theme.of(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final current = langProvider.languageCode;

    return Row(
      children: [
        Expanded(child: _buildLangButton(context, theme, 'ru', 'Русский', current)),
        const SizedBox(width: 15),
        Expanded(child: _buildLangButton(context, theme, 'uz', "O'zbek", current)),
      ],
    );
  }

  Widget _buildLangButton(BuildContext context, ThemeData theme, String code, String label, String current) {
    final isSelected = current == code;
    return GestureDetector(
      onTap: () => Provider.of<LanguageProvider>(context, listen: false).setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.primaryColor : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, StudentProfileResponse profile, AppLocalizations l) {
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
              profile.firstName.isNotEmpty
                  ? profile.firstName.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            '${profile.firstName} ${profile.lastName}',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            profile.studentNumber.isNotEmpty ? profile.studentNumber : 'No Student ID',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEditProfileDialog(context, profile, l),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l.profileEdit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, StudentProfileResponse profile, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, l.profileEmail,
              profile.email.isNotEmpty ? profile.email : l.profileNA, theme),
          const Divider(height: 30),
          _buildInfoRow(Icons.phone_outlined, l.profilePhone,
              profile.phoneNumber.isNotEmpty ? profile.phoneNumber : l.profileNA, theme),
          const Divider(height: 30),
          _buildInfoRow(Icons.school_outlined, l.profileCourse,
              '${profile.course}${l.profileCourseSuffix}', theme),
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

  void _showEditProfileDialog(BuildContext context, StudentProfileResponse? profile, AppLocalizations l) {
    int selectedCourse = profile?.course != null && profile!.course > 0 ? profile.course : 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.profileEditTitle),
        content: StatefulBuilder(
          builder: (context, setDialogState) => DropdownButtonFormField<int>(
            initialValue: selectedCourse,
            decoration: InputDecoration(labelText: l.profileCourseLabel),
            items: List.generate(
              8,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                child: Text('${index + 1}${l.profileCourseSuffix}'),
              ),
            ),
            onChanged: (value) {
              if (value != null) setDialogState(() => selectedCourse = value);
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final updated = await authProvider.updateProfile(course: selectedCourse);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(updated ? l.profileUpdateSuccess : l.profileUpdateError)),
                );
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.profileLogoutTitle),
        content: Text(l.profileLogoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(l.profileLogout),
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
                  decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(name, style: TextStyle(
              color: themeProvider.themeData.textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}
