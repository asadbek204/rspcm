import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final profile = auth.teacherProfile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── Avatar + name ────────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  profile != null && profile.firstName.isNotEmpty
                      ? profile.firstName[0].toUpperCase()
                      : 'П',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                profile != null
                    ? '${profile.firstName} ${profile.lastName}'.trim()
                    : '—',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Преподаватель',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Info card ────────────────────────────────────────────────────────
        _SectionCard(
          children: [
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile?.email ?? '—',
            ),
            if (profile != null && profile.academicDegree.isNotEmpty)
              _InfoRow(
                icon: Icons.school_outlined,
                label: 'Учёная степень',
                value: profile.academicDegree,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Teaching subjects ────────────────────────────────────────────────
        if (profile != null && profile.teachingSubjects.isNotEmpty) ...[
          _SectionHeader(title: 'Преподаваемые предметы', icon: Icons.menu_book_outlined),
          const SizedBox(height: 10),
          _SectionCard(
            children: profile.teachingSubjects.map((s) => _InfoRow(
              icon: Icons.circle,
              iconSize: 8,
              label: s.name,
              value: s.description,
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // ── Theme selector ───────────────────────────────────────────────────
        _SectionHeader(title: 'Тема оформления', icon: Icons.palette_outlined),
        const SizedBox(height: 10),
        _SectionCard(
          padding: const EdgeInsets.all(12),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ThemeChip(type: AppThemeType.darkGold, label: 'Тёмное золото',
                    color: const Color(0xFFFFB300), provider: themeProvider),
                _ThemeChip(type: AppThemeType.darkEmerald, label: 'Тёмный изумруд',
                    color: const Color(0xFF2ECC71), provider: themeProvider),
                _ThemeChip(type: AppThemeType.softLatte, label: 'Мягкий латте',
                    color: const Color(0xFF795548), provider: themeProvider),
                _ThemeChip(type: AppThemeType.softZinc, label: 'Мягкий цинк',
                    color: const Color(0xFF18181B), provider: themeProvider),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Logout ───────────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text(
              'Выйти из аккаунта',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
            )),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  const _SectionCard({required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final AppThemeType type;
  final String label;
  final Color color;
  final ThemeProvider provider;
  const _ThemeChip(
      {required this.type,
      required this.label,
      required this.color,
      required this.provider});

  @override
  Widget build(BuildContext context) {
    final isActive = provider.themeType == type;
    return GestureDetector(
      onTap: () => provider.setTheme(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: isActive ? color : null,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double iconSize;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: theme.primaryColor.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : '—',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
