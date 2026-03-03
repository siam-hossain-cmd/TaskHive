import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
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
  bool _isSearching = false;
  String _searchQuery = '';

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
    final friendsAsync = ref.watch(friendsProvider);
    final totalFriends = friendsAsync.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(incomingCount, totalFriends),
            if (_isSearching && _tab.index == 0) _buildSearchBar(),
            _buildTabBar(incomingCount),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _FriendsTab(searchQuery: _searchQuery),
                  const _RequestsTab(),
                  const _FindPeopleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int badgeCount, int totalFriends) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Friends',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.0,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Connect & collaborate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (totalFriends > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$totalFriends',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isSearching
                    ? AppColors.primary
                    : AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.softShadows,
              ),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                size: 20,
                color: _isSearching ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
          if (badgeCount > 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _tab.animateTo(1);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadows,
        ),
        child: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search friends...',
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          cursorColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTabBar(int badgeCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadows,
        ),
        child: TabBar(
          controller: _tab,
          onTap: (_) => setState(() {}),
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
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
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B6B),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
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

// =============================== Friends Tab =================================
class _FriendsTab extends ConsumerWidget {
  final String searchQuery;
  const _FriendsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return const _EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No friends yet',
            subtitle:
                'Search for people and send them a friend request to start chatting!',
          );
        }
        final filtered = searchQuery.isEmpty
            ? friends
            : friends
                  .where(
                    (f) =>
                        f.friendName.toLowerCase().contains(searchQuery) ||
                        f.friendEmail.toLowerCase().contains(searchQuery),
                  )
                  .toList();
        if (filtered.isEmpty) {
          return const _EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matches',
            subtitle: 'Try a different name',
          );
        }
        final withUnread = filtered.where((f) => f.unreadCount > 0).toList()
          ..sort(
            (a, b) => (b.lastMessageAt ?? b.connectedAt).compareTo(
              a.lastMessageAt ?? a.connectedAt,
            ),
          );
        final withoutUnread = filtered.where((f) => f.unreadCount == 0).toList()
          ..sort(
            (a, b) => (b.lastMessageAt ?? b.connectedAt).compareTo(
              a.lastMessageAt ?? a.connectedAt,
            ),
          );
        final sorted = [...withUnread, ...withoutUnread];

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: sorted.length + (withUnread.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (withUnread.isNotEmpty && index == 0) {
              return const _SectionHeader(label: 'New Messages');
            }
            final adj = withUnread.isNotEmpty ? index - 1 : index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _FriendCard(friend: sorted[adj]),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final FriendModel friend;
  const _FriendCard({required this.friend});

  IconData? _msgIcon(String? msg) {
    if (msg == null) return null;
    if (msg.startsWith('\u{1F4F7}') || msg.contains('Photo'))
      return Icons.camera_alt_rounded;
    if (msg.startsWith('\u{1F4CE}') || msg.contains('File'))
      return Icons.attach_file_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = friend.unreadCount > 0;
    final icon = _msgIcon(friend.lastMessage);
    final preview = friend.lastMessage ?? 'Tap to start chatting';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/friends/chat/${friend.friendUid}', extra: friend);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: hasUnread
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _Avatar(
              name: friend.friendName,
              photoUrl: friend.friendPhotoUrl,
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          friend.friendName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w900
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (friend.lastMessageAt != null)
                        Text(
                          _timeLabel(friend.lastMessageAt!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: hasUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: hasUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasUnread)
              Container(
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    friend.unreadCount > 99 ? '99+' : '${friend.unreadCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}

// ============================== Requests Tab =================================
class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        incomingAsync.when(
          data: (reqs) {
            if (reqs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(label: 'INCOMING  \u00b7  ${reqs.length}'),
                const SizedBox(height: 6),
                ...reqs.map((r) => _IncomingRequestCard(req: r)),
                const SizedBox(height: 20),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => const SizedBox(),
        ),
        outgoingAsync.when(
          data: (reqs) {
            if (reqs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(label: 'SENT  \u00b7  ${reqs.length}'),
                const SizedBox(height: 6),
                ...reqs.map((r) => _SentRequestCard(req: r)),
              ],
            );
          },
          loading: () => const SizedBox(),
          error: (e, _) => const SizedBox(),
        ),
        if ((incomingAsync.asData?.value.isEmpty ?? true) &&
            (outgoingAsync.asData?.value.isEmpty ?? true))
          const _EmptyState(
            icon: Icons.mail_outline_rounded,
            title: 'No requests',
            subtitle:
                'When someone sends you a friend request, it will appear here.',
          ),
      ],
    );
  }
}

class _IncomingRequestCard extends ConsumerStatefulWidget {
  final FriendRequestModel req;
  const _IncomingRequestCard({required this.req});
  @override
  ConsumerState<_IncomingRequestCard> createState() =>
      _IncomingRequestCardState();
}

class _IncomingRequestCardState extends ConsumerState<_IncomingRequestCard> {
  bool _isAccepting = false;
  bool _isDeclining = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.req;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(name: req.fromName, photoUrl: req.fromPhotoUrl, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.fromName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      req.fromEmail,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeago.format(req.createdAt, locale: 'en_short'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isDeclining
                      ? null
                      : () async {
                          setState(() => _isDeclining = true);
                          await ref
                              .read(friendRequestNotifierProvider.notifier)
                              .decline(req.id);
                        },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: _isDeclining
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : Text(
                              'Decline',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _isAccepting
                      ? null
                      : () async {
                          setState(() => _isAccepting = true);
                          await ref
                              .read(friendRequestNotifierProvider.notifier)
                              .accept(req);
                        },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isAccepting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentRequestCard extends ConsumerStatefulWidget {
  final FriendRequestModel req;
  const _SentRequestCard({required this.req});
  @override
  ConsumerState<_SentRequestCard> createState() => _SentRequestCardState();
}

class _SentRequestCardState extends ConsumerState<_SentRequestCard> {
  bool _isCancelling = false;
  @override
  Widget build(BuildContext context) {
    final req = widget.req;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(
            name: req.fromName.isNotEmpty ? req.fromName : req.toUid,
            photoUrl: null,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.toUid.length > 12
                      ? '${req.toUid.substring(0, 12)}...'
                      : req.toUid,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\u00b7  ${timeago.format(req.createdAt, locale: 'en_short')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isCancelling
                ? null
                : () async {
                    setState(() => _isCancelling = true);
                    await ref
                        .read(friendRequestNotifierProvider.notifier)
                        .cancel(req.id);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isCancelling
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================= Find People Tab ================================
class _FindPeopleTab extends ConsumerStatefulWidget {
  const _FindPeopleTab();
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadows,
            ),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) {
                ref.read(userSearchQueryProvider.notifier).state = v;
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search by email or name...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          ref.read(userSearchQueryProvider.notifier).state = '';
                          setState(() {});
                        },
                        child: Icon(
                          Icons.clear_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: resultsAsync.when(
            data: (users) {
              final filtered = users.where((u) => u.uid != me).toList();
              if (filtered.isEmpty && _ctrl.text.isEmpty) {
                return const _EmptyState(
                  icon: Icons.person_search_rounded,
                  title: 'Discover people',
                  subtitle:
                      'Enter an email or name to find people and add them as friends.',
                );
              }
              if (filtered.isEmpty) {
                return const _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No one found',
                  subtitle: 'Try a different email or name.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final u = filtered[i];
                  final alreadyFriend = myFriends.any(
                    (f) => f.friendUid == u.uid,
                  );
                  final pendingReq = outgoing
                      .where((r) => r.toUid == u.uid)
                      .firstOrNull;
                  final hasPending = pendingReq != null;
                  return _SearchResultCard(
                    profile: u,
                    alreadyFriend: alreadyFriend,
                    hasPendingRequest: hasPending,
                    onCancel: pendingReq == null
                        ? null
                        : () async {
                            await ref
                                .read(friendRequestNotifierProvider.notifier)
                                .cancel(pendingReq.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Request to ${u.displayName} cancelled',
                                  ),
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
                            await ref
                                .read(friendRequestNotifierProvider.notifier)
                                .sendRequest(
                                  fromUid: user.uid,
                                  toUid: u.uid,
                                  fromName:
                                      user.displayName ?? user.email ?? '',
                                  fromEmail: user.email ?? '',
                                  fromPhotoUrl: user.photoURL,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Friend request sent to ${u.displayName}!',
                                  ),
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
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final UserProfile profile;
  final bool alreadyFriend;
  final bool hasPendingRequest;
  final VoidCallback? onAdd;
  final VoidCallback? onCancel;
  const _SearchResultCard({
    required this.profile,
    required this.alreadyFriend,
    required this.hasPendingRequest,
    this.onAdd,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(
            name: profile.displayName,
            photoUrl: profile.photoUrl,
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (alreadyFriend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Friends',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            )
          else if (hasPendingRequest)
            GestureDetector(
              onTap: onCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================== Shared Widgets ================================
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
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(photoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
