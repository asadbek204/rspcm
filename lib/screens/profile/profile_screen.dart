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
    final teacherProfile = authProvider.teacherProfile;
    final l = AppLocalizations.of(context);
    final hasProfile = authProvider.isTeacher ? teacherProfile != null : profile != null;

    if (authProvider.isLoading && !hasProfile) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!hasProfile) {
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildProfileCard(context, profile, l),
          const SizedBox(height: 24),
          _buildInfoSection(theme, profile, l),
          const SizedBox(height: 24),
          Text(
            l.profileTheme,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildThemeOption(context, AppThemeType.darkGold, l.profileThemeDarkGold, Colors.black, const Color(0xFFFFB300)),
              _buildThemeOption(context, AppThemeType.darkEmerald, l.profileThemeDarkEmerald, Colors.black, const Color(0xFF2ECC71)),
              _buildThemeOption(context, AppThemeType.softLatte, l.profileThemeLatte, const Color(0xFFFFF8F3), const Color(0xFF795548)),
              _buildThemeOption(context, AppThemeType.softZinc, l.profileThemeZinc, const Color(0xFFF9F9F9), const Color(0xFF18181B)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l.profileLanguage,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildLanguageSwitcher(context),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context, l),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(l.profileLogout, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        const SizedBox(width: 12),
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
          borderRadius: BorderRadius.circular(14),
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

  Widget _buildProfileCard(BuildContext context, StudentProfileResponse? profile, AppLocalizations l) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firstName = authProvider.isTeacher
        ? (authProvider.teacherProfile?.firstName ?? '')
        : (profile?.firstName ?? '');
    final lastName = authProvider.isTeacher
        ? (authProvider.teacherProfile?.lastName ?? '')
        : (profile?.lastName ?? '');
    final subtitle = authProvider.isTeacher
        ? (authProvider.teacherProfile?.academicDegree ?? '')
        : (profile?.studentNumber.isNotEmpty == true ? profile!.studentNumber : '');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : '?',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$firstName $lastName',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: theme.hintColor, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditProfileSheet(context, profile, l),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l.profileEdit),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showChangePasswordDialog(context, l),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.lock_outline_rounded, size: 16),
                  label: Text(l.profileChangePassword),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, StudentProfileResponse? profile, AppLocalizations l) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = authProvider.isTeacher
        ? (authProvider.teacherProfile?.email ?? '')
        : (profile?.email ?? '');
    final phone = authProvider.isTeacher ? '' : (profile?.phoneNumber ?? '');

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildInfoTile(Icons.email_outlined, l.profileEmail,
              email.isNotEmpty ? email : l.profileNA, theme),
          if (!authProvider.isTeacher) ...[
            _buildDivider(theme),
            _buildInfoTile(Icons.phone_outlined, l.profilePhone,
                phone.isNotEmpty ? phone : l.profileNA, theme),
            _buildDivider(theme),
            _buildInfoTile(Icons.school_outlined, l.profileCourse,
                '${profile?.course ?? 0}${l.profileCourseSuffix}', theme),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
  );

  Widget _buildInfoTile(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: theme.hintColor, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, StudentProfileResponse? profile, AppLocalizations l) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isTeacher = authProvider.isTeacher;

    final firstNameCtrl = TextEditingController(
        text: isTeacher ? authProvider.teacherProfile?.firstName : profile?.firstName);
    final lastNameCtrl = TextEditingController(
        text: isTeacher ? authProvider.teacherProfile?.lastName : profile?.lastName);
    final emailCtrl = TextEditingController(
        text: isTeacher ? authProvider.teacherProfile?.email : profile?.email);
    DateTime? selectedBirthDate =
        isTeacher ? authProvider.teacherProfile?.birthDate : profile?.birthDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final theme = Theme.of(ctx);
          final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 8, bottom: bottomPadding + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  l.profileEditTitle,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _sheetField(
                        controller: firstNameCtrl,
                        label: l.profileFirstName,
                        icon: Icons.person_outline,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sheetField(
                        controller: lastNameCtrl,
                        label: l.profileLastName,
                        icon: Icons.badge_outlined,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sheetField(
                  controller: emailCtrl,
                  label: l.profileEmail,
                  icon: Icons.email_outlined,
                  theme: theme,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                // Birth date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedBirthDate ?? DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setSheetState(() => selectedBirthDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: theme.primaryColor, size: 18),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.profileBirthDate,
                                style: TextStyle(color: theme.hintColor, fontSize: 11, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(
                              selectedBirthDate != null
                                  ? '${selectedBirthDate!.day.toString().padLeft(2, '0')}.${selectedBirthDate!.month.toString().padLeft(2, '0')}.${selectedBirthDate!.year}'
                                  : l.profileSelectDate,
                              style: TextStyle(
                                color: selectedBirthDate != null
                                    ? theme.textTheme.bodyMedium?.color
                                    : theme.hintColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: theme.hintColor, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final firstName = firstNameCtrl.text.trim().isEmpty ? null : firstNameCtrl.text.trim();
                          final lastName = lastNameCtrl.text.trim().isEmpty ? null : lastNameCtrl.text.trim();
                          final email = emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim();

                          bool updated;
                          if (isTeacher) {
                            updated = await authProvider.updateTeacherProfile(
                              firstName: firstName,
                              lastName: lastName,
                              email: email,
                              birthDate: selectedBirthDate,
                            );
                          } else {
                            updated = await authProvider.updateProfile(
                              firstName: firstName,
                              lastName: lastName,
                              email: email,
                              birthDate: selectedBirthDate,
                            );
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(updated ? l.profileUpdateSuccess : l.profileUpdateError)),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l.save, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      firstNameCtrl.dispose();
      lastNameCtrl.dispose();
      emailCtrl.dispose();
    });
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: theme.primaryColor, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(color: theme.hintColor, fontSize: 13),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppLocalizations l) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isTeacher = authProvider.isTeacher;
    final currentPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(
        l: l,
        currentPwdCtrl: currentPwdCtrl,
        newPwdCtrl: newPwdCtrl,
        confirmPwdCtrl: confirmPwdCtrl,
        onSave: (current, newPwd, confirm) async {
          if (newPwd != confirm) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.profilePasswordMismatch)),
            );
            return;
          }
          if (current.isEmpty || newPwd.isEmpty) return;

          bool updated;
          if (isTeacher) {
            updated = await authProvider.updateTeacherProfile(
              currentPassword: current,
              newPassword: newPwd,
            );
          } else {
            updated = await authProvider.updateProfile(
              currentPassword: current,
              newPassword: newPwd,
            );
          }

          if (ctx.mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(updated ? l.profilePasswordSuccess : l.profilePasswordError)),
            );
          }
        },
      ),
    ).then((_) {
      currentPwdCtrl.dispose();
      newPwdCtrl.dispose();
      confirmPwdCtrl.dispose();
    });
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.profileLogoutTitle),
        content: Text(l.profileLogoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
          borderRadius: BorderRadius.circular(18),
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
            Text(
              name,
              style: TextStyle(
                color: themeProvider.themeData.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(Icons.check_circle_rounded,
                  color: themeProvider.themeData.primaryColor, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Separate stateful widget so obscure-toggle state persists.
// ─────────────────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final AppLocalizations l;
  final TextEditingController currentPwdCtrl;
  final TextEditingController newPwdCtrl;
  final TextEditingController confirmPwdCtrl;
  final Future<void> Function(String current, String newPwd, String confirm) onSave;

  const _ChangePasswordDialog({
    required this.l,
    required this.currentPwdCtrl,
    required this.newPwdCtrl,
    required this.confirmPwdCtrl,
    required this.onSave,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = widget.l;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: theme.primaryColor, size: 22),
          const SizedBox(width: 10),
          Text(l.profileChangePasswordTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pwdField(widget.currentPwdCtrl, l.profileCurrentPassword, _obscureCurrent,
              () => setState(() => _obscureCurrent = !_obscureCurrent), theme),
          const SizedBox(height: 14),
          _pwdField(widget.newPwdCtrl, l.profileNewPassword, _obscureNew,
              () => setState(() => _obscureNew = !_obscureNew), theme),
          const SizedBox(height: 14),
          _pwdField(widget.confirmPwdCtrl, l.profileConfirmNewPassword, _obscureConfirm,
              () => setState(() => _obscureConfirm = !_obscureConfirm), theme),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        ElevatedButton(
          onPressed: () => widget.onSave(
            widget.currentPwdCtrl.text,
            widget.newPwdCtrl.text,
            widget.confirmPwdCtrl.text,
          ),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(l.save, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _pwdField(TextEditingController ctrl, String label, bool obscure,
      VoidCallback onToggle, ThemeData theme) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor, size: 18),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
          onPressed: onToggle,
          color: theme.hintColor,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(fontSize: 13, color: theme.hintColor),
      ),
    );
  }
}
