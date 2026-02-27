import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/friend_model.dart';
import '../providers/friend_providers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final incomingCount = incomingAsync.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(incomingCount),
            _buildTabBar(incomingCount),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _FriendsTab(),
                  _RequestsTab(),
                  _FindPeopleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int badgeCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Friends', style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.w900,
                color: AppColors.textPrimary, letterSpacing: -1.0, height: 1.1,
              )),
              SizedBox(height: 4),
              Text('Connect & collaborate', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              )),
            ],
          ),
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPurpleBlue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadows,
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('$badgeCount new', style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(int badgeCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadows,
        ),
        child: TabBar(
          controller: _tab,
          indicator: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          dividerColor: Colors.transparent,
          tabs: [
            const Tab(text: 'Friends'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests', style: TextStyle(fontSize: 12)),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.priorityHighText,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('$badgeCount', style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white,
                        )),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Find People'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════ Friends Tab ══════════════════════════════════
class _FriendsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) return _emptyState('No friends yet', 'Find people to connect with!', Icons.people_outline_rounded);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          itemCount: friends.length,
          itemBuilder: (context, i) => _FriendTile(friend: friends[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendModel friend;
  const _FriendTile({required this.friend});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/friends/chat/${friend.friendUid}', extra: friend),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadows,
        ),
        child: Row(
          children: [
            _Avatar(name: friend.friendName, photoUrl: friend.friendPhotoUrl, size: 52),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.friendName, style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                  )),
                  SizedBox(height: 3),
                  Text(
                    friend.lastMessage ?? 'Tap to chat',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (friend.lastMessageAt != null)
                  Text(_timeLabel(friend.lastMessageAt!), style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600,
                  )),
                SizedBox(height: 6),
                if (friend.unreadCount > 0)
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Center(child: Text('${friend.unreadCount}', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white,
                    ))),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

// ═══════════════════════════════ Requests Tab ══════════════════════════════════
class _RequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      children: [
        incomingAsync.when(
          data: (reqs) {
            if (reqs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incoming Requests', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary,
                )),
                const SizedBox(height: 12),
                ...reqs.map((r) => _IncomingRequestTile(req: r)),
                const SizedBox(height: 24),
              ],
            );
          },
          loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => SizedBox(),
        ),
        outgoingAsync.when(
          data: (reqs) {
            if (reqs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sent Requests', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary,
                )),
                const SizedBox(height: 12),
                ...reqs.map((r) => _SentRequestTile(req: r)),
              ],
            );
          },
          loading: () => const SizedBox(),
          error: (e, _) => const SizedBox(),
        ),
        if ((incomingAsync.asData?.value.isEmpty ?? true) &&
            (outgoingAsync.asData?.value.isEmpty ?? true))
          _emptyState('No requests', 'Find friends and send requests!', Icons.person_add_outlined),
      ],
    );
  }
}

class _IncomingRequestTile extends ConsumerWidget {
  final FriendRequestModel req;
  const _IncomingRequestTile({required this.req});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPurpleBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          _Avatar(name: req.fromName, photoUrl: req.fromPhotoUrl, size: 48),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.fromName, style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                )),
                Text(req.fromEmail, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
                )),
              ],
            ),
          ),
          Row(
            children: [
              _ActionBtn(
                icon: Icons.check_rounded,
                color: AppColors.priorityLowText,
                bg: AppColors.priorityLowBg,
                onTap: () => ref.read(friendRequestNotifierProvider.notifier).accept(req),
              ),
              SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.close_rounded,
                color: AppColors.priorityHighText,
                bg: AppColors.priorityHighBg,
                onTap: () => ref.read(friendRequestNotifierProvider.notifier).decline(req.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentRequestTile extends StatelessWidget {
  final FriendRequestModel req;
  const _SentRequestTile({required this.req});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          _Avatar(name: req.toUid, photoUrl: null, size: 48),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${req.toUid.substring(0, 8)}...', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                )),
                SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.priorityMediumBg, borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Pending', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.priorityMediumText,
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════ Find People Tab ════════════════════════════════
class _FindPeopleTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FindPeopleTab> createState() => _FindPeopleTabState();
}

class _FindPeopleTabState extends ConsumerState<_FindPeopleTab> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(userSearchResultsProvider);
    final outgoing = ref.watch(outgoingRequestsProvider).asData?.value ?? [];
    final myFriends = ref.watch(friendsProvider).asData?.value ?? [];
    final me = ref.watch(currentUidProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: isDark ? Border.all(color: Colors.white12) : null,
              boxShadow: isDark ? [] : AppTheme.softShadows,
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => ref.read(userSearchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                  hintText: 'Search by email or user ID...',
                  hintStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontWeight: FontWeight.w500),
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary),
              cursorColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: resultsAsync.when(
            data: (users) {
              final filtered = users.where((u) => u.uid != me).toList();
              if (filtered.isEmpty && _ctrl.text.isEmpty) {
                return _emptyState('Search for friends', 'Enter an email or user ID to find people', Icons.person_search_rounded);
              }
              if (filtered.isEmpty) {
                return _emptyState('No users found', 'Try a different email', Icons.search_off_rounded);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final u = filtered[i];
                  final alreadyFriend = myFriends.any((f) => f.friendUid == u.uid);
                  final pendingReq = outgoing.where((r) => r.toUid == u.uid).firstOrNull;
                  final hasPending = pendingReq != null;
                  return _SearchResultTile(
                    profile: u,
                    alreadyFriend: alreadyFriend,
                    hasPendingRequest: hasPending,
                    onCancel: pendingReq == null ? null : () async {
                      await ref.read(friendRequestNotifierProvider.notifier).cancel(pendingReq.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Friend request cancelled for ${u.displayName}'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.textPrimary,
                          ),
                        );
                      }
                    },
                    onAdd: alreadyFriend || hasPending
                        ? null
                        : () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;
                            await ref.read(friendRequestNotifierProvider.notifier).sendRequest(
                              fromUid: user.uid,
                              toUid: u.uid,
                              fromName: user.displayName ?? user.email ?? '',
                              fromEmail: user.email ?? '',
                              fromPhotoUrl: user.photoURL,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Friend request sent to ${u.displayName}!'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final UserProfile profile;
  final bool alreadyFriend;
  final bool hasPendingRequest;
  final VoidCallback? onAdd;
  final VoidCallback? onCancel;

  const _SearchResultTile({
    required this.profile,
    required this.alreadyFriend,
    required this.hasPendingRequest,
    this.onAdd,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          _Avatar(name: profile.displayName, photoUrl: profile.photoUrl, size: 48),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName, style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                )),
                Text(profile.email, style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500,
                )),
              ],
            ),
          ),
          if (alreadyFriend)
            _pill('Friends', AppColors.priorityLowBg, AppColors.priorityLowText)
          else if (hasPendingRequest)
            GestureDetector(
              onTap: onCancel,
              child: _pill('Cancel', AppColors.priorityHighBg, AppColors.priorityHighText),
            )
          else
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary, borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  const _Avatar({required this.name, this.photoUrl, required this.size});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(radius: size / 2, backgroundImage: NetworkImage(photoUrl!));
    }
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: AppColors.gradientPurpleBlue, shape: BoxShape.circle,
      ),
      child: Center(child: Text(_initials, style: TextStyle(
        fontSize: size * 0.32, fontWeight: FontWeight.w900, color: AppColors.primary,
      ))),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.bg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

Widget _emptyState(String title, String sub, IconData icon) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPurpleBlue, shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),
          SizedBox(height: 20),
          Text(title, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary,
          )),
          SizedBox(height: 8),
          Text(sub, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500,
          )),
        ],
      ),
    ),
  );
}
