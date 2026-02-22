import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/notification_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final notifAsync = ref.watch(notificationSettingsProvider);
    final notifSettings = notifAsync.valueOrNull ?? const NotificationSettings();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings, style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        // Back button auto-shows when pushed (e.g. from Home), hidden when used as a tab
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          // ── Profile Banner ───────────────────────────────────────────────────
          _buildProfileBanner(context, ref),
          const SizedBox(height: AppSizes.lg),

          // ── Appearance ──────────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            label: AppStrings.darkMode,
            subtitle: isDark ? 'Dark theme active' : 'Light theme active',
            trailing: Switch.adaptive(
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
              activeTrackColor: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // ── Notifications ────────────────────────────────────────────────
          _SectionHeader(title: 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            subtitle: notifSettings.pushEnabled ? 'Enabled' : 'Disabled',
            trailing: Switch.adaptive(
              value: notifSettings.pushEnabled,
              onChanged: (v) =>
                  ref.read(notificationSettingsProvider.notifier).togglePush(v),
              activeTrackColor: AppColors.primary,
            ),
          ),
          _SettingsTile(
            icon: Icons.access_time_rounded,
            label: 'Auto Reminder',
            subtitle: notifSettings.reminderEnabled
                ? '${notifSettings.reminderHours}h before deadline'
                : 'Disabled',
            trailing: Switch.adaptive(
              value: notifSettings.reminderEnabled,
              onChanged: (v) => ref
                  .read(notificationSettingsProvider.notifier)
                  .toggleReminder(v),
              activeTrackColor: AppColors.primary,
            ),
          ),
          _SettingsTile(
            icon: Icons.alarm_outlined,
            label: 'Reminder Lead Time',
            subtitle: '${notifSettings.reminderHours} hours before deadline',
            trailing: const Icon(Icons.chevron_right_rounded, size: 22),
            onTap: () => _showReminderPicker(context, ref, notifSettings.reminderHours),
          ),

          const SizedBox(height: AppSizes.lg),

          // ── General ──────────────────────────────────────────────────────
          _SectionHeader(title: 'General'),
          _SettingsTile(
            icon: Icons.language_rounded,
            label: 'Language',
            subtitle: 'English',
            trailing: const Icon(Icons.chevron_right_rounded, size: 22),
            onTap: () => _showLanguagePicker(context),
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            label: 'Export Data',
            subtitle: 'Download your tasks as CSV',
            trailing: const Icon(Icons.chevron_right_rounded, size: 22),
            onTap: () => _showExportDialog(context),
          ),

          const SizedBox(height: AppSizes.lg),

          // ── Support ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Support'),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            subtitle: 'FAQs and contact us',
            trailing: const Icon(Icons.chevron_right_rounded, size: 22),
            onTap: () => _showHelpDialog(context),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'About TaskHive',
            subtitle: 'Version, licenses and details',
            trailing: const Icon(Icons.chevron_right_rounded, size: 22),
            onTap: () => _showAboutDialog(context),
          ),
          _SettingsTile(
            icon: Icons.star_outline_rounded,
            label: 'Rate the App',
            subtitle: 'Enjoying TaskHive? Leave a review',
            trailing: const Icon(Icons.chevron_right_rounded, size: 22),
            onTap: () async {
              final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.taskhive.taskhive');
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),

          const SizedBox(height: AppSizes.lg),

          // ── Account ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.logout_rounded,
            label: AppStrings.logout,
            iconColor: AppColors.warning,
            onTap: () async {
              final confirm = await _confirmDialog(
                context,
                title: 'Log Out',
                content: 'Are you sure you want to log out?',
                confirmLabel: 'Log Out',
                isDangerous: false,
              );
              if (confirm == true && context.mounted) {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            label: AppStrings.deleteAccount,
            iconColor: AppColors.error,
            onTap: () async {
              final confirm = await _confirmDialog(
                context,
                title: 'Delete Account',
                content:
                    'This action is irreversible. All your data will be permanently deleted.',
                confirmLabel: 'Delete',
                isDangerous: true,
              );
              if (confirm == true && context.mounted) {
                await ref.read(authRepositoryProvider).deleteAccount();
                if (context.mounted) context.go('/login');
              }
            },
          ),

          const SizedBox(height: AppSizes.xxl),
          Center(
            child: Text(
              'TaskHive v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }

  // ── Profile Banner ─────────────────────────────────────────────────────────
  Widget _buildProfileBanner(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final initial = user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : '?';
    final name = user?.displayName ?? 'Your Profile';
    final email = user?.email ?? '';

    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
            if (email.isNotEmpty)
              Text(email, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 16, color: Colors.white),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Reminder Picker ─────────────────────────────────────────────────────────
  Future<void> _showReminderPicker(
      BuildContext context, WidgetRef ref, int currentHours) async {
    final options = [1, 2, 4, 6, 12, 24, 48, 72];
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reminder Lead Time',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((h) {
            final label = h == 1
                ? '1 hour'
                : h < 24
                    ? '$h hours'
                    : '${h ~/ 24} day${h > 24 ? 's' : ''}';
            return ListTile(
              title: Text(label, style: TextStyle(
                fontWeight: h == currentHours ? FontWeight.w700 : FontWeight.w600,
                color: h == currentHours ? AppColors.primary : null,
              )),
              trailing: h == currentHours
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, h),
            );
          }).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );
    if (picked != null) {
      await ref.read(notificationSettingsProvider.notifier).setReminderHours(picked);
    }
  }

  // ── Language Picker ─────────────────────────────────────────────────────────
  Future<void> _showLanguagePicker(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langOption(ctx, '🇺🇸 English', true),
            _langOption(ctx, '🇸🇦 Arabic (coming soon)', false),
            _langOption(ctx, '🇲🇾 Malay (coming soon)', false),
            _langOption(ctx, '🇪🇸 Spanish (coming soon)', false),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _langOption(BuildContext ctx, String label, bool available) {
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: available ? null : Colors.grey)),
      trailing: available ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
      onTap: available ? () => Navigator.pop(ctx) : null,
    );
  }

  // ── Export Dialog ────────────────────────────────────────────────────────────
  Future<void> _showExportDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Your tasks will be exported and saved to your device Downloads folder. This feature will be available in v1.1.0.',
            style: TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  // ── Help Dialog ───────────────────────────────────────────────────────────
  Future<void> _showHelpDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help? Reach out to us:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _helpRow(Icons.email_outlined, 'support@taskhive.app', () async {
              final uri = Uri.parse('mailto:support@taskhive.app');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            }),
            const SizedBox(height: 8),
            _helpRow(Icons.language_rounded, 'taskhive.app/help', () async {
              final uri = Uri.parse('https://taskhive.app/help');
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            }),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _helpRow(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
      ]),
    );
  }

  // ── About Dialog ─────────────────────────────────────────────────────────────
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TaskHive',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.hive_rounded, color: Colors.white, size: 30),
      ),
      applicationLegalese: '© 2025 TaskHive. All rights reserved.',
      children: const [
        SizedBox(height: 12),
        Text(
          'TaskHive is a premium task management app designed to help students and teams stay organised, productive, and on track.',
          style: TextStyle(height: 1.5),
        ),
      ],
    );
  }

  // ── Confirm Dialog ───────────────────────────────────────────────────────────
  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    required bool isDangerous,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(content, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDangerous ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1.2, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Settings Tile ──────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: iconColor ?? AppColors.primary),
        ),
        title: Text(label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: iconColor)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}
