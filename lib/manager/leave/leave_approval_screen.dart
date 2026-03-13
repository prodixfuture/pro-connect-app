import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════
//  COLORS
// ══════════════════════════════════════════════════════════════
class _C {
  static const bg = Color(0xFFF8F9FC);
  static const white = Color(0xFFFFFFFF);
  static const primary = Color(0xFF3B5BDB);
  static const primaryLight = Color(0xFFEEF2FF);
  static const success = Color(0xFF2F9E44);
  static const successLight = Color(0xFFEBFBEE);
  static const danger = Color(0xFFE03131);
  static const dangerLight = Color(0xFFFFF5F5);
  static const warn = Color(0xFFE67700);
  static const warnLight = Color(0xFFFFF9DB);
  static const text1 = Color(0xFF1A1D2E);
  static const text2 = Color(0xFF6B7280);
  static const border = Color(0xFFE8EAF0);
  static const cardShadow = Color(0x0A000000);
  static const purple = Color(0xFF7C3AED);
  static const purpleLight = Color(0xFFF5F3FF);
}

// ══════════════════════════════════════════════════════════════
//  ENTRY — routes by role
// ══════════════════════════════════════════════════════════════
class LeaveApprovalScreen extends StatelessWidget {
  const LeaveApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _C.bg,
            body: Center(child: CircularProgressIndicator(color: _C.primary)),
          );
        }

        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
        final role = (data['role'] as String? ?? '').toLowerCase();
        final dept = data['department'] as String? ?? '';

        if (role == 'admin') {
          return const _LeaveRoot(isAdmin: true, department: '');
        } else if (role == 'manager') {
          return _LeaveRoot(isAdmin: false, department: dept);
        }
        return const Scaffold(body: Center(child: Text('Access Denied')));
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ROOT
// ══════════════════════════════════════════════════════════════
class _LeaveRoot extends StatefulWidget {
  final bool isAdmin;
  final String department;
  const _LeaveRoot({required this.isAdmin, required this.department});

  @override
  State<_LeaveRoot> createState() => _LeaveRootState();
}

class _LeaveRootState extends State<_LeaveRoot>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _selectedStaffUid;
  String? _selectedDept;

  static const _statuses = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // Simple query – only filter by status to avoid composite index requirement
  Stream<QuerySnapshot> _stream(String status) => FirebaseFirestore.instance
      .collection('leaves')
      .where('status', isEqualTo: status)
      .snapshots();

  // Client-side filtering for dept + staff
  List<QueryDocumentSnapshot> _filter(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final docDept = d['department'] as String? ?? '';
      final docUid = d['uid'] as String? ?? '';

      if (!widget.isAdmin) {
        if (docDept != widget.department) return false;
      } else if (_selectedDept != null && _selectedDept!.isNotEmpty) {
        if (docDept != _selectedDept) return false;
      }

      if (_selectedStaffUid != null && _selectedStaffUid!.isNotEmpty) {
        if (docUid != _selectedStaffUid) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final ta = (a.data() as Map)['createdAt'];
        final tb = (b.data() as Map)['createdAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        return 0;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(),
          _FilterBar(
            isAdmin: widget.isAdmin,
            department: widget.department,
            selectedStaffUid: _selectedStaffUid,
            selectedDept: _selectedDept,
            onStaffChanged: (uid) => setState(() => _selectedStaffUid = uid),
            onDeptChanged: (dept) => setState(() {
              _selectedDept = dept;
              _selectedStaffUid = null;
            }),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: _statuses.map((status) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _stream(status),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: _C.primary));
                    }
                    if (snap.hasError) {
                      return _ErrorCard(msg: snap.error.toString());
                    }
                    final filtered = _filter(snap.data?.docs ?? []);
                    if (filtered.isEmpty) return _EmptyState(status: status);

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final doc = filtered[i];
                        final data = doc.data() as Map<String, dynamic>;
                        return _LeaveCard(
                          docId: doc.id,
                          data: data,
                          status: status,
                          onTap: () => _openDetail(ctx, doc.id, data, status),
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: _C.white,
      child: Column(
        children: [
          SizedBox(height: top + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.event_note_rounded,
                      color: _C.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Leave Requests',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _C.text1,
                              letterSpacing: -0.3)),
                      Text(
                        widget.isAdmin
                            ? 'Admin · All Departments'
                            : widget.department,
                        style: const TextStyle(fontSize: 12, color: _C.text2),
                      ),
                    ],
                  ),
                ),
                if (widget.isAdmin)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.purpleLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Admin',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _C.purple)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tab,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 2.5, color: _C.primary),
              insets: EdgeInsets.symmetric(horizontal: 24),
            ),
            labelColor: _C.primary,
            unselectedLabelColor: _C.text2,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
          Container(height: 1, color: _C.border),
        ],
      ),
    );
  }

  void _openDetail(
      BuildContext ctx, String id, Map<String, dynamic> data, String status) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(docId: id, data: data, status: status),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FILTER BAR
// ══════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final bool isAdmin;
  final String department;
  final String? selectedStaffUid;
  final String? selectedDept;
  final ValueChanged<String?> onStaffChanged;
  final ValueChanged<String?> onDeptChanged;

  const _FilterBar({
    required this.isAdmin,
    required this.department,
    required this.selectedStaffUid,
    required this.selectedDept,
    required this.onStaffChanged,
    required this.onDeptChanged,
  });

  Stream<QuerySnapshot> get _staffStream {
    Query q = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'staff');
    if (!isAdmin && department.isNotEmpty) {
      q = q.where('department', isEqualTo: department);
    }
    return q.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: StreamBuilder<QuerySnapshot>(
        stream: _staffStream,
        builder: (_, snap) {
          final staffDocs = snap.data?.docs ?? [];
          final depts = <String>{};
          if (isAdmin) {
            for (final s in staffDocs) {
              final d =
                  (s.data() as Map<String, dynamic>)['department'] as String?;
              if (d != null && d.isNotEmpty) depts.add(d);
            }
          }

          final visibleStaff = staffDocs.where((s) {
            if (!isAdmin || selectedDept == null || selectedDept!.isEmpty)
              return true;
            return (s.data() as Map<String, dynamic>)['department'] ==
                selectedDept;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dept chips (admin only)
              if (isAdmin && depts.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                          label: 'All Depts',
                          active: selectedDept == null,
                          color: _C.purple,
                          onTap: () => onDeptChanged(null)),
                      ...depts.map((d) => _Chip(
                            label: d,
                            active: selectedDept == d,
                            color: _C.purple,
                            onTap: () => onDeptChanged(d),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // Staff chips
              if (visibleStaff.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                          label: 'All Staff',
                          active: selectedStaffUid == null,
                          color: _C.primary,
                          onTap: () => onStaffChanged(null)),
                      ...visibleStaff.map((s) {
                        final d = s.data() as Map<String, dynamic>;
                        final name = d['name'] as String? ??
                            d['staffName'] as String? ??
                            s.id;
                        return _Chip(
                          label: name,
                          active: selectedStaffUid == s.id,
                          color: _C.primary,
                          onTap: () => onStaffChanged(s.id),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.active,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : color.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LEAVE CARD
// ══════════════════════════════════════════════════════════════
class _LeaveCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String status;
  final VoidCallback onTap;

  const _LeaveCard({
    required this.docId,
    required this.data,
    required this.status,
    required this.onTap,
  });

  Future<void> _update(String s) async {
    await FirebaseFirestore.instance.collection('leaves').doc(docId).update({
      'status': s,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final name =
        data['staffName'] as String? ?? data['name'] as String? ?? 'Unknown';
    final reason = data['reason'] as String? ?? '—';
    final dept = data['department'] as String? ?? '';
    final leaveType =
        data['leaveType'] as String? ?? data['type'] as String? ?? 'Leave';
    final fromTs = data['fromDate'] ?? data['startDate'];
    final toTs = data['toDate'] ?? data['endDate'];

    String fmtShort(dynamic ts) {
      if (ts is Timestamp) return DateFormat('dd MMM').format(ts.toDate());
      return '—';
    }

    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    Color stColor, stBg;
    IconData stIcon;
    String stLabel;
    switch (status) {
      case 'approved':
        stColor = _C.success;
        stBg = _C.successLight;
        stIcon = Icons.check_circle_outline_rounded;
        stLabel = 'Approved';
        break;
      case 'rejected':
        stColor = _C.danger;
        stBg = _C.dangerLight;
        stIcon = Icons.cancel_outlined;
        stLabel = 'Rejected';
        break;
      default:
        stColor = _C.warn;
        stBg = _C.warnLight;
        stIcon = Icons.hourglass_top_rounded;
        stLabel = 'Pending';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        decoration: BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
          boxShadow: const [
            BoxShadow(
                color: _C.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            // Top
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _C.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                          color: _C.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _C.text1)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (dept.isNotEmpty) ...[
                              const Icon(Icons.business_rounded,
                                  size: 11, color: _C.text2),
                              const SizedBox(width: 3),
                              Text(dept,
                                  style: const TextStyle(
                                      fontSize: 11, color: _C.text2)),
                              const SizedBox(width: 8),
                            ],
                            const Icon(Icons.label_outline,
                                size: 11, color: _C.text2),
                            const SizedBox(width: 3),
                            Text(leaveType,
                                style: const TextStyle(
                                    fontSize: 11, color: _C.text2)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: stBg, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stIcon, size: 11, color: stColor),
                        const SizedBox(width: 4),
                        Text(stLabel,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: stColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: _C.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded,
                      size: 13, color: _C.text2),
                  const SizedBox(width: 5),
                  Text(
                    '${fmtShort(fromTs)} → ${fmtShort(toTs)}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _C.text2,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _C.text2)),
                  ),
                  if (status == 'pending') ...[
                    _IconBtn(
                        icon: Icons.check_rounded,
                        color: _C.success,
                        bg: _C.successLight,
                        onTap: () => _update('approved')),
                    const SizedBox(width: 8),
                    _IconBtn(
                        icon: Icons.close_rounded,
                        color: _C.danger,
                        bg: _C.dangerLight,
                        onTap: () => _update('rejected')),
                  ] else
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: _C.text2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon,
      required this.color,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 17),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  DETAIL SHEET
// ══════════════════════════════════════════════════════════════
class _DetailSheet extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String status;
  const _DetailSheet(
      {required this.docId, required this.data, required this.status});

  Future<void> _update(String s) async {
    await FirebaseFirestore.instance.collection('leaves').doc(docId).update({
      'status': s,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _fmt(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate());
    }
    return '—';
  }

  String _fmtDate(dynamic ts) {
    if (ts is Timestamp) return DateFormat('dd MMM yyyy').format(ts.toDate());
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final name =
        data['staffName'] as String? ?? data['name'] as String? ?? 'Unknown';
    final reason = data['reason'] as String? ?? '—';
    final dept = data['department'] as String? ?? '—';
    final leaveType =
        data['leaveType'] as String? ?? data['type'] as String? ?? 'Leave';
    final fromTs = data['fromDate'] ?? data['startDate'];
    final toTs = data['toDate'] ?? data['endDate'];

    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    Color stColor, stBg;
    IconData stIcon;
    String stLabel;
    switch (status) {
      case 'approved':
        stColor = _C.success;
        stBg = _C.successLight;
        stIcon = Icons.check_circle_outline_rounded;
        stLabel = 'Approved';
        break;
      case 'rejected':
        stColor = _C.danger;
        stBg = _C.dangerLight;
        stIcon = Icons.cancel_outlined;
        stLabel = 'Rejected';
        break;
      default:
        stColor = _C.warn;
        stBg = _C.warnLight;
        stIcon = Icons.hourglass_top_rounded;
        stLabel = 'Pending';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _C.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: _C.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                          color: _C.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _C.text1)),
                      Text(dept,
                          style:
                              const TextStyle(fontSize: 12, color: _C.text2)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: stBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(stIcon, size: 12, color: stColor),
                      const SizedBox(width: 5),
                      Text(stLabel,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: stColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Info grid
            Container(
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.border),
              ),
              child: Column(
                children: [
                  _Row(
                      icon: Icons.label_rounded,
                      label: 'Leave Type',
                      value: leaveType),
                  Container(
                      height: 1,
                      color: _C.border,
                      margin: const EdgeInsets.symmetric(horizontal: 14)),
                  _Row(
                      icon: Icons.calendar_today_rounded,
                      label: 'From',
                      value: _fmtDate(fromTs)),
                  Container(
                      height: 1,
                      color: _C.border,
                      margin: const EdgeInsets.symmetric(horizontal: 14)),
                  _Row(
                      icon: Icons.event_rounded,
                      label: 'To',
                      value: _fmtDate(toTs)),
                  Container(
                      height: 1,
                      color: _C.border,
                      margin: const EdgeInsets.symmetric(horizontal: 14)),
                  _Row(
                      icon: Icons.schedule_rounded,
                      label: 'Applied On',
                      value: _fmt(data['createdAt'])),
                  if (status != 'pending') ...[
                    Container(
                        height: 1,
                        color: _C.border,
                        margin: const EdgeInsets.symmetric(horizontal: 14)),
                    _Row(
                        icon: Icons.update_rounded,
                        label: 'Updated On',
                        value: _fmt(data['updatedAt'])),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Reason',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.text2)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: Text(reason,
                  style: const TextStyle(
                      fontSize: 14, color: _C.text1, height: 1.6)),
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _BigBtn(
                      label: 'Approve',
                      icon: Icons.check_rounded,
                      color: _C.success,
                      bg: _C.successLight,
                      onTap: () {
                        Navigator.pop(context);
                        _update('approved');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigBtn(
                      label: 'Reject',
                      icon: Icons.close_rounded,
                      color: _C.danger,
                      bg: _C.dangerLight,
                      onTap: () {
                        Navigator.pop(context);
                        _update('rejected');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 15, color: _C.primary),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13, color: _C.text2)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.text1)),
          ],
        ),
      );
}

class _BigBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _BigBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final String status;
  const _EmptyState({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData ic;
    String msg, sub;
    switch (status) {
      case 'approved':
        ic = Icons.check_circle_outline_rounded;
        msg = 'No approved leaves';
        sub = 'Approved requests appear here';
        break;
      case 'rejected':
        ic = Icons.cancel_outlined;
        msg = 'No rejected leaves';
        sub = 'Rejected requests appear here';
        break;
      default:
        ic = Icons.inbox_outlined;
        msg = 'No pending requests';
        sub = 'New leave requests appear here';
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _C.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(ic, size: 34, color: _C.primary),
          ),
          const SizedBox(height: 16),
          Text(msg,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _C.text1)),
          const SizedBox(height: 6),
          Text(sub, style: const TextStyle(fontSize: 13, color: _C.text2)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ERROR CARD
// ══════════════════════════════════════════════════════════════
class _ErrorCard extends StatelessWidget {
  final String msg;
  const _ErrorCard({required this.msg});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.dangerLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.danger.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: _C.danger, size: 32),
                const SizedBox(height: 8),
                const Text('Failed to load',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _C.danger)),
                const SizedBox(height: 4),
                Text(msg,
                    style: const TextStyle(fontSize: 12, color: _C.text2),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}
