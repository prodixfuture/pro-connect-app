import 'package:flutter/material.dart';
import '/staff/chat/chat_service.dart';
import '/staff/chat/group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _selectedUserIds = [];
  final Map<String, String> _selectedUserNames = {};
  String _searchQuery = '';
  bool _isCreating = false;

  static const _primary = Color(0xFF6C63FF);
  static const _surface = Color(0xFFF8F9FE);
  static const _cardBg = Colors.white;
  static const _textPrimary = Color(0xFF1A1D2E);
  static const _textSecondary = Color(0xFF8B8FA8);

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _cardBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Group',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, color: _textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isCreating ? null : _createGroup,
              style: TextButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Create',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F5)),
        ),
      ),
      body: Column(
        children: [
          _buildGroupInfoSection(),
          _buildSelectedMembers(),
          _buildSearchBar(),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  Widget _buildGroupInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_primary, Color(0xFF9C94FF)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Group Name *',
                        hintStyle: const TextStyle(
                            color: _textSecondary, fontWeight: FontWeight.w500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFEEEDF8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFEEEDF8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: _surface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      style: const TextStyle(fontSize: 14, color: _textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Description (optional)',
                        hintStyle: const TextStyle(
                            color: _textSecondary, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFEEEDF8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFEEEDF8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: _surface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMembers() {
    if (_selectedUserIds.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _primary.withOpacity(0.15), style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_rounded,
                color: _primary.withOpacity(0.7), size: 20),
            const SizedBox(width: 10),
            Text('Select members to add to the group',
                style: TextStyle(
                    color: _primary.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedUserIds.length} members selected',
            style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedUserIds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final uid = _selectedUserIds[i];
                final name = _selectedUserNames[uid] ?? '';
                return GestureDetector(
                  onTap: () => _toggleUser(uid, name),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_primary, Color(0xFF9C94FF)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _cardBg, width: 2)),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name.split(' ').first,
                        style: const TextStyle(
                            fontSize: 9,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 14, color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search members...',
          hintStyle: const TextStyle(color: _textSecondary),
          prefixIcon:
              const Icon(Icons.search_rounded, color: _textSecondary, size: 20),
          filled: true,
          fillColor: _cardBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getAvailableUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var users = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          users = users.where((u) {
            final name = (u['name'] as String? ?? '').toLowerCase();
            final role = (u['role'] as String? ?? '').toLowerCase();
            return name.contains(_searchQuery.toLowerCase()) ||
                role.contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (users.isEmpty) {
          return const Center(
              child: Text('No users found',
                  style: TextStyle(color: _textSecondary)));
        }

        // Group by role
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final u in users) {
          final role = u['role'] as String? ?? 'other';
          grouped.putIfAbsent(role, () => []).add(u);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _textSecondary,
                        letterSpacing: 1),
                  ),
                ),
                ...entry.value.map((user) => _buildUserTile(user)),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final uid = user['uid'] as String;
    final name = user['name'] as String? ?? 'Unknown';
    final role = user['role'] as String? ?? '';
    final dept = user['department'] as String? ?? '';
    final isSelected = _selectedUserIds.contains(uid);

    return GestureDetector(
      onTap: () => _toggleUser(uid, name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withOpacity(0.08) : _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primary.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? _primary : const Color(0xFFEEEDF8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : _primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary)),
                  Text(dept.isNotEmpty ? '$role • $dept' : role,
                      style:
                          const TextStyle(fontSize: 12, color: _textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? _primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        isSelected ? _primary : _textSecondary.withOpacity(0.4),
                    width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _toggleUser(String uid, String name) {
    setState(() {
      if (_selectedUserIds.contains(uid)) {
        _selectedUserIds.remove(uid);
        _selectedUserNames.remove(uid);
      } else {
        _selectedUserIds.add(uid);
        _selectedUserNames[uid] = name;
      }
    });
  }

  Future<void> _createGroup() async {
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a group name'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one member'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final chatId = await _chatService.createGroupChat(
        groupName: groupName,
        memberIds: _selectedUserIds,
        description: _descController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context); // pop create screen

      final chatData = {
        'chatId': chatId,
        'isGroup': true,
        'groupName': groupName,
        'participants': [_chatService.currentUserId, ..._selectedUserIds],
        'adminIds': [_chatService.currentUserId],
        'description': _descController.text.trim(),
      };

      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(chatData: chatData),
          ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create group: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
