import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'group_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  late TabController _tabController;

  // ── Design tokens ──────────────────────────────────────
  static const _primary = Color(0xFF6C63FF);
  static const _surface = Color(0xFFF8F9FE);
  static const _cardBg = Colors.white;
  static const _textPrimary = Color(0xFF1A1D2E);
  static const _textSecondary = Color(0xFF8B8FA8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIndividualTab(),
                  _buildGroupsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── HEADER ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      color: _cardBg,
      child: Row(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                StreamBuilder<int>(
                  stream: _chatService.getTotalUnreadCount(),
                  builder: (_, snap) {
                    final c = snap.data ?? 0;
                    return Text(
                      c > 0 ? '$c unread' : 'All caught up ✓',
                      style: TextStyle(
                        fontSize: 12,
                        color: c > 0 ? _primary : _textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Unread badge
          StreamBuilder<int>(
            stream: _chatService.getTotalUnreadCount(),
            builder: (_, snap) {
              final c = snap.data ?? 0;
              if (c == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$c',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              );
            },
          ),
          _buildProfileButton(),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: _cardBg,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _chatService.getCurrentUserData(),
        builder: (_, snap) {
          final name = (snap.data?['name'] as String?) ?? 'U';
          return Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [_primary, Color(0xFF8B82FF)]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                    color: _primary.withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17),
              ),
            ),
          );
        },
      ),
      onSelected: (v) async {
        if (v == 'logout') {
          final ok = await _confirmDialog(
            title: 'Sign Out',
            message: 'Are you sure you want to sign out?',
            confirmText: 'Sign Out',
            confirmColor: Colors.red,
          );
          if (ok == true) await FirebaseAuth.instance.signOut();
        } else if (v == 'profile') {
          final data = await _chatService.getCurrentUserData();
          if (data != null && mounted) {
            _showProfileDialog(data);
          }
        }
      },
      itemBuilder: (_) => [
        _popupItem(
            'profile', Icons.person_outline_rounded, 'Profile', _primary),
        _popupItem('logout', Icons.logout_rounded, 'Sign Out', Colors.red),
      ],
    );
  }

  PopupMenuItem<String> _popupItem(
      String val, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color == Colors.red ? Colors.red : _textPrimary)),
      ]),
    );
  }

  // ── TAB BAR ────────────────────────────────────────────

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
                offset: const Offset(0, 2))
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
                const Text('Chats'),
                const SizedBox(width: 4),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _chatService.getUserChats(),
                  builder: (_, snap) {
                    final c = (snap.data ?? []).length;
                    if (c == 0) return const SizedBox.shrink();
                    return _TabBadge(
                        count: c, active: _tabController.index == 0);
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
                  builder: (_, snap) {
                    final c = (snap.data ?? []).length;
                    if (c == 0) return const SizedBox.shrink();
                    return _TabBadge(
                        count: c, active: _tabController.index == 1);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────

  Widget _buildFAB() {
    final isGroup = _tabController.index == 1;
    // Clients don't create groups
    return FutureBuilder<Map<String, dynamic>?>(
      future: _chatService.getCurrentUserData(),
      builder: (_, snap) {
        final role = snap.data?['role'] as String? ?? '';
        final canCreateGroup =
            (role == 'manager' || role == 'admin') && isGroup;
        if (isGroup && !canCreateGroup) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: _navigateToNewChat,
          backgroundColor: _primary,
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_comment_rounded, size: 20),
          label: const Text('New Chat',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        );
      },
    );
  }

  // ── INDIVIDUAL TAB ─────────────────────────────────────

  Widget _buildIndividualTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUserChats(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snap.hasError) return _buildError();
        final chats = snap.data ?? [];
        if (chats.isEmpty)
          return _buildEmpty('No conversations yet', 'Start a new chat');
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: chats.length,
          itemBuilder: (_, i) => _buildChatCard(chats[i], i),
        );
      },
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat, int index) {
    final other = _chatService.getOtherParticipant(chat);
    final unread = _chatService.getUnreadCountForChat(chat);
    final lastMsg = chat['lastMessage'] as String? ?? '';
    final ts = chat['lastMessageAt'] as Timestamp?;
    final time = _chatService.formatTimestamp(ts);
    final name = other['name'] as String? ?? '?';
    final avatar = other['avatar'] as String?;
    final roles = List<String>.from(chat['participantRoles'] ?? []);
    final otherRole = roles.isNotEmpty
        ? roles.firstWhere(
            (r) => r != 'staff' && r != 'client',
            orElse: () => roles.first,
          )
        : '';
    final hasUnread = unread > 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 180 + index * 40),
      curve: Curves.easeOut,
      builder: (_, v, child) => Transform.translate(
          offset: Offset(0, 14 * (1 - v)),
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: Dismissible(
        key: Key(chat['chatId'] as String),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDialog(
          title: 'Delete Chat',
          message:
              'Delete this conversation with $name? This cannot be undone.',
          confirmText: 'Delete',
          confirmColor: Colors.red,
        ),
        onDismissed: (_) async {
          try {
            await _chatService.deleteChat(chat['chatId'] as String);
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
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_rounded, color: Colors.white, size: 28),
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
          onTap: () => _openChat(chat['chatId'] as String, other),
          onLongPress: () => _showChatOptions(chat, name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    hasUnread ? _primary.withOpacity(0.3) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(children: [
              // Avatar
              Stack(children: [
                _buildAvatar(name, avatar),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759),
                      shape: BoxShape.circle,
                      border: Border.all(color: _cardBg, width: 2),
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Row(children: [
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
                          if (otherRole.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _buildRoleBadge(otherRole),
                          ],
                        ]),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? _primary : _textSecondary,
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(
                        child: Text(
                          lastMsg.isEmpty ? 'No messages yet' : lastMsg,
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
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── GROUPS TAB ─────────────────────────────────────────

  Widget _buildGroupsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getGroupChats(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snap.hasError) return _buildError();
        final groups = snap.data ?? [];
        if (groups.isEmpty) {
          return _buildEmpty('No groups yet',
              'Groups created by your manager will appear here');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: groups.length,
          itemBuilder: (_, i) => _buildGroupCard(groups[i], i),
        );
      },
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, int index) {
    final groupName = group['groupName'] as String? ?? 'Group';
    final lastMsg = group['lastMessage'] as String? ?? '';
    final ts = group['lastMessageAt'] as Timestamp?;
    final time = _chatService.formatTimestamp(ts);
    final unread = _chatService.getUnreadCountForChat(group);
    final hasUnread = unread > 0;
    final memberCount = (group['participants'] as List?)?.length ?? 0;
    final isAdmin = _chatService.isGroupAdmin(group);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 180 + index * 40),
      curve: Curves.easeOut,
      builder: (_, v, child) => Transform.translate(
          offset: Offset(0, 14 * (1 - v)),
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child)),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupChatScreen(chatData: group)),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
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
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(children: [
            // Group avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_primary, Color(0xFF9C94FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(children: [
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
              ]),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
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
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: hasUnread ? _primary : _textSecondary,
                        fontWeight:
                            hasUnread ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$memberCount members',
                          style: const TextStyle(
                              fontSize: 10,
                              color: _primary,
                              fontWeight: FontWeight.w600)),
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
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: Text(
                        lastMsg.isEmpty ? 'No messages yet' : lastMsg,
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
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────

  Widget _buildAvatar(String name, String? avatar) {
    final color = _getAvatarColor(name);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        image: avatar != null && avatar.isNotEmpty
            ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
            : null,
      ),
      child: avatar == null || avatar.isEmpty
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color),
              ),
            )
          : null,
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      _primary,
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF3B30),
      const Color(0xFF5856D6),
      const Color(0xFFFF2D55),
      const Color(0xFF00C7BE),
    ];
    return colors[name.hashCode.abs() % colors.length];
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
      child: Text(role.toUpperCase(),
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: color)),
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

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20)),
            child: const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(_primary)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Loading...',
              style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(22)),
              child: Icon(Icons.wifi_off_rounded,
                  size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 8),
            const Text('Check your connection and try again',
                style: TextStyle(fontSize: 13, color: _textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(26)),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 46, color: _primary),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(fontSize: 14, color: _textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── NAVIGATION ─────────────────────────────────────────

  void _openChat(String chatId, Map<String, dynamic> other) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ChatScreen(
          chatId: chatId,
          otherUserName: other['name'] as String,
          otherUserAvatar: other['avatar'] as String?,
        ),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOutCubic))
              .animate(a),
          child: child,
        ),
      ),
    );
  }

  void _navigateToNewChat() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const NewChatScreen(),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOutCubic))
              .animate(a),
          child: child,
        ),
      ),
    );
  }

  // ── DIALOGS ────────────────────────────────────────────

  void _showChatOptions(Map<String, dynamic> chat, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              final ok = await _confirmDialog(
                title: 'Delete Chat',
                message:
                    'Delete conversation with $name? This cannot be undone.',
                confirmText: 'Delete',
                confirmColor: Colors.red,
              );
              if (ok == true) {
                try {
                  await _chatService.deleteChat(chat['chatId'] as String);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red));
                  }
                }
              }
            },
          ),
        ]),
      ),
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
    Color confirmColor = _primary,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                fontSize: 18)),
        content: Text(message,
            style: const TextStyle(color: _textSecondary, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(
                    color: _textSecondary, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor: confirmColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmText,
                style: TextStyle(
                    color: confirmColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(Map<String, dynamic> data) {
    final name = data['name'] as String? ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_primary, Color(0xFF9C94FF)]),
                  borderRadius: BorderRadius.circular(20)),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _profileRow('Name', data['name'] ?? 'N/A'),
            _profileRow('Email', data['email'] ?? 'N/A'),
            _profileRow('Role', data['role'] ?? 'N/A'),
            _profileRow('Department', data['department'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              backgroundColor: _primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Close',
                style: TextStyle(color: _primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
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
                  fontSize: 13,
                  color: _textPrimary)),
        ),
      ]),
    );
  }
}

// ── Tab badge widget ────────────────────────────────────
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
