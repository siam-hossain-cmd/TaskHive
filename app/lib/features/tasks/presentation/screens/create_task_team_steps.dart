part of 'create_task_screen.dart';

// ═══════════════════════════════════════════════════════
//  STEP 3 — Team Setup
// ═══════════════════════════════════════════════════════
class _StepTeam extends ConsumerWidget {
  final _TeamSource teamSource;
  final ValueChanged<_TeamSource> onSourceChange;
  final TextEditingController teamNameCtrl, memberSearchCtrl;
  final List<FriendModel> selectedMembers;
  final List<UserProfile> searchResults;
  final bool searching;
  final String? leaderId, leaderName;
  final PermissionMode permMode;
  final ValueChanged<String> onSearch;
  final ValueChanged<FriendModel> onToggleFriend;
  final ValueChanged<UserProfile> onToggleSearch;
  final void Function(String uid, String name) onSelectLeader;
  final ValueChanged<PermissionMode> onPermMode;
  // Existing team
  final GroupModel? selectedGroup;
  final String? assigneeId, assigneeName;
  final ValueChanged<GroupModel> onSelectGroup;
  final void Function(String id, String name) onSelectAssignee;
  // AI subtask assignment
  final List<AISubTask>? aiSubtasks;
  final void Function(int subtaskIndex, String memberId, String memberName)?
  onAssignSubtask;

  const _StepTeam({
    required this.teamSource,
    required this.onSourceChange,
    required this.teamNameCtrl,
    required this.memberSearchCtrl,
    required this.selectedMembers,
    required this.searchResults,
    required this.searching,
    required this.leaderId,
    required this.leaderName,
    required this.permMode,
    required this.onSearch,
    required this.onToggleFriend,
    required this.onToggleSearch,
    required this.onSelectLeader,
    required this.onPermMode,
    required this.selectedGroup,
    required this.assigneeId,
    required this.assigneeName,
    required this.onSelectGroup,
    required this.onSelectAssignee,
    this.aiSubtasks,
    this.onAssignSubtask,
  });

  bool _isSel(String uid) => selectedMembers.any((m) => m.friendUid == uid);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final groupsAsync = ref.watch(userGroupsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source toggle
          _SourceToggle(current: teamSource, onChange: onSourceChange),
          const SizedBox(height: 24),

          if (teamSource == _TeamSource.newTeam) ...[
            // ── New Team ──────────────────────────────────
            _label('Team Name *'),
            const SizedBox(height: 8),
            _field(teamNameCtrl, 'e.g. Design Squad', Icons.groups_rounded),
            const SizedBox(height: 20),

            _label('Add Members'),
            const SizedBox(height: 10),

            // Selected chips
            if (selectedMembers.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedMembers
                    .map(
                      (m) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            m.friendName.isNotEmpty
                                ? m.friendName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        label: Text(
                          m.friendName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: AppColors.surfaceColor,
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                        onDeleted: () => onToggleFriend(m),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: 14),
            ],

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.softShadows,
              ),
              child: TextField(
                controller: memberSearchCtrl,
                onChanged: onSearch,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by email or user ID...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  suffixIcon: searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 14),

            // Search results
            if (searchResults.isNotEmpty) ...[
              Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ...searchResults.map(
                (u) => _MemberListTile(
                  name: u.displayName,
                  subtitle: u.email,
                  uid: u.uid,
                  isSelected: _isSel(u.uid),
                  onTap: () => onToggleSearch(u),
                ),
              ),
              Divider(height: 24),
            ],

            // Friends list
            Text(
              'YOUR FRIENDS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            friendsAsync.when(
              data: (friends) => friends.isEmpty
                  ? _emptyFriends()
                  : Column(
                      children: friends
                          .map(
                            (f) => _MemberListTile(
                              name: f.friendName,
                              subtitle: f.friendEmail,
                              uid: f.friendUid,
                              isSelected: _isSel(f.friendUid),
                              onTap: () => onToggleFriend(f),
                            ),
                          )
                          .toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => Text('Error: $e'),
            ),

            // Leader picker
            if (selectedMembers.isNotEmpty) ...[
              const SizedBox(height: 24),
              _label('Choose Leader'),
              const SizedBox(height: 10),
              ...selectedMembers.map((m) {
                final isLeader = leaderId == m.friendUid;
                return GestureDetector(
                  onTap: () => onSelectLeader(m.friendUid, m.friendName),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isLeader
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isLeader
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: AppTheme.softShadows,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isLeader
                                ? AppColors.primary
                                : AppColors.bgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              m.friendName.isNotEmpty
                                  ? m.friendName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: isLeader
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.friendName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                m.friendEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLeader)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'LEADER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              _label('Permission Rules'),
              const SizedBox(height: 10),
              _PermCard(
                icon: Icons.shield_rounded,
                title: 'Leader-Led',
                subtitle:
                    'Only the leader can assign tasks and approve submissions',
                selected: permMode == PermissionMode.leader,
                onTap: () => onPermMode(PermissionMode.leader),
              ),
              const SizedBox(height: 10),
              _PermCard(
                icon: Icons.handshake_rounded,
                title: 'Democratic',
                subtitle:
                    'Any member can assign tasks, leader approves submissions',
                selected: permMode == PermissionMode.democratic,
                onTap: () => onPermMode(PermissionMode.democratic),
              ),
            ],
          ] else ...[
            // ── Existing Team ─────────────────────────────
            _label('Select Your Team'),
            SizedBox(height: 10),
            groupsAsync.when(
              data: (groups) => groups.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          "You haven't created any teams yet.\nUse 'Create New Team' instead.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: groups.map((g) {
                        final isSel = selectedGroup?.id == g.id;
                        return GestureDetector(
                          onTap: () => onSelectGroup(g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.primary.withValues(alpha: 0.07)
                                  : AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: AppTheme.softShadows,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: isSel
                                        ? const LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.secondary,
                                            ],
                                          )
                                        : null,
                                    color: isSel ? null : AppColors.bgColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.groups_rounded,
                                    color: isSel
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        g.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${g.memberIds.length} members · ${g.permissionMode.name}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSel)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Text('Error: $e'),
            ),

            // Assignee picker from group
            if (selectedGroup != null) ...[
              const SizedBox(height: 24),
              _label('Assign Task To'),
              const SizedBox(height: 10),
              ...selectedGroup!.memberIds.map((uid) {
                final isSel = assigneeId == uid;
                return GestureDetector(
                  onTap: () => onSelectAssignee(uid, uid),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSel ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: AppTheme.softShadows,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.bgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: isSel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uid == selectedGroup!.leaderId
                                    ? 'Leader'
                                    : 'Member',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                uid.length > 16
                                    ? '${uid.substring(0, 16)}...'
                                    : uid,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (uid == selectedGroup!.leaderId)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.priorityHighBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Leader',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.priorityHighText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],

          // ── AI Subtask Assignment Board ─────────────────
          if (aiSubtasks != null && aiSubtasks!.isNotEmpty) ...[
            SizedBox(height: 28),
            Container(
              width: double.infinity,
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_ind_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign Subtasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Distribute AI-generated tasks to team members',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...aiSubtasks!.asMap().entries.map((entry) {
              final i = entry.key;
              final subtask = entry.value;
              // Build available members list
              final availableMembers = <_AssignableMember>[];
              if (teamSource == _TeamSource.newTeam) {
                for (final m in selectedMembers) {
                  availableMembers.add(
                    _AssignableMember(id: m.friendUid, name: m.friendName),
                  );
                }
              } else if (selectedGroup != null) {
                for (final uid in selectedGroup!.memberIds) {
                  availableMembers.add(
                    _AssignableMember(
                      id: uid,
                      name: uid == selectedGroup!.leaderId
                          ? 'Leader ($uid)'
                          : uid,
                    ),
                  );
                }
              }

              return _SubtaskAssignCard(
                index: i,
                subtask: subtask,
                members: availableMembers,
                onAssign: (memberId, memberName) {
                  onAssignSubtask?.call(i, memberId, memberName);
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _emptyFriends() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surfaceColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'No friends yet',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add friends first or search by email/UID above',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _label(String t) => Text(
    t,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: AppColors.textSecondary,
      letterSpacing: 0.5,
    ),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppTheme.softShadows,
        ),
        child: TextField(
          controller: ctrl,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      );
}

// ─── Source Toggle ────────────────────────────────────────────────────────────
class _SourceToggle extends StatelessWidget {
  final _TeamSource current;
  final ValueChanged<_TeamSource> onChange;
  const _SourceToggle({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: _TeamSource.values.map((s) {
          final isSel = current == s;
          final label = s == _TeamSource.newTeam
              ? '✨ Create New Team'
              : '📂 Use Existing Team';
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.surfaceColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSel ? AppTheme.softShadows : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Member List Tile ─────────────────────────────────────────────────────────
class _MemberListTile extends StatelessWidget {
  final String name, subtitle, uid;
  final bool isSelected;
  final VoidCallback onTap;
  const _MemberListTile({
    required this.name,
    required this.subtitle,
    required this.uid,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppTheme.softShadows,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Permission Card ──────────────────────────────────────────────────────────
class _PermCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _PermCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppTheme.softShadows,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  STEP 4 — Review
// ═══════════════════════════════════════════════════════
class _StepReview extends StatelessWidget {
  final _TaskMode mode;
  final String title;
  final DateTime dueDate;
  final TimeOfDay dueTime;
  final TaskPriority priority;
  final _TeamSource teamSource;
  final String teamName;
  final GroupModel? selectedGroup;
  final List<FriendModel> selectedMembers;
  final String? leaderName, assigneeName;
  final PermissionMode permMode;
  final AIAnalysisResult? aiResult;
  final ValueChanged<int> onEdit;

  const _StepReview({
    required this.mode,
    required this.title,
    required this.dueDate,
    required this.dueTime,
    required this.priority,
    required this.teamSource,
    required this.teamName,
    required this.selectedGroup,
    required this.selectedMembers,
    required this.leaderName,
    required this.assigneeName,
    required this.permMode,
    required this.onEdit,
    this.aiResult,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColors = {
      TaskPriority.high: (AppColors.priorityHighBg, AppColors.priorityHighText),
      TaskPriority.medium: (
        AppColors.priorityMediumBg,
        AppColors.priorityMediumText,
      ),
      TaskPriority.low: (AppColors.priorityLowBg, AppColors.priorityLowText),
    };
    final (prioBg, prioText) = priorityColors[priority]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everything looks\ngood?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Review the details before creating your task.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Task card
          _ReviewSection(
            title: 'Task Details',
            onEdit: () => onEdit(1),
            children: [
              _ReviewRow(
                icon: Icons.title_rounded,
                label: 'Title',
                value: title.isEmpty ? 'Untitled' : title,
              ),
              _ReviewRow(
                icon: Icons.calendar_today_rounded,
                label: 'Due',
                value:
                    '${DateFormat('MMM dd, yyyy').format(dueDate)} at ${_formatTime(dueTime)}',
              ),
              _ReviewRow(
                icon: Icons.flag_rounded,
                label: 'Priority',
                valueWidget: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: prioBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: prioText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (mode == _TaskMode.team)
            _ReviewSection(
              title: 'Team',
              onEdit: () => onEdit(2),
              children: [
                _ReviewRow(
                  icon: Icons.groups_rounded,
                  label: 'Mode',
                  value: teamSource == _TeamSource.newTeam
                      ? 'New Team — $teamName'
                      : 'Existing — ${selectedGroup?.name ?? '?'}',
                ),
                if (leaderName != null)
                  _ReviewRow(
                    icon: Icons.star_rounded,
                    label: 'Leader',
                    value: leaderName!,
                  ),
                if (selectedMembers.isNotEmpty)
                  _ReviewRow(
                    icon: Icons.people_rounded,
                    label: 'Members',
                    value:
                        '${selectedMembers.length} member${selectedMembers.length > 1 ? 's' : ''}',
                  ),
                if (teamSource == _TeamSource.newTeam)
                  _ReviewRow(
                    icon: Icons.shield_rounded,
                    label: 'Rules',
                    value: permMode == PermissionMode.leader
                        ? 'Leader-Led'
                        : 'Democratic',
                  ),
                if (assigneeName != null)
                  _ReviewRow(
                    icon: Icons.assignment_ind_rounded,
                    label: 'Assignee',
                    value: assigneeName!,
                  ),
              ],
            ),

          // AI Analysis summary
          if (aiResult != null && aiResult!.subtasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReviewSection(
              title: 'AI Subtasks',
              onEdit: () => onEdit(1),
              children: [
                _ReviewRow(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Total',
                  value:
                      '${aiResult!.subtasks.length} subtask${aiResult!.subtasks.length != 1 ? 's' : ''}',
                ),
                _ReviewRow(
                  icon: Icons.assignment_ind_rounded,
                  label: 'Assigned',
                  value:
                      '${aiResult!.subtasks.where((s) => s.assignedToId != null).length} / ${aiResult!.subtasks.length}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  const _ReviewRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: valueWidget ??
                Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Assignable Member ────────────────────────────────────────────────────────
class _AssignableMember {
  final String id;
  final String name;
  const _AssignableMember({required this.id, required this.name});
}

// ─── Subtask Assignment Card ──────────────────────────────────────────────────
class _SubtaskAssignCard extends StatelessWidget {
  final int index;
  final AISubTask subtask;
  final List<_AssignableMember> members;
  final void Function(String memberId, String memberName) onAssign;

  const _SubtaskAssignCard({
    required this.index,
    required this.subtask,
    required this.members,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColors = {
      'high': (AppColors.priorityHighBg, AppColors.priorityHighText),
      'medium': (AppColors.priorityMediumBg, AppColors.priorityMediumText),
      'low': (AppColors.priorityLowBg, AppColors.priorityLowText),
    };
    final prio = subtask.priority.toLowerCase();
    final (bg, text) =
        priorityColors[prio] ??
        (AppColors.priorityLowBg, AppColors.priorityLowText);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
        border: subtask.assignedToId != null
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtask.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  prio.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: text,
                  ),
                ),
              ),
            ],
          ),
          if (subtask.description.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              subtask.description,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 10),
          // Member assignment dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              underline: SizedBox(),
              value: subtask.assignedToId,
              hint: Row(
                children: [
                  Icon(
                    Icons.person_add_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Assign to member',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              items: members
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: m.id,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                m.name.isNotEmpty
                                    ? m.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.name.length > 20
                                  ? '${m.name.substring(0, 20)}...'
                                  : m.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (memberId) {
                if (memberId != null) {
                  final member = members.firstWhere((m) => m.id == memberId);
                  onAssign(memberId, member.name);
                }
              },
            ),
          ),
          if (subtask.assignedToId != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Assigned to ${subtask.assignedToName ?? subtask.assignedToId}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
