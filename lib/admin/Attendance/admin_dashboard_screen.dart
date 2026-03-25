import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  String _searchQuery = '';
  DateTime _selectedMonth = DateTime.now();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getTodayDate() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staff Attendance',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D1F),
                    letterSpacing: -0.5)),
            Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6F767E))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _isExporting
                  ? const Color(0xFFF3F4F6)
                  : const Color(0xFF4F46E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _isExporting ? null : _exportToExcel,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF6F767E)))
                  : const Icon(Icons.download_rounded,
                      size: 22, color: Colors.white),
              tooltip: 'Export Excel',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              children: [
                // Modern Tab Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    indicatorPadding: EdgeInsets.zero,
                    labelColor: const Color(0xFF4F46E5),
                    unselectedLabelColor: const Color(0xFF6F767E),
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                    dividerColor: Colors.transparent,
                    onTap: (index) => setState(() {}),
                    tabs: const [Tab(text: 'Today'), Tab(text: 'Previous')],
                  ),
                ),

                if (_tabController.index == 1) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMMM yyyy').format(_selectedMonth),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D1F))),
                      Row(
                        children: [
                          _buildMonthButton(Icons.chevron_left_rounded, () {
                            setState(() => _selectedMonth = DateTime(
                                _selectedMonth.year, _selectedMonth.month - 1));
                          }),
                          const SizedBox(width: 8),
                          _buildMonthButton(Icons.chevron_right_rounded, () {
                            setState(() => _selectedMonth = DateTime(
                                _selectedMonth.year, _selectedMonth.month + 1));
                          }),
                        ],
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Statistics
                if (_tabController.index == 0)
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('attendance')
                        .where('date', isEqualTo: _getTodayDate())
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      int present = 0, absent = 0, late = 0, leave = 0;

                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'absent';

                        if (status == 'on_time' || status == 'working') {
                          present++;
                        } else if (status == 'late') {
                          late++;
                        } else if (status == 'leave') {
                          leave++;
                        } else {
                          absent++;
                        }
                      }

                      return Row(
                        children: [
                          _StatCard(
                              value: '$present',
                              label: 'Present',
                              gradient: [
                                const Color(0xFF10B981),
                                const Color(0xFF059669)
                              ]),
                          const SizedBox(width: 12),
                          _StatCard(
                              value: '$absent',
                              label: 'Absent',
                              gradient: [
                                const Color(0xFFEF4444),
                                const Color(0xFFDC2626)
                              ]),
                          const SizedBox(width: 12),
                          _StatCard(value: '$late', label: 'Late', gradient: [
                            const Color(0xFFF59E0B),
                            const Color(0xFFD97706)
                          ]),
                          const SizedBox(width: 12),
                          _StatCard(value: '$leave', label: 'Leave', gradient: [
                            const Color(0xFF3B82F6),
                            const Color(0xFF2563EB)
                          ]),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // Search Bar
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1D1F)),
                    decoration: const InputDecoration(
                      hintText: 'Search Staff',
                      hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Color(0xFF6F767E), size: 22),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').where('role',
                  whereIn: ['staff', 'manager', 'admin']).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF4F46E5)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No staff found'));
                }

                var staffList = snapshot.data!.docs;

                if (_searchQuery.isNotEmpty) {
                  staffList = staffList.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final empId =
                        (data['employeeId'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) ||
                        empId.contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staffDoc = staffList[index];
                    final staffData = staffDoc.data() as Map<String, dynamic>;

                    return _ModernStaffCard(
                      uid: staffDoc.id,
                      name: staffData['name'] ?? 'Unknown',
                      empId: staffData['employeeId'] ?? 'N/A',
                      department: staffData['department'] ?? 'N/A',
                      designation: staffData['designation'] ??
                          staffData['role'] ??
                          'Staff',
                      role: staffData['role'] ?? 'staff',
                      photoUrl: staffData['photoUrl'],
                      isToday: _tabController.index == 0,
                      onTap: () =>
                          _showStaffHistory(context, staffDoc.id, staffData),
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

  Widget _buildMonthButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1A1D1F)),
      ),
    );
  }

  void _showStaffHistory(
      BuildContext context, String uid, Map<String, dynamic> staffData) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                StaffHistoryScreen(uid: uid, staffData: staffData)));
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Attendance'];

      sheet.appendRow([
        TextCellValue('Staff Name'),
        TextCellValue('Employee ID'),
        TextCellValue('Department'),
        TextCellValue('Role'),
        TextCellValue('Date'),
        TextCellValue('Punch In'),
        TextCellValue('Punch Out'),
        TextCellValue('Status'),
      ]);

      String startDate, endDate;
      if (_tabController.index == 0) {
        startDate = endDate = _getTodayDate();
      } else {
        startDate = DateFormat('yyyy-MM-01').format(_selectedMonth);
        endDate = DateFormat('yyyy-MM-dd')
            .format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));
      }

      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['staff', 'manager', 'admin']).get();

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final uid = userDoc.id;

        final attendanceSnapshot = await _firestore
            .collection('attendance')
            .where('uid', isEqualTo: uid)
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThanOrEqualTo: endDate)
            .orderBy('date')
            .get();

        for (var doc in attendanceSnapshot.docs) {
          final data = doc.data();
          final punchIn = data['punchIn'] != null
              ? DateFormat('hh:mm a')
                  .format((data['punchIn'] as Timestamp).toDate())
              : '-';
          final punchOut = data['punchOut'] != null
              ? DateFormat('hh:mm a')
                  .format((data['punchOut'] as Timestamp).toDate())
              : '-';

          sheet.appendRow([
            TextCellValue(userData['name'] ?? ''),
            TextCellValue(userData['employeeId'] ?? ''),
            TextCellValue(userData['department'] ?? ''),
            TextCellValue(userData['role'] ?? ''),
            TextCellValue(data['date'] ?? ''),
            TextCellValue(punchIn),
            TextCellValue(punchOut),
            TextCellValue(data['status'] ?? ''),
          ]);
        }
      }

      final bytes = excel.encode();
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'Attendance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes!);

      await Share.shareXFiles([XFile(file.path)], subject: 'Attendance Report');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Excel exported successfully ✓'),
              backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final List<Color> gradient;

  const _StatCard(
      {required this.value, required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -1)),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ModernStaffCard extends StatelessWidget {
  final String uid, name, empId, department, designation, role;
  final String? photoUrl;
  final bool isToday;
  final VoidCallback onTap;

  const _ModernStaffCard({
    required this.uid,
    required this.name,
    required this.empId,
    required this.department,
    required this.designation,
    required this.role,
    this.photoUrl,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateToCheck = isToday ? _getTodayDate() : null;

    return StreamBuilder<QuerySnapshot>(
      stream: dateToCheck != null
          ? FirebaseFirestore.instance
              .collection('attendance')
              .where('uid', isEqualTo: uid)
              .where('date', isEqualTo: dateToCheck)
              .limit(1)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        String? punchIn, punchOut;
        String status = 'absent';
        bool hasCheckedIn = false;
        bool hasCompleted = false;

        if (isToday && snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

          if (data['punchIn'] != null) {
            punchIn = DateFormat('hh:mm a')
                .format((data['punchIn'] as Timestamp).toDate());
            hasCheckedIn = true;
          }

          if (data['punchOut'] != null) {
            punchOut = DateFormat('hh:mm a')
                .format((data['punchOut'] as Timestamp).toDate());
            hasCompleted = true;
          }

          status = data['status'] ?? 'absent';
        }

        final shouldShowButtons =
            isToday && !hasCompleted && status != 'absent' && status != 'leave';

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Status + Photo
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: _getStatusGradient(status)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(_getStatusLetter(status),
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ),
                          ),
                          if (isToday && hasCompleted)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.check,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(name,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1D1F),
                                          letterSpacing: -0.3)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(role).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(role.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: _getRoleColor(role),
                                          letterSpacing: 0.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('$empId | $designation',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6F767E))),
                            Text('Dept: $department',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9CA3AF))),
                            if (isToday) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _TimeChip(label: 'In', time: punchIn ?? '--'),
                                  const SizedBox(width: 8),
                                  _TimeChip(
                                      label: 'Out', time: punchOut ?? '--'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                if (isToday) ...[
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (!hasCheckedIn && !hasCompleted) ...[
                          _ActionButton(
                              label: 'Absent',
                              color: const Color(0xFFEF4444),
                              onTap: () => _showConfirmation(
                                  context, uid, 'absent', 'Absent')),
                          const SizedBox(width: 10),
                          _ActionButton(
                              label: 'Leave',
                              color: const Color(0xFF3B82F6),
                              onTap: () => _showConfirmation(
                                  context, uid, 'leave', 'Leave')),
                          const SizedBox(width: 10),
                          _ActionButton(
                              label: 'Check In',
                              color: const Color(0xFF10B981),
                              onTap: () => _showConfirmation(
                                  context, uid, 'checkin', 'Check In')),
                        ],
                        if (shouldShowButtons) ...[
                          _ActionButton(
                              label: 'Check Out',
                              color: const Color(0xFFF59E0B),
                              onTap: () => _showConfirmation(
                                  context, uid, 'checkout', 'Check Out')),
                          const SizedBox(width: 10),
                          _ActionButton(
                              label: 'Overtime',
                              color: const Color(0xFF8B5CF6),
                              onTap: () => _showConfirmation(
                                  context, uid, 'overtime', 'Overtime')),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTodayDate() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'on_time':
      case 'working':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'late':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'leave':
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      default:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return const Color(0xFF8B5CF6);
      case 'admin':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _getStatusLetter(String status) {
    switch (status) {
      case 'on_time':
      case 'working':
        return 'P';
      case 'late':
        return 'L';
      case 'leave':
        return 'L';
      default:
        return 'A';
    }
  }

  void _showConfirmation(
      BuildContext context, String uid, String action, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getActionColor(action).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getActionIcon(action),
                  color: _getActionColor(action), size: 24),
            ),
            const SizedBox(width: 12),
            Text('Confirm $label',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text('Are you sure you want to mark $name as $label?',
            style: const TextStyle(fontSize: 15, color: Color(0xFF6F767E))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F767E))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeAction(context, uid, action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getActionColor(action),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'absent':
        return const Color(0xFFEF4444);
      case 'leave':
        return const Color(0xFF3B82F6);
      case 'checkin':
        return const Color(0xFF10B981);
      case 'checkout':
        return const Color(0xFFF59E0B);
      case 'overtime':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6F767E);
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'absent':
        return Icons.block_rounded;
      case 'leave':
        return Icons.beach_access_rounded;
      case 'checkin':
        return Icons.login_rounded;
      case 'checkout':
        return Icons.logout_rounded;
      case 'overtime':
        return Icons.access_time_filled_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  Future<void> _executeAction(
      BuildContext context, String uid, String action) async {
    try {
      final date = _getTodayDate();

      if (action == 'absent' || action == 'leave') {
        await FirebaseFirestore.instance
            .collection('attendance')
            .doc('${uid}_$date')
            .set({
          'uid': uid,
          'date': date,
          'status': action == 'absent' ? 'absent' : 'leave',
          'punchIn': null,
          'punchOut': null,
          'duration': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else if (action == 'checkin') {
        await FirebaseFirestore.instance
            .collection('attendance')
            .doc('${uid}_$date')
            .set({
          'uid': uid,
          'date': date,
          'punchIn': Timestamp.now(),
          'punchOut': null,
          'status': 'on_time',
          'duration': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else if (action == 'checkout') {
        await FirebaseFirestore.instance
            .collection('attendance')
            .doc('${uid}_$date')
            .update({
          'punchOut': Timestamp.now(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else if (action == 'overtime') {
        await FirebaseFirestore.instance
            .collection('attendance')
            .doc('${uid}_$date')
            .update({
          'status': 'overtime',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$name marked successfully ✓'),
            backgroundColor: const Color(0xFF10B981)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }
}

class _TimeChip extends StatelessWidget {
  final String label, time;

  const _TimeChip({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6F767E))),
          Text(time,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D1F))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }
}

// Placeholder for Staff History Screen
class StaffHistoryScreen extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> staffData;

  const StaffHistoryScreen(
      {Key? key, required this.uid, required this.staffData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(staffData['name'] ?? 'History')),
      body: const Center(child: Text('Staff History Screen')),
    );
  }
}
