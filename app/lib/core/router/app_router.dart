import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/tasks/presentation/screens/home_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/tasks/presentation/screens/create_task_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/groups/presentation/screens/groups_list_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/friends/presentation/screens/friend_chat_screen.dart';
import '../../features/friends/domain/models/friend_model.dart';
import '../../features/friends/presentation/providers/friend_providers.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/notifications/presentation/screens/notification_screen.dart';
import '../../features/tasks/presentation/screens/assignment_detail_screen.dart';
import '../../features/tasks/presentation/screens/submission_detail_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

      // Full-screen modals
      GoRoute(
        path: '/create-task',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(
          fullscreenDialog: true,
          child: CreateTaskScreen(),
        ),
      ),
      GoRoute(
        path: '/create-group',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(
          fullscreenDialog: true,
          child: CreateGroupScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(
          fullscreenDialog: false,
          child: SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(
          fullscreenDialog: false,
          child: NotificationScreen(),
        ),
      ),
      GoRoute(
        path: '/calendar',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(child: CalendarScreen()),
      ),
      GoRoute(
        path: '/groups',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(child: GroupsListScreen()),
      ),
      GoRoute(
        path: '/analytics',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(child: AnalyticsScreen()),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(child: ProfileScreen()),
      ),

      // Full Screen Friend Chat
      GoRoute(
        path: '/friends/chat/:friendUid',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final friendUid = state.pathParameters['friendUid'] ?? '';
          final friend = state.extra as FriendModel?;
          return MaterialPage(
            child: FriendChatScreen(friendUid: friendUid, friend: friend),
          );
        },
      ),

      // Task Detail
      GoRoute(
        path: '/task/:taskId',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final taskId = state.pathParameters['taskId'] ?? '';
          return MaterialPage(
            child: TaskDetailScreen(taskId: taskId),
          );
        },
      ),

      // Assignment Detail
      GoRoute(
        path: '/assignment/:assignmentId',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final assignmentId = state.pathParameters['assignmentId'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final groupId = extra['groupId'] as String? ?? '';
          return MaterialPage(
            child: AssignmentDetailScreen(
              assignmentId: assignmentId,
              groupId: groupId,
            ),
          );
        },
      ),

      // Submission / Task Detail within Assignment
      GoRoute(
        path: '/assignment/:assignmentId/task/:taskId',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final assignmentId = state.pathParameters['assignmentId'] ?? '';
          final taskId = state.pathParameters['taskId'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final groupId = extra['groupId'] as String? ?? '';
          return MaterialPage(
            child: SubmissionDetailScreen(
              assignmentId: assignmentId,
              taskId: taskId,
              groupId: groupId,
            ),
          );
        },
      ),

      // Main App Shell — 4 tabs + FAB
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: TaskListScreen()),
          ),
          GoRoute(
            path: '/friends',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: FriendsScreen()),
          ),
          GoRoute(
            path: '/shell-settings',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});

// ─── Shell with 4-tab Nav Bar ────────────────────────────────────────────────
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  int get _currentIndex {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/tasks')) return 1;
    if (loc.startsWith('/friends')) return 2;
    if (loc.startsWith('/shell-settings')) return 3;
    return 0;
  }

  void _go(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/tasks');
        break;
      case 2:
        context.go('/friends');
        break;
      case 3:
        context.go('/shell-settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-task'),
        backgroundColor: AppColors.primary,
        elevation: 8,
        shape: const CircleBorder(),
        child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(36),
            boxShadow: AppTheme.softShadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BottomAppBar(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: AppColors.surfaceColor,
              shape: const CircularNotchedRectangle(),
              notchMargin: 10,
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: _currentIndex == 0,
                    onTap: () => _go(0),
                  ),
                  _NavItem(
                    icon: Icons.task_alt_rounded,
                    label: 'Tasks',
                    isSelected: _currentIndex == 1,
                    onTap: () => _go(1),
                  ),
                  const SizedBox(width: 56), // FAB gap
                  _FriendNavItem(
                    isSelected: _currentIndex == 2,
                    onTap: () => _go(2),
                  ),
                  _SettingsNavItem(
                    isSelected: _currentIndex == 3,
                    onTap: () => _go(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Standard Nav Item ────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.primary
        : AppColors.textSecondary.withValues(alpha: 0.5);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fixed padding — only animate the background color to avoid negative padding crash
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Friends Nav Item (unread badge) ─────────────────────────────────────────
class _FriendNavItem extends ConsumerWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _FriendNavItem({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider).asData?.value ?? [];
    final totalUnread = friends.fold<int>(0, (s, f) => s + f.unreadCount);
    final color = isSelected
        ? AppColors.primary
        : AppColors.textSecondary.withValues(alpha: 0.5);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.people_rounded, color: color, size: 24),
                ),
                if (totalUnread > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          totalUnread > 9 ? '9+' : '$totalUnread',
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Friends',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Settings Nav Item ────────────────────────────────────────────────────────
class _SettingsNavItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _SettingsNavItem({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.primary
        : AppColors.textSecondary.withValues(alpha: 0.5);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.settings_rounded, color: color, size: 24),
            ),
            const SizedBox(height: 3),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
