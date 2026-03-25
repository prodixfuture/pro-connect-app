import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'chat_screen.dart';
import 'widgets/chat_widgets.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedRole;
  String _searchQuery = '';

  final List<String> departments = [
    'All Departments',
    'Sales',
    'Marketing',
    'Engineering',
    'HR',
    'Finance',
    'Support',
  ];

  final List<String> roles = [
    'All Roles',
    'staff',
    'manager',
    'admin',
    'client',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getFilteredUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load users'));
                }

                var users = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) {
                    return (u['name'] as String)
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        (u['role'] as String)
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return UserTile(
                      name: user['name'],
                      role: user['role'],
                      subtitle: user['department'],
                      avatar: user['avatar'],
                      onTap: () => _createOrOpenChat(user),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getFilteredUsers() {
    if (_selectedDepartment != null &&
        _selectedDepartment != 'All Departments') {
      return _chatService.getUsersByDepartment(_selectedDepartment);
    }

    if (_selectedRole != null && _selectedRole != 'All Roles') {
      return _chatService.getUsersByRole(_selectedRole);
    }

    return _chatService.getAvailableUsers();
  }

  Future<void> _createOrOpenChat(Map<String, dynamic> user) async {
    final userId = user['uid'] as String;

    final canChat = await _chatService.canChatWith(userId);
    if (!canChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to chat with this user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final chatId = await _chatService.getOrCreateChat(userId);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserName: user['name'],
              otherUserAvatar: user['avatar'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create chat: $e')),
      );
    }
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search by name or role',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }
}
