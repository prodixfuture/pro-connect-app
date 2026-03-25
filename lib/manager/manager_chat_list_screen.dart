import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../staff/chat/chat_service.dart';
import '../staff/chat/chat_screen.dart';
import '../staff/chat/new_chat_screen.dart';
import '../staff/chat/group_chat_screen.dart';
import '../staff/chat/create_group_screen.dart';
import '../staff/chat/widgets/chat_widgets.dart';

class ManagerChatListScreen extends StatefulWidget {
  const ManagerChatListScreen({super.key});

  @override
  State<ManagerChatListScreen> createState() => _ManagerChatListScreenState();
}

class _ManagerChatListScreenState extends State<ManagerChatListScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  late TabController _tabController;

  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Staff',
    'Clients',
    'Managers',
    'Unread'
  ];

  // Modern color palette
  static const _primary = Color(0xFF6C63FF);
  static const _surface = Color(0xFFF8F9FE);
  static const _cardBg = Colors.white;
  static const _textPrimary = Color(0xFF1A1D2E);
  static const _textSecondary = Color(0xFF8B8FA8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatisticsCard(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIndividualTab(),
                _buildGroupTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _cardBg,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, Color(0xFF8B82FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Manager Dashboard',
                style: TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
      actions: [
        StreamBuilder<int>(
          stream: _chatService.getTotalUnreadCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            if (unreadCount == 0) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: FutureBuilder<Map<String, dynamic>?>(
            future: _chatService.getCurrentUserData(),
            builder: (context, snapshot) {
              final name = snapshot.data?['name'] as String? ?? 'M';
              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B82FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'M',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              );
            },
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) async {
            if (value == 'logout') {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => _buildConfirmDialog(
                  ctx,
                  title: 'Logout',
                  content: 'Are you sure you want to logout?',
                  confirmText: 'Logout',
                  confirmColor: Colors.red,
                ),
              );
              if (ok == true) await FirebaseAuth.instance.signOut();
            } else if (value == 'profile') {
              final userData = await _chatService.getCurrentUserData();
              if (userData != null && mounted) _showProfileDialog(userData);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(children: [
                Icon(Icons.person_outline_rounded, size: 20),
                SizedBox(width: 12),
                Text('View Profile')
              ]),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                Icon(Icons.logout_rounded,
                    color: Colors.red.shade400, size: 20),
                const SizedBox(width: 12),
                Text('Logout', style: TextStyle(color: Colors.red.shade400))
              ]),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF0F0F5)),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUserChats(),
      builder: (context, indivSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _chatService.getGroupChats(),
          builder: (context, groupSnapshot) {
            final indivChats = indivSnapshot.data ?? [];
            final groupChats = groupSnapshot.data ?? [];

            final totalIndiv = indivChats.length;
            final totalGroups = groupChats.length;
            final totalUnread = [...indivChats, ...groupChats]
                .where((c) => _chatService.getUnreadCountForChat(c) > 0)
                .length;
            final staffChats = indivChats.where((chat) {
              final roles = List<String>.from(chat['participantRoles'] ?? []);
              return roles.contains('staff');
            }).length;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9C94FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      Icons.chat_bubble_rounded, 'Chats', '$totalIndiv'),
                  _buildStatDivider(),
                  _buildStatItem(
                      Icons.groups_rounded, 'Groups', '$totalGroups'),
                  _buildStatDivider(),
                  _buildStatItem(
                      Icons.mark_chat_unread_rounded, 'Unread', '$totalUnread'),
                  _buildStatDivider(),
                  _buildStatItem(Icons.badge_rounded, 'Staff', '$staffChats'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
        height: 40, width: 1, color: Colors.white.withOpacity(0.25));
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEDF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: _primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Individual'),
                const SizedBox(width: 4),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _chatService.getUserChats(),
                  builder: (ctx, snap) {
                    final count = (snap.data ?? []).length;
                    if (count == 0) return const SizedBox.shrink();
                    return _TabBadge(
                        count: count, active: _tabController.index == 0);
                  },
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_rounded, size: 16),
                const SizedBox(width: 6),
                const Text('Groups'),
                const SizedBox(width: 4),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _chatService.getGroupChats(),
                  builder: (ctx, snap) {
                    final count = (snap.data ?? []).length;
                    if (count == 0) return const SizedBox.shrink();
                    return _TabBadge(
                        count: count, active: _tabController.index == 1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final isGroupTab = _tabController.index == 1;
        return FloatingActionButton.extended(
          onPressed: isGroupTab ? _navigateToCreateGroup : _navigateToNewChat,
          backgroundColor: _primary,
          elevation: 6,
          icon: Icon(
              isGroupTab ? Icons.group_add_rounded : Icons.add_comment_rounded,
              size: 20),
          label: Text(isGroupTab ? 'New Group' : 'New Chat',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }

  // ── INDIVIDUAL TAB ──────────────────────────────────────────

  Widget _buildIndividualTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getUserChats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ChatListSkeleton();
              }
              if (snapshot.hasError)
                return _buildErrorState(snapshot.error.toString());

              var chats = snapshot.data ?? [];
              chats = _applyFilters(chats);

              if (chats.isEmpty) {
                return EmptyStateWidget(
                  title: _selectedFilter == 'All'
                      ? 'No conversations yet'
                      : 'No $_selectedFilter chats',
                  subtitle: 'Start a new conversation',
                  icon: Icons.chat_bubble_outline_rounded,
                  action: ElevatedButton.icon(
                    onPressed: _navigateToNewChat,
                    icon: const Icon(Icons.add),
                    label: const Text('New Chat'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: chats.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) =>
                    _buildIndividualChatCard(chats[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _primary : _cardBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: _primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4)
                      ],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : _textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIndividualChatCard(Map<String, dynamic> chat) {
    final other = _chatService.getOtherParticipant(chat);
    final unreadCount = _chatService.getUnreadCountForChat(chat);
    final lastMessage = chat['lastMessage'] as String? ?? '';
    final lastMessageAt = chat['lastMessageAt'] as Timestamp?;
    final timeString = _chatService.formatTimestamp(lastMessageAt);
    final roles = List<String>.from(chat['participantRoles'] ?? []);
    final otherRole =
        roles.firstWhere((r) => r != 'manager', orElse: () => 'manager');
    final name = other['name'] as String? ?? '?';
    final avatar = other['avatar'] as String?;
    final hasUnread = unreadCount > 0;
    final chatId = chat['chatId'] as String;

    return Dismissible(
      key: Key(chatId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => _buildConfirmDialog(
            ctx,
            title: 'Delete Chat',
            content: 'Delete conversation with $name? This cannot be undone.',
            confirmText: 'Delete',
            confirmColor: Colors.red,
          ),
        );
      },
      onDismissed: (_) async {
        try {
          await _chatService.deleteChat(chatId);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to delete: $e'),
                  backgroundColor: Colors.red),
            );
          }
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _openIndividualChat(chatId, other),
        onLongPress: () => _showChatOptionsSheet(chat, name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnread ? _primary.withOpacity(0.3) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _getRoleColor(otherRole).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      image: avatar != null && avatar.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(avatar), fit: BoxFit.cover)
                          : null,
                    ),
                    child: avatar == null || avatar.isEmpty
                        ? Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _getRoleColor(otherRole),
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _getRoleColor(otherRole),
                        shape: BoxShape.circle,
                        border: Border.all(color: _cardBg, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: hasUnread
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _buildRoleBadge(otherRole),
                            ],
                          ),
                        ),
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread ? _primary : _textSecondary,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread ? _textPrimary : _textSecondary,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ), // closes GestureDetector
    ); // closes Dismissible
  }

  // ── GROUP TAB ───────────────────────────────────────────────

  Widget _buildGroupTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getGroupChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ChatListSkeleton();
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return EmptyStateWidget(
            title: 'No groups yet',
            subtitle: 'Create a group to collaborate with your team',
            icon: Icons.groups_outlined,
            action: ElevatedButton.icon(
              onPressed: _navigateToCreateGroup,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Create Group'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary, foregroundColor: Colors.white),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _buildGroupCard(groups[index]),
        );
      },
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final groupName = group['groupName'] as String? ?? 'Group';
    final lastMessage = group['lastMessage'] as String? ?? '';
    final lastMessageAt = group['lastMessageAt'] as Timestamp?;
    final timeString = _chatService.formatTimestamp(lastMessageAt);
    final unreadCount = _chatService.getUnreadCountForChat(group);
    final hasUnread = unreadCount > 0;
    final memberCount = (group['participants'] as List?)?.length ?? 0;
    final isAdmin = _chatService.isGroupAdmin(group);
    final createdByName = group['createdByName'] as String? ?? '';
    final description = group['description'] as String? ?? '';

    return GestureDetector(
      onTap: () => _openGroupChat(group),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread ? _primary.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Group Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9C94FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  const Center(
                      child: Icon(Icons.groups_rounded,
                          color: Colors.white, size: 26)),
                  if (isAdmin)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: _cardBg, width: 2),
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: Colors.white, size: 9),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          groupName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                hasUnread ? FontWeight.w800 : FontWeight.w700,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? _primary : _textSecondary,
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$memberCount members',
                          style: const TextStyle(
                              fontSize: 10,
                              color: _primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Admin',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isEmpty
                              ? (description.isNotEmpty
                                  ? description
                                  : 'No messages yet')
                              : lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread ? _textPrimary : _textSecondary,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────

  void _showChatOptionsSheet(Map<String, dynamic> chat, String name) {
    final chatId = chat['chatId'] as String;
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.shade400, size: 20),
              ),
              title: Text('Delete Conversation',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade400,
                      fontSize: 15)),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => _buildConfirmDialog(c,
                      title: 'Delete Chat',
                      content: 'Delete conversation with $name?',
                      confirmText: 'Delete',
                      confirmColor: Colors.red),
                );
                if (ok == true) {
                  try {
                    await _chatService.deleteChat(chatId);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        role.toUpperCase(),
        style:
            TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF9C27B0);
      case 'manager':
        return const Color(0xFF2196F3);
      case 'staff':
        return const Color(0xFF4CAF50);
      case 'client':
        return const Color(0xFFFF9800);
      default:
        return _textSecondary;
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> chats) {
    if (_selectedFilter == 'All') return chats;
    if (_selectedFilter == 'Unread') {
      return chats
          .where((c) => _chatService.getUnreadCountForChat(c) > 0)
          .toList();
    }
    // Map display label → actual Firestore role value
    const roleMap = {
      'Staff': 'staff',
      'Clients': 'client',
      'Managers': 'manager'
    };
    final targetRole =
        roleMap[_selectedFilter] ?? _selectedFilter.toLowerCase();
    final myId = _chatService.currentUserId;

    return chats.where((chat) {
      final participants = List<String>.from(chat['participants'] ?? []);
      final roles = List<String>.from(chat['participantRoles'] ?? []);

      // Find the OTHER participant's role (not the current user)
      for (int i = 0; i < participants.length; i++) {
        if (participants[i] != myId) {
          final role = i < roles.length ? roles[i].toLowerCase() : '';
          if (role == targetRole) return true;
        }
      }
      return false;
    }).toList();
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade400),
          ),
          const SizedBox(height: 16),
          const Text('Failed to load',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openIndividualChat(String chatId, Map<String, dynamic> other) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserName: other['name'] as String,
            otherUserAvatar: other['avatar'] as String?,
          ),
        ));
  }

  void _openGroupChat(Map<String, dynamic> group) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupChatScreen(chatData: group),
        ));
  }

  void _navigateToNewChat() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const NewChatScreen()));
  }

  void _navigateToCreateGroup() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
  }

  void _showProfileDialog(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [_primary, Color(0xFF9C94FF)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  (userData['name'] as String? ?? 'M')[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildProfileRow('Name', userData['name'] ?? 'N/A'),
            _buildProfileRow('Email', userData['email'] ?? 'N/A'),
            _buildProfileRow('Role', 'Manager'),
            _buildProfileRow('Department', userData['department'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: TextStyle(color: _primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                    fontSize: 13)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildConfirmDialog(BuildContext ctx,
      {required String title,
      required String content,
      required String confirmText,
      required Color confirmColor}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(content, style: const TextStyle(color: _textSecondary)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: _textSecondary))),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText,
              style:
                  TextStyle(color: confirmColor, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _TabBadge extends StatelessWidget {
  final int count;
  final bool active;
  const _TabBadge({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withOpacity(0.3)
            : const Color(0xFF6C63FF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: active ? Colors.white : const Color(0xFF6C63FF),
        ),
      ),
    );
  }
}
