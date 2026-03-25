import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/salary_model.dart';
import '../services/salary_service.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen>
    with SingleTickerProviderStateMixin {
  final _salaryService = SalaryService();
  final _db = FirebaseFirestore.instance;
  late TabController _tabController;
  late String _selectedMonth;
  bool _generating = false;

  // Cache user map so we don't re-fetch on every rebuild
  Map<String, Map<String, String>> _userMap = {};
  bool _userMapLoaded = false;

  final List<String> _roles = ['All', 'Staff', 'Manager', 'Admin'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadUserMap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserMap() async {
    final snap = await _db.collection('users').get();
    final map = <String, Map<String, String>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      map[doc.id] = {
        'name': data['name'] ?? 'Employee',
        'role': (data['role'] ?? '').toString().toLowerCase(),
      };
    }
    if (mounted)
      setState(() {
        _userMap = map;
        _userMapLoaded = true;
      });
  }

  Future<void> _generateAll() async {
    setState(() => _generating = true);
    try {
      await _salaryService.generateSalaryForAll(_selectedMonth);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Salary generated for all employees!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Salary Management',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          _MonthPicker(
            selected: _selectedMonth,
            onChanged: (m) => setState(() => _selectedMonth = m),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.black45,
          indicatorColor: const Color(0xFF2196F3),
          tabs: _roles.map((r) => Tab(text: r)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Summary strip
          StreamBuilder<List<SalaryRecord>>(
            stream: _salaryService.getSalaryRecords(_selectedMonth),
            builder: (ctx, snap) {
              final records = snap.data ?? [];
              final totalPayout =
                  records.fold(0.0, (s, r) => s + r.finalSalary);
              final paidCount = records.where((r) => r.isPaid).length;
              return Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _SummaryChip(
                      label: 'Total Payout',
                      value: '₹${totalPayout.toStringAsFixed(0)}',
                      color: const Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 10),
                    _SummaryChip(
                      label: 'Paid',
                      value: '$paidCount/${records.length}',
                      color: Colors.green,
                    ),
                  ],
                ),
              );
            },
          ),
          // Generate button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generating ? null : _generateAll,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome),
                label: Text(_generating
                    ? 'Generating...'
                    : 'Generate Salary for $_selectedMonth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: !_userMapLoaded
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _roles.map((role) {
                      // Fix: use exact lowercase match
                      final filterRole =
                          role == 'All' ? null : role.toLowerCase();
                      return _SalaryList(
                        month: _selectedMonth,
                        roleFilter: filterRole,
                        salaryService: _salaryService,
                        userMap: _userMap,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Salary List ─────────────────────────────────────────────────────────────
class _SalaryList extends StatelessWidget {
  final String month;
  final String? roleFilter;
  final SalaryService salaryService;
  final Map<String, Map<String, String>> userMap;

  const _SalaryList({
    required this.month,
    required this.roleFilter,
    required this.salaryService,
    required this.userMap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SalaryRecord>>(
      stream: salaryService.getSalaryRecords(month),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allRecords = snap.data ?? [];

        final filtered = roleFilter == null
            ? allRecords
            : allRecords.where((r) {
                final role = (userMap[r.uid]?['role'] ?? '').toLowerCase();
                return role ==
                    roleFilter; // exact match: 'accountant' == 'accountant'
              }).toList();

        if (allRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments_outlined,
                    size: 64, color: Colors.black26),
                const SizedBox(height: 12),
                Text('No salary records for $month',
                    style: const TextStyle(color: Colors.black45)),
                const SizedBox(height: 6),
                const Text('Tap "Generate Salary" to create records',
                    style: TextStyle(color: Colors.black38, fontSize: 12)),
              ],
            ),
          );
        }

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No ${roleFilter ?? ''} records for $month',
              style: const TextStyle(color: Colors.black45),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final record = filtered[i];
            final name = userMap[record.uid]?['name'] ?? 'Employee';
            final role = userMap[record.uid]?['role'] ?? '';
            return _SalaryCard(
              record: record,
              name: name,
              role: role,
              salaryService: salaryService,
            );
          },
        );
      },
    );
  }
}

// ─── Salary Card ─────────────────────────────────────────────────────────────
class _SalaryCard extends StatelessWidget {
  final SalaryRecord record;
  final String name;
  final String role;
  final SalaryService salaryService;

  const _SalaryCard({
    required this.record,
    required this.name,
    required this.role,
    required this.salaryService,
  });

  Color get _roleColor {
    switch (role.toLowerCase()) {
      case 'manager':
        return Colors.purple;
      case 'admin':
        return Colors.deepOrange;
      case 'accountant':
        return Colors.teal;
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _EmployeeSalaryHistory(
            uid: record.uid,
            name: name,
            salaryService: salaryService,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3))
          ],
          border: record.isPaid
              ? Border.all(color: Colors.green.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _roleColor.withOpacity(0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'E',
                    style: TextStyle(
                        color: _roleColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(role.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  color: _roleColor,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Text(record.month,
                            style: const TextStyle(
                                color: Colors.black45, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${record.finalSalary.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(height: 4),
                    _PaymentBadge(
                      isPaid: record.isPaid,
                      recordId: record.id,
                      salaryService: salaryService,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCol(
                    label: 'Present',
                    value: record.presentDays.toStringAsFixed(0),
                    color: Colors.green),
                _StatCol(
                    label: 'Absent',
                    value: record.absentDays.toStringAsFixed(1),
                    color: Colors.red),
                _StatCol(
                    label: 'Late',
                    value: record.lateCount.toString(),
                    color: Colors.orange),
                _StatCol(
                    label: 'Half',
                    value: record.halfdayCount.toStringAsFixed(1),
                    color: Colors.amber),
                _StatCol(
                    label: 'P.Leave',
                    value: record.earnedPaidLeaves.toString(),
                    color: Colors.blue),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Base: ₹${record.salaryPerMonth.toStringAsFixed(0)}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black45)),
                Text('Deduction: ₹${record.deductionAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: Colors.red)),
              ],
            ),
            if (record.isPaid && record.paidAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Paid on: ${record.paidAt!.day}/${record.paidAt!.month}/${record.paidAt!.year}',
                style: const TextStyle(fontSize: 11, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Payment Badge ────────────────────────────────────────────────────────────
class _PaymentBadge extends StatelessWidget {
  final bool isPaid;
  final String recordId;
  final SalaryService salaryService;

  const _PaymentBadge(
      {required this.isPaid,
      required this.recordId,
      required this.salaryService});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showToggleDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isPaid
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isPaid
                  ? Colors.green.withOpacity(0.5)
                  : Colors.orange.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPaid ? Icons.check_circle : Icons.pending,
                size: 12, color: isPaid ? Colors.green : Colors.orange),
            const SizedBox(width: 3),
            Text(isPaid ? 'PAID' : 'UNPAID',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green : Colors.orange)),
          ],
        ),
      ),
    );
  }

  void _showToggleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isPaid ? 'Mark as Unpaid?' : 'Mark as Paid?'),
        content: Text(isPaid
            ? 'This will revert the payment status to unpaid.'
            : 'Confirm that salary has been paid to this employee.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (isPaid) {
                await salaryService.markSalaryUnpaid(recordId);
              } else {
                await salaryService.markSalaryPaid(recordId);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      isPaid ? 'Marked as unpaid' : '✅ Salary marked as paid!'),
                  backgroundColor: isPaid ? Colors.orange : Colors.green,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaid ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isPaid ? 'Mark Unpaid' : 'Mark Paid'),
          ),
        ],
      ),
    );
  }
}

// ─── Employee Salary History ──────────────────────────────────────────────────
class _EmployeeSalaryHistory extends StatelessWidget {
  final String uid;
  final String name;
  final SalaryService salaryService;

  const _EmployeeSalaryHistory(
      {required this.uid, required this.name, required this.salaryService});

  String _monthLabel(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final m = int.tryParse(parts[1]) ?? 1;
    return '${names[(m - 1).clamp(0, 11)]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(name,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<List<SalaryRecord>>(
        stream: salaryService.getEmployeeSalaryHistory(uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snap.data ?? [];
          if (records.isEmpty) {
            return const Center(
                child: Text('No salary history',
                    style: TextStyle(color: Colors.black45)));
          }

          final totalPaid = records
              .where((r) => r.isPaid)
              .fold(0.0, (s, r) => s + r.finalSalary);
          final totalPending = records
              .where((r) => !r.isPaid)
              .fold(0.0, (s, r) => s + r.finalSalary);
          final totalDeducted =
              records.fold(0.0, (s, r) => s + r.deductionAmount);

          return Column(
            children: [
              // 3-tile summary
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                        child: _HistorySummaryTile(
                            label: 'Received',
                            amount: totalPaid,
                            color: Colors.green,
                            icon: Icons.check_circle_outline)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _HistorySummaryTile(
                            label: 'Pending',
                            amount: totalPending,
                            color: Colors.orange,
                            icon: Icons.pending_outlined)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _HistorySummaryTile(
                            label: 'Deducted',
                            amount: totalDeducted,
                            color: Colors.red,
                            icon: Icons.remove_circle_outline)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = records[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: r.isPaid
                            ? Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1.5)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF2196F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_monthLabel(r.month),
                                    style: const TextStyle(
                                        color: Color(0xFF2196F3),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                              const Spacer(),
                              _PaymentBadge(
                                  isPaid: r.isPaid,
                                  recordId: r.id,
                                  salaryService: salaryService),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('₹${r.finalSalary.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2196F3))),
                                  Text(
                                      'Base: ₹${r.salaryPerMonth.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: Colors.black45, fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      'Deduction: ₹${r.deductionAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12)),
                                  if (r.isPaid && r.paidAt != null)
                                    Text(
                                      'Paid: ${r.paidAt!.day}/${r.paidAt!.month}/${r.paidAt!.year}',
                                      style: const TextStyle(
                                          color: Colors.green, fontSize: 11),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          // ── Salary breakdown ──────────────────────────
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                _BreakdownRow(
                                  label:
                                      'Present (${r.presentDays.toStringAsFixed(0)} × ₹${r.perDaySalary.toStringAsFixed(0)})',
                                  amount: r.presentSalary,
                                  color: Colors.green,
                                  isPositive: true,
                                ),
                                if (r.halfdayCount > 0)
                                  _BreakdownRow(
                                    label:
                                        'Half Day (${r.halfdayCount.toStringAsFixed(0)} × ₹${(r.perDaySalary / 2).toStringAsFixed(0)})',
                                    amount: r.halfDaySalary,
                                    color: Colors.amber,
                                    isPositive: true,
                                  ),
                                if (r.earnedPaidLeaves > 0)
                                  _BreakdownRow(
                                    label:
                                        'Paid Leave (${r.earnedPaidLeaves} × ₹${r.perDaySalary.toStringAsFixed(0)})',
                                    amount: r.paidLeaveSalary,
                                    color: Colors.blue,
                                    isPositive: true,
                                  ),
                                if (r.absentDays > 0)
                                  _BreakdownRow(
                                    label:
                                        'Absent (${r.absentDays.toStringAsFixed(0)} × ₹${r.perDaySalary.toStringAsFixed(0)})',
                                    amount: r.absentDeduction,
                                    color: Colors.red,
                                    isPositive: false,
                                  ),
                                if (r.lateCount > 0)
                                  _BreakdownRow(
                                    label:
                                        'Late Penalty (${r.lateCount} × ₹${(r.perDaySalary / 2).toStringAsFixed(0)})',
                                    amount: r.latePenalty,
                                    color: Colors.orange,
                                    isPositive: false,
                                  ),
                                if (r.unpaidLeaveDeduction > 0)
                                  _BreakdownRow(
                                    label:
                                        'Unpaid Leave (${r.uncoveredLeaveDays} × ₹${r.perDaySalary.toStringAsFixed(0)})',
                                    amount: r.unpaidLeaveDeduction,
                                    color: Colors.deepOrange,
                                    isPositive: false,
                                  ),
                                const Divider(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Net Salary',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text('₹${r.finalSalary.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            color: Color(0xFF2196F3),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistorySummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _HistorySummaryTile(
      {required this.label,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(color: color.withOpacity(0.8), fontSize: 10)),
                Text('₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCol(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 9)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniStat(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;

  const _MonthPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: DateTime(now.year - 2),
            lastDate: now,
            helpText: 'Select month',
          );
          if (picked != null) {
            onChanged(
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(selected,
              style: const TextStyle(
                  color: Color(0xFF2196F3), fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isPositive;

  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: color)),
          ),
          Text(
            '${isPositive ? '+' : '-'} ₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
