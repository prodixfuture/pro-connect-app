import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_user_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;
  String _search = '';

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'All', 'role': null, 'color': Colors.blueGrey},
    {'label': 'Staff', 'role': 'staff', 'color': Color(0xFF2196F3)},
    {'label': 'Manager', 'role': 'manager', 'color': Colors.purple},
    {'label': 'Admin', 'role': 'admin', 'color': Colors.deepOrange},
    {'label': 'Accountant', 'role': 'accountant', 'color': Colors.teal},
    {'label': 'Client', 'role': 'client', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _activeColor => _tabs[_tabController.index]['color'] as Color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Employees',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: _activeColor,
                unselectedLabelColor: Colors.black38,
                indicatorColor: _activeColor,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs:
                    _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateUserScreen()),
        ),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add User'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return _UserTab(
            roleFilter: tab['role'] as String?,
            roleColor: tab['color'] as Color,
            search: _search,
            db: _db,
          );
        }).toList(),
      ),
    );
  }
}

// ─── Per-tab user list ────────────────────────────────────────────────────────
class _UserTab extends StatelessWidget {
  final String? roleFilter;
  final Color roleColor;
  final String search;
  final FirebaseFirestore db;

  const _UserTab({
    required this.roleFilter,
    required this.roleColor,
    required this.search,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    Query query = db.collection('users');
    if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snap.data?.docs ?? [];

        // Client-side search filter
        if (search.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(search) || email.contains(search);
          }).toList();
        }

        // Sort: active first, then by name
        docs.sort((a, b) {
          final da = a.data() as Map<String, dynamic>;
          final db2 = b.data() as Map<String, dynamic>;
          final statusA = da['status'] == 'active' ? 0 : 1;
          final statusB = db2['status'] == 'active' ? 0 : 1;
          if (statusA != statusB) return statusA - statusB;
          return (da['name'] ?? '').compareTo(db2['name'] ?? '');
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outline,
                  size: 64, color: roleColor.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                search.isNotEmpty
                    ? 'No results for "$search"'
                    : 'No ${roleFilter ?? 'users'} found',
                style: const TextStyle(color: Colors.black45),
              ),
            ]),
          );
        }

        // Count summary
        final activeCount =
            docs.where((d) => (d.data() as Map)['status'] == 'active').length;

        return Column(
          children: [
            // Summary strip
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                _CountChip(
                    label: 'Total', count: docs.length, color: roleColor),
                const SizedBox(width: 8),
                _CountChip(
                    label: 'Active', count: activeCount, color: Colors.green),
                const SizedBox(width: 8),
                _CountChip(
                    label: 'Inactive',
                    count: docs.length - activeCount,
                    color: Colors.red),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  return _UserCard(
                    uid: doc.id,
                    data: data,
                    roleColor: roleColor,
                    db: db,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final Color roleColor;
  final FirebaseFirestore db;

  const _UserCard({
    required this.uid,
    required this.data,
    required this.roleColor,
    required this.db,
  });

  bool get _isActive => data['status'] == 'active';
  String get _name => data['name'] ?? 'Unknown';
  String get _role => (data['role'] ?? '').toString();

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return Colors.purple;
      case 'admin':
        return Colors.deepOrange;
      case 'accountant':
        return Colors.teal;
      case 'client':
        return Colors.green;
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(_role);
    final salary = data['salaryPerMonth'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))
        ],
        border:
            _isActive ? null : Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: color.withOpacity(0.15),
                      child: Text(
                        _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isActive ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
                      Row(children: [
                        Expanded(
                          child: Text(_name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _isActive
                                      ? Colors.black87
                                      : Colors.black38)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_role.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  color: color,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(data['email'] ?? '',
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 12)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.business_outlined,
                            size: 11, color: Colors.black38),
                        const SizedBox(width: 3),
                        Text(data['department'] ?? '',
                            style: const TextStyle(
                                color: Colors.black38, fontSize: 11)),
                        if (salary != null && _role != 'client') ...[
                          const SizedBox(width: 10),
                          Icon(Icons.currency_rupee,
                              size: 11, color: Colors.black38),
                          Text(salary.toStringAsFixed(0),
                              style: const TextStyle(
                                  color: Colors.black38, fontSize: 11)),
                          const Text('/mo',
                              style: TextStyle(
                                  color: Colors.black26, fontSize: 10)),
                        ],
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(children: [
              _ActionBtn(
                icon: Icons.edit_outlined,
                label: 'Edit',
                color: const Color(0xFF2196F3),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditUserScreen(uid: uid, userData: data),
                  ),
                ),
              ),
              _Divider(),
              _ActionBtn(
                icon: _isActive
                    ? Icons.block_outlined
                    : Icons.check_circle_outline,
                label: _isActive ? 'Deactivate' : 'Activate',
                color: _isActive ? Colors.orange : Colors.green,
                onTap: () => _toggleStatus(context),
              ),
              _Divider(),
              _ActionBtn(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: Colors.red,
                onTap: () => _confirmDelete(context),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context) async {
    final newStatus = _isActive ? 'inactive' : 'active';
    final label = _isActive ? 'deactivate' : 'activate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${label[0].toUpperCase()}${label.substring(1)} user?'),
        content: Text('Are you sure you want to $label $_name?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(label[0].toUpperCase() + label.substring(1)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.collection('users').doc(uid).update({'status': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '$_name ${newStatus == 'active' ? 'activated' : 'deactivated'}'),
          backgroundColor: newStatus == 'active' ? Colors.green : Colors.orange,
        ));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User?', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to delete $_name.'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'This will delete the Firestore record. Auth account must be removed separately from Firebase Console.',
                    style: TextStyle(fontSize: 11, color: Colors.red),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.collection('users').doc(uid).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_name deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 20, color: Colors.black12);
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        const SizedBox(width: 5),
        Text('$count',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
      ]),
    );
  }
}
