import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBadgeManagement extends StatefulWidget {
  const AdminBadgeManagement({super.key});
  @override
  State<AdminBadgeManagement> createState() => _AdminBadgeManagementState();
}

class _AdminBadgeManagementState extends State<AdminBadgeManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 6 tabs now
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Badge metadata per role ───────────────────────────────────────────────
  String _getBadgeTitle(dynamic roleData) {
    final roles = _toRoleList(roleData);
    if (roles.any((r) => r.contains('accountant')))
      return 'Efficiency Champion';
    if (roles.any((r) => r.contains('sales'))) return 'Game Changer';
    if (roles.any((r) => r.contains('design'))) return 'Creative Genius';
    if (roles.any((r) => r.contains('manager') || r.contains('admin')))
      return 'Visionary Leader';
    if (roles.any((r) => r.contains('client') || r.contains('customer')))
      return 'Legend';
    if (roles.any((r) => r.contains('staff'))) return 'Outstanding';
    return 'Best Performer';
  }

  IconData _getBadgeIcon(dynamic roleData) {
    final roles = _toRoleList(roleData);
    if (roles.any((r) => r.contains('accountant')))
      return Icons.account_balance_rounded;
    if (roles.any((r) => r.contains('sales'))) return Icons.trending_up_rounded;
    if (roles.any((r) => r.contains('design'))) return Icons.palette_rounded;
    if (roles.any((r) => r.contains('manager') || r.contains('admin')))
      return Icons.lightbulb_rounded;
    if (roles.any((r) => r.contains('client') || r.contains('customer')))
      return Icons.workspace_premium_rounded;
    if (roles.any((r) => r.contains('staff'))) return Icons.stars_rounded;
    return Icons.star_rounded;
  }

  Color _getBadgeColor(dynamic roleData) {
    final roles = _toRoleList(roleData);
    if (roles.any((r) => r.contains('accountant')))
      return const Color(0xff00BCD4); // Cyan
    if (roles.any((r) => r.contains('sales')))
      return const Color(0xffFFD700); // Gold
    if (roles.any((r) => r.contains('design')))
      return const Color(0xff9C27B0); // Purple
    if (roles.any((r) => r.contains('manager') || r.contains('admin')))
      return const Color(0xff2196F3); // Blue
    if (roles.any((r) => r.contains('client') || r.contains('customer')))
      return const Color(0xffFF5722); // Orange
    if (roles.any((r) => r.contains('staff')))
      return const Color(0xff4CAF50); // Green
    return const Color(0xffFFD700);
  }

  bool _matchesRole(dynamic roleData, String filterRole) {
    final roles = _toRoleList(roleData);
    switch (filterRole) {
      case 'accountant':
        return roles.any((r) => r.contains('accountant'));
      case 'sales':
        return roles.any((r) => r.contains('sales') && !r.contains('_staff'));
      case 'design':
        return roles.any((r) => r.contains('design'));
      case 'manager':
        return roles.any((r) => r.contains('manager') || r.contains('admin'));
      case 'client':
        return roles.any((r) => r.contains('client') || r.contains('customer'));
      case 'staff':
        return roles.any((r) =>
            (r == 'staff' || r.contains('staff')) &&
            !r.contains('sales') &&
            !r.contains('design') &&
            !r.contains('accountant'));
      default:
        return false;
    }
  }

  List<String> _toRoleList(dynamic roleData) {
    if (roleData is String) return [roleData.toLowerCase()];
    if (roleData is List)
      return roleData.map((r) => r.toString().toLowerCase()).toList();
    return [];
  }

  Future<void> _toggleBadge(
      String userId, String userName, bool current, dynamic roleData) async {
    final badgeTitle = _getBadgeTitle(roleData);
    final badgeColor = _getBadgeColor(roleData);
    final roleStr =
        roleData is List ? (roleData as List).join(', ') : roleData.toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(current ? 'Remove Badge' : 'Award Badge'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15), shape: BoxShape.circle),
              child:
                  Icon(_getBadgeIcon(roleData), color: badgeColor, size: 28)),
          const SizedBox(height: 12),
          Text('"$badgeTitle"',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text(current ? 'Remove from $userName?' : 'Award to $userName?'),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: current ? Colors.red : badgeColor,
                  foregroundColor: Colors.white),
              child: Text(current ? 'Remove' : 'Award')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'hasPremiumBadge': !current,
        'badgeTitle': current ? '' : badgeTitle,
        'badgeType': current ? '' : roleStr,
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(current
              ? 'Badge removed from $userName'
              : '$badgeTitle awarded to $userName'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Badges'),
        backgroundColor: const Color(0xff6366f1),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(
                icon: Icon(Icons.account_balance_rounded, size: 16),
                text: 'Accountant'),
            Tab(icon: Icon(Icons.trending_up_rounded, size: 16), text: 'Sales'),
            Tab(icon: Icon(Icons.palette_rounded, size: 16), text: 'Designers'),
            Tab(icon: Icon(Icons.stars_rounded, size: 16), text: 'Staff'),
            Tab(
                icon: Icon(Icons.lightbulb_rounded, size: 16),
                text: 'Managers'),
            Tab(
                icon: Icon(Icons.workspace_premium_rounded, size: 16),
                text: 'Clients'),
          ],
        ),
      ),
      backgroundColor: const Color(0xfff8f9fa),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList('accountant'),
          _buildUserList('sales'),
          _buildUserList('design'),
          _buildUserList('staff'),
          _buildUserList('manager'),
          _buildUserList('client'),
        ],
      ),
    );
  }

  Widget _buildUserList(String roleFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final all = snap.data!.docs;
        final filtered = all.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final roleData = data['roles'] ?? data['role'] ?? '';
          return _matchesRole(roleData, roleFilter);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(_getBadgeIcon(roleFilter),
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No ${_getRoleName(roleFilter)} found',
                    style: const TextStyle(
                        fontSize: 18, color: Color(0xff6b7280))),
                const SizedBox(height: 8),
                Text('Role field must contain: "${roleFilter}"',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xff9ca3af))),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                    onPressed: () => _showDebug(all),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Show All Roles'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff6366f1))),
              ]));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final doc = filtered[i];
            final userData = doc.data() as Map<String, dynamic>;
            final name = userData['name'] ?? 'Unknown';
            final email = userData['email'] ?? '';
            final roleData = userData['roles'] ?? userData['role'] ?? '';
            final hasBadge = userData['hasPremiumBadge'] ?? false;
            final bColor = _getBadgeColor(roleData);
            final bTitle = _getBadgeTitle(roleData);
            final bIcon = _getBadgeIcon(roleData);
            String roleDisplay = roleData is List
                ? (roleData as List).join(', ')
                : roleData.toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: hasBadge ? Border.all(color: bColor, width: 2) : null,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: hasBadge
                                    ? [bColor, bColor.withOpacity(0.7)]
                                    : [
                                        const Color(0xff6366f1),
                                        const Color(0xff8b5cf6)
                                      ]),
                            borderRadius: BorderRadius.circular(12)),
                        child: Center(
                            child: hasBadge
                                ? Icon(bIcon, color: Colors.white, size: 28)
                                : Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff1a1a1a)))),
                            if (hasBadge)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        bColor,
                                        bColor.withOpacity(0.7)
                                      ]),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(bIcon,
                                            color: Colors.white, size: 13),
                                        const SizedBox(width: 4),
                                        Text(bTitle,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold)),
                                      ])),
                          ]),
                          const SizedBox(height: 3),
                          Text(email,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xff6b7280))),
                          if (roleDisplay.isNotEmpty)
                            Text('Role: $roleDisplay',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xff9ca3af))),
                        ])),
                    Switch(
                        value: hasBadge,
                        activeColor: bColor,
                        onChanged: _isLoading
                            ? null
                            : (_) =>
                                _toggleBadge(doc.id, name, hasBadge, roleData)),
                  ])),
            );
          },
        );
      },
    );
  }

  void _showDebug(List<QueryDocumentSnapshot> allUsers) {
    final roleMap = <String, int>{};
    for (var doc in allUsers) {
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'];
      final roles = data['roles'];
      if (role != null && role.toString().isNotEmpty)
        roleMap[role.toString()] = (roleMap[role.toString()] ?? 0) + 1;
      if (roles is List)
        for (var r in roles)
          roleMap[r.toString()] = (roleMap[r.toString()] ?? 0) + 1;
    }
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Roles in Firestore'),
              content: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: roleMap.isEmpty
                          ? [const Text('No roles found')]
                          : roleMap.entries
                              .map(
                                  (e) => Text('• ${e.key}: ${e.value} user(s)'))
                              .toList())),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'))
              ],
            ));
  }

  String _getRoleName(String r) {
    const m = {
      'accountant': 'accountants',
      'sales': 'sales staff',
      'design': 'designers',
      'staff': 'staff',
      'manager': 'managers',
      'client': 'clients'
    };
    return m[r] ?? r;
  }
}
