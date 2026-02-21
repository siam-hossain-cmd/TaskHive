import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));

          return CustomScrollView(
            slivers: [
              // ── Profile Header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20)],
                  ),
                  child: Column(children: [
                    // Avatar
                    Container(
                      width: 86, height: 86,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 5))],
                      ),
                      child: Center(child: Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                      )),
                    ),
                    const SizedBox(height: 14),
                    Text(user.displayName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),

                    // Unique ID badge
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: user.uniqueId));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('User ID copied!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.tag_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(user.uniqueId, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.8)),
                          const SizedBox(width: 6),
                          Icon(Icons.copy_rounded, size: 13, color: AppColors.primary.withValues(alpha: 0.6)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Stats Row ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(children: [
                    _StatCard(icon: Icons.bolt_rounded, label: 'XP', value: '${user.xp}', color: AppColors.warning),
                    const SizedBox(width: 10),
                    _StatCard(icon: Icons.local_fire_department_rounded, label: 'Streak', value: '${user.streak}d', color: AppColors.error),
                    const SizedBox(width: 10),
                    _StatCard(icon: Icons.emoji_events_rounded, label: 'Badges', value: '${user.badges.length}', color: AppColors.accent),
                  ]),
                ),
              ),

              // ── Menu ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(children: [

                    // ── Settings — primary CTA ──────────────────────────
                    _SettingsCTA(onTap: () => context.push('/settings')),
                    const SizedBox(height: 24),

                    // ── Account section ─────────────────────────────────
                    _SectionLabel('My Activity'),
                    _MenuTile(icon: Icons.analytics_outlined, label: 'Analytics', onTap: () => context.push('/analytics')),
                    _MenuTile(icon: Icons.groups_outlined, label: 'My Teams', onTap: () => context.push('/groups')),
                    _MenuTile(icon: Icons.emoji_events_outlined, label: 'Achievements',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('🏆 Achievements coming in v1.1.0!'),
                        behavior: SnackBarBehavior.floating,
                      ))),
                    const SizedBox(height: 16),

                    _SectionLabel('Support'),
                    _MenuTile(icon: Icons.help_outline_rounded, label: 'Help & Support',
                      onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w800)),
                        content: const Text('Email us at support@taskhive.app for assistance.', style: TextStyle(height: 1.5)),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                      ))),
                    _MenuTile(icon: Icons.info_outline_rounded, label: 'About TaskHive',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'TaskHive',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2025 TaskHive',
                      )),
                  ]),
                ),
              ),

              // ── Member Since ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Center(child: Text(
                    'Member since ${AppHelpers.formatDate(user.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  )),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

// ─── Settings CTA banner ─────────────────────────────────────────────────────
class _SettingsCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _SettingsCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              Text('Theme, notifications, account', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 24),
        ]),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text.toUpperCase(), style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: AppColors.textSecondary, letterSpacing: 1.2)),
      ),
    );
  }
}

// ─── Menu Tile ────────────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Icon(icon, size: 22, color: AppColors.textPrimary),
        ),
        title: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
