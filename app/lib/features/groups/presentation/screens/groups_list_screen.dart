import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/group_model.dart';
import '../providers/group_providers.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: groupsAsync.when(
              data: (groups) => _buildContent(context, groups),
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<GroupModel> groups) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Space',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.0,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Collaborate & achieve goals',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _iconBtn(Icons.search_rounded),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push('/create-group'),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadows,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 36),

        if (groups.isEmpty) _buildEmptyState(context),

        // Group cards
        ...groups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildGroupCard(group),
          ),
        ),

        SizedBox(height: 100),
      ],
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadows,
      ),
      child: Icon(icon, size: 24, color: AppColors.textPrimary),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    final gradientIndex = group.id.hashCode;
    final groupTasksAsync = ref.watch(groupTasksProvider(group.id));

    // Get real progress from tasks
    int approvedCount = 0;
    int totalCount = 0;
    groupTasksAsync.whenData((tasks) {
      totalCount = tasks.length;
      approvedCount = tasks
          .where((t) => t.status == GroupTaskStatus.approved)
          .length;
    });
    final progress = totalCount > 0 ? approvedCount / totalCount : 0.0;

    return GestureDetector(
      onTap: () =>
          context.push('/group/${group.id}', extra: {'groupName': group.name}),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppTheme.softShadows,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.getGradientTheme(gradientIndex),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Colors.white.withValues(alpha: 0.65), // Glass wash
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.lightTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '${group.memberIds.length} Members active',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Member avatars
                    SizedBox(
                      width: 80,
                      height: 36,
                      child: Stack(
                        children: List.generate(
                          group.memberIds.length.clamp(0, 3),
                          (i) => Positioned(
                            left: i * 22.0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceColor,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                // Progress bar (real data)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.lightTextPrimary.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      totalCount > 0
                          ? '$approvedCount of $totalCount tasks done'
                          : 'No tasks yet',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightTextPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Collaboration Actions ──
                Row(
                  children: [
                    _buildCollabAction(
                      Icons.assignment_rounded,
                      'Tasks',
                      const Color(0xFFE65100),
                      () => context.push(
                        '/group/${group.id}',
                        extra: {'groupName': group.name},
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCollabAction(
                      Icons.chat_bubble_rounded,
                      'Chat',
                      const Color(0xFF667EEA),
                      () => context.push(
                        '/group/${group.id}/chat',
                        extra: {'groupName': group.name},
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCollabAction(
                      Icons.sticky_note_2_rounded,
                      'Notes',
                      const Color(0xFF11998E),
                      () => context.push(
                        '/group/${group.id}/notes',
                        extra: {'groupName': group.name},
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildCollabAction(
                      Icons.poll_rounded,
                      'Polls',
                      const Color(0xFFFF6B6B),
                      () => context.push(
                        '/group/${group.id}/polls',
                        extra: {'groupName': group.name},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollabAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: AppTheme.softShadows,
            ),
            child: Icon(
              Icons.groups_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No teams yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a space to collaborate.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 32),
          GestureDetector(
            onTap: () => context.push('/create-group'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadows,
              ),
              child: const Text(
                'Create Team',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
