import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pro_connect/staff/accounts/accountant_expense_screen.dart';
import '../../../staff/common/notification_screen.dart';
import '../services/accounts_service.dart';

import 'salary_screen.dart';
import 'income_expense_screen.dart';
import 'invoice_screen.dart';
import 'reports_screen.dart';

class AccountsDashboard extends StatefulWidget {
  const AccountsDashboard({super.key});

  @override
  State<AccountsDashboard> createState() => _AccountsDashboardState();
}

class _AccountsDashboardState extends State<AccountsDashboard> {
  final AccountsService _accountsService = AccountsService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final String _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Redesigned Card Header ─────────────────────────────────
          SliverToBoxAdapter(
            child: _AccountsHeaderCard(
              userId: _userId,
              accountsService: _accountsService,
              month: _month,
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Overview + Report icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel(label: "Today's Overview"),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ReportsScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00897B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bar_chart_rounded,
                              color: Color(0xFF00897B), size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(children: [
                    Expanded(
                        child: _TodayCard(
                      label: 'Income',
                      color: const Color(0xFF4CAF50),
                      icon: Icons.trending_up,
                      stream: _accountsService
                          .getTodayIncome()
                          .map((l) => _accountsService.sumAmounts(l)),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _TodayCard(
                      label: 'Expense',
                      color: const Color(0xFFF44336),
                      icon: Icons.trending_down,
                      stream: _accountsService
                          .getTodayExpense()
                          .map((l) => _accountsService.sumAmounts(l)),
                    )),
                  ]),

                  const SizedBox(height: 12),
                  _MonthlyProfitCard(
                      accountsService: _accountsService, month: _month),

                  const SizedBox(height: 20),
                  const _SectionLabel(label: 'Quick Actions'),
                  const SizedBox(height: 10),

                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    children: [
                      _ActionCard(
                        label: 'Salary',
                        icon: Icons.payments_outlined,
                        color: const Color(0xFF2196F3),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => SalaryScreen())),
                      ),
                      _ActionCard(
                        label: 'Income & Expense',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF4CAF50),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => IncomeExpenseScreen())),
                      ),
                      _ActionCard(
                        label: 'Invoices',
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFFFF9800),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => InvoiceScreen())),
                      ),
                      _ActionCard(
                        label: 'Expense Request',
                        icon: Icons.insert_chart_outlined,
                        color: const Color(0xFF9C27B0),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AccountantExpenseScreen())),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _UnpaidInvoicesBanner(accountsService: _accountsService),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REDESIGNED HEADER CARD — matches new client dashboard style
// ─────────────────────────────────────────────────────────────────────────────
class _AccountsHeaderCard extends StatelessWidget {
  final String userId;
  final AccountsService accountsService;
  final String month;

  const _AccountsHeaderCard({
    required this.userId,
    required this.accountsService,
    required this.month,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _greetingEmoji() {
    final h = DateTime.now().hour;
    if (h < 12) return '🌅';
    if (h < 17) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (_, userSnap) {
        final data = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final name = (data['name'] ?? 'Accountant').toString();
        // Support both field naming conventions from admin panel
        final badgeEnabled =
            data['badgeEnabled'] == true || data['hasPremiumBadge'] == true;
        final badgeLabel =
            (data['badgeLabel'] ?? data['badgeTitle'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 52, 16, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF00796B), Color(0xFF00897B), Color(0xFF26A69A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00897B).withOpacity(0.45),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top row: date pill + badge + bell ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Badge + notification bell
                        Row(
                          children: [
                            if (badgeEnabled && badgeLabel.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white38),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      badgeLabel.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            _NotificationBell(userId: userId),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Greeting + name + avatar ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(_greetingEmoji(),
                                      style: const TextStyle(fontSize: 15)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _greeting(),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Avatar with initial
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // ── Monthly stats row ──
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: accountsService.getMonthlyIncome(month),
                      builder: (_, incSnap) =>
                          StreamBuilder<List<Map<String, dynamic>>>(
                        stream: accountsService.getMonthlyExpense(month),
                        builder: (_, expSnap) {
                          final income =
                              accountsService.sumAmounts(incSnap.data ?? []);
                          final expense =
                              accountsService.sumAmounts(expSnap.data ?? []);
                          final profit = income - expense;
                          final rate = income > 0
                              ? ((profit / income) * 100).clamp(0, 100)
                              : 0.0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(children: [
                              _StatItem(
                                  'Income',
                                  '₹${income.toStringAsFixed(0)}',
                                  Icons.arrow_upward_rounded),
                              _StatItem(
                                  'Expense',
                                  '₹${expense.toStringAsFixed(0)}',
                                  Icons.arrow_downward_rounded),
                              _StatItem(
                                  'Profit Rate',
                                  '${rate.toStringAsFixed(0)}%',
                                  Icons.trending_up_rounded),
                            ]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stat item ─────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      );
}

// ── Notification Bell ─────────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  final String userId;
  const _NotificationBell({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (_, snap) {
        final count = snap.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationScreen())),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.notifications_rounded,
                  color: Colors.white, size: 22),
            ),
            if (count > 0)
              Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text('$count',
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  )),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unchanged widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          letterSpacing: 0.5));
}

class _TodayCard extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final Stream<double> stream;
  const _TodayCard(
      {required this.label,
      required this.color,
      required this.icon,
      required this.stream});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18)),
            const Spacer(),
          ]),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          StreamBuilder<double>(
            stream: stream,
            builder: (_, snap) => Text(
                '₹${(snap.data ?? 0).toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ),
        ]),
      );
}

class _MonthlyProfitCard extends StatelessWidget {
  final AccountsService accountsService;
  final String month;
  const _MonthlyProfitCard(
      {required this.accountsService, required this.month});

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: accountsService.getMonthlyIncome(month),
        builder: (_, incSnap) => StreamBuilder<List<Map<String, dynamic>>>(
          stream: accountsService.getMonthlyExpense(month),
          builder: (_, expSnap) {
            final income = accountsService.sumAmounts(incSnap.data ?? []);
            final expense = accountsService.sumAmounts(expSnap.data ?? []);
            final profit = income - expense;
            final isProfit = profit >= 0;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: isProfit
                        ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                        : [const Color(0xFFE53935), const Color(0xFFEF5350)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Profit',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('₹${profit.abs().toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      _ProfitStat(
                          label: 'Income',
                          value: income,
                          icon: Icons.arrow_upward),
                      const SizedBox(width: 20),
                      _ProfitStat(
                          label: 'Expense',
                          value: expense,
                          icon: Icons.arrow_downward),
                    ]),
                  ]),
            );
          },
        ),
      );
}

class _ProfitStat extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  const _ProfitStat(
      {required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text('₹${value.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ]);
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87))),
            ]),
          ),
        ),
      );
}

class _UnpaidInvoicesBanner extends StatelessWidget {
  final AccountsService accountsService;
  const _UnpaidInvoicesBanner({required this.accountsService});
  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: accountsService.getUnpaidInvoices(),
        builder: (_, snap) {
          final count = snap.data?.length ?? 0;
          if (count == 0) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => InvoiceScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: const Color(0xFFFF9800).withOpacity(0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFF9800), size: 24),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        '$count unpaid invoice${count > 1 ? 's' : ''} pending',
                        style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right, color: Color(0xFFFF9800)),
              ]),
            ),
          );
        },
      );
}
