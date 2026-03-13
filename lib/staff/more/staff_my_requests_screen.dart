import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StaffMyRequestsScreen extends StatefulWidget {
  const StaffMyRequestsScreen({super.key});

  @override
  State<StaffMyRequestsScreen> createState() => _StaffMyRequestsScreenState();
}

class _StaffMyRequestsScreenState extends State<StaffMyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  static const _bg = Color(0xFFF4F6FB);
  static const _surface = Colors.white;
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _tabAccent = Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: _surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _textPrimary, size: 16),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: _surface,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('DASHBOARD',
                          style: TextStyle(
                              color: _tabAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 6),
                    const Text('My Requests',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(49),
              child: Container(
                decoration: const BoxDecoration(
                  color: _surface,
                  border: Border(bottom: BorderSide(color: _border)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: _tabAccent,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: _tabAccent,
                  unselectedLabelColor: _textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Tickets'),
                    Tab(text: 'Expenses'),
                    Tab(text: 'Leads'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTicketsList(),
            _buildExpensesList(),
            _buildTrialLeadsList(),
          ],
        ),
      ),
    );
  }

  // ─── TICKETS ─────────────────────────────────────────────────────────────

  Widget _buildTicketsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('raisedBy', isEqualTo: _currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return _buildLoader();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(Icons.confirmation_number_outlined,
              'No Tickets Yet', 'Support tickets you raise will appear here');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _buildTicketCard(data);
          },
        );
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'open';
    final priority = data['priority'] ?? 'medium';
    final title = data['title'] ?? 'No Title';
    final category = data['category'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final priorityColor = _getPriorityColor(priority);
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildBadge(status.toUpperCase(), statusColor,
                        statusColor.withOpacity(0.1)),
                    const SizedBox(width: 6),
                    _buildBadge(priority.toUpperCase(), priorityColor,
                        priorityColor.withOpacity(0.1)),
                    if (category.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _buildBadge(
                          category, _textSecondary, const Color(0xFFF1F5F9)),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                if (createdAt != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: _textSecondary),
                    const SizedBox(width: 4),
                    Text(DateFormat('MMM d, y · h:mm a').format(createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: _textSecondary)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── EXPENSES ────────────────────────────────────────────────────────────

  Widget _buildExpensesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expense_requests')
          .where('raisedBy', isEqualTo: _currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return _buildLoader();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(Icons.receipt_long_outlined,
              'No Expenses Yet', 'Submitted expense requests will appear here');
        }
        double pending = 0, approved = 0, rejected = 0;
        for (var doc in snapshot.data!.docs) {
          final d = doc.data() as Map<String, dynamic>;
          final amount = (d['amount'] ?? 0).toDouble();
          final acctStatus = d['accountantStatus'] ?? d['status'];
          if (acctStatus == 'accountant_approved') {
            approved += amount;
          } else if (acctStatus == 'rejected' ||
              acctStatus == 'accountant_rejected') {
            rejected += amount;
          } else {
            pending += amount;
          }
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildExpenseSummary(pending, approved, rejected),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildExpenseCard(data);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpenseSummary(
      double pending, double approved, double rejected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          _buildSummaryCell('₹${_compact(pending)}', 'Pending',
              const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          _buildVertDivider(),
          _buildSummaryCell('₹${_compact(approved)}', 'Approved',
              const Color(0xFF059669), const Color(0xFFD1FAE5)),
          _buildVertDivider(),
          _buildSummaryCell('₹${_compact(rejected)}', 'Rejected',
              const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> data) {
    final amount = (data['amount'] ?? 0).toDouble();
    final category = data['category'] ?? 'Other';
    final paymentMode = data['paymentMode'] ?? '';
    final status = data['status'] ?? 'pending';
    final accountantStatus = data['accountantStatus'];
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    String displayStatus;
    Color statusColor;
    IconData statusIcon;

    if (accountantStatus == 'accountant_approved') {
      displayStatus = 'Fully Approved';
      statusColor = const Color(0xFF059669);
      statusIcon = Icons.check_circle_rounded;
    } else if (accountantStatus == 'accountant_rejected') {
      displayStatus = 'Rejected';
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
    } else if (status == 'approved') {
      displayStatus = 'Manager Approved';
      statusColor = const Color(0xFF2563EB);
      statusIcon = Icons.verified_rounded;
    } else if (status == 'rejected') {
      displayStatus = 'Rejected';
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
    } else {
      displayStatus = 'Pending';
      statusColor = const Color(0xFFD97706);
      statusIcon = Icons.pending_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Color(0xFFDC2626), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(category,
                        style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('₹${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(displayStatus,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    if (paymentMode.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _textSecondary)),
                      const SizedBox(width: 8),
                      Text(paymentMode,
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 11)),
                    ],
                  ],
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 3),
                  Text(DateFormat('MMM d, y').format(createdAt),
                      style:
                          const TextStyle(fontSize: 10, color: _textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TRIAL LEADS ──────────────────────────────────────────────────────────

  Widget _buildTrialLeadsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trial_leads')
          .where('createdBy', isEqualTo: _currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return _buildLoader();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(Icons.person_add_outlined,
              'No Trial Leads Yet', 'Leads you submit will appear here');
        }
        int pending = 0, approved = 0, rejected = 0;
        for (var doc in snapshot.data!.docs) {
          final d = doc.data() as Map<String, dynamic>;
          final s = d['status'] ?? 'pending';
          if (s == 'pending')
            pending++;
          else if (s == 'approved')
            approved++;
          else if (s == 'rejected') rejected++;
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildLeadSummary(pending, approved, rejected),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final data =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return _buildTrialLeadCard(data);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeadSummary(int pending, int approved, int rejected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          _buildSummaryCell(pending.toString(), 'Pending',
              const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          _buildVertDivider(),
          _buildSummaryCell(approved.toString(), 'Approved',
              const Color(0xFF059669), const Color(0xFFD1FAE5)),
          _buildVertDivider(),
          _buildSummaryCell(rejected.toString(), 'Rejected',
              const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
        ],
      ),
    );
  }

  Widget _buildTrialLeadCard(Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final company = data['company'] ?? '';
    final status = data['status'] ?? 'pending';
    final dealValue = (data['dealValue'] ?? 0).toDouble();
    final priority = data['priority'] ?? 'medium';
    final source = data['source'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final assignedToName = data['assignedToName'];
    final priorityColor = _getPriorityColor(priority);

    Color statusColor = const Color(0xFFD97706);
    IconData statusIcon = Icons.pending_rounded;
    if (status == 'approved') {
      statusColor = const Color(0xFF059669);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
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
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          if (company.isNotEmpty)
                            Text(company,
                                style: const TextStyle(
                                    color: _textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(status.toUpperCase(),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (dealValue > 0) ...[
                      const Icon(Icons.currency_rupee_rounded,
                          size: 12, color: Color(0xFF059669)),
                      Text(_compact(dealValue),
                          style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                    ],
                    if (source.isNotEmpty) ...[
                      const Icon(Icons.source_rounded,
                          size: 11, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(
                          source
                              .split('_')
                              .map((w) => w[0].toUpperCase() + w.substring(1))
                              .join(' '),
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 11)),
                    ],
                    const Spacer(),
                    if (createdAt != null)
                      Text(DateFormat('MMM d').format(createdAt),
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 11)),
                  ],
                ),
                if (status == 'approved' && assignedToName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 12, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text('Assigned to $assignedToName',
                            style: const TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Helpers ───────────────────────────────────────────────────────

  Widget _buildLoader() => const Center(
      child: CircularProgressIndicator(color: _tabAccent, strokeWidth: 2));

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: _tabAccent.withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(color: _textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSummaryCell(String value, String label, Color color, Color bg) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(8)),
            child: Text(value,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: _textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildVertDivider() => Container(
      width: 1,
      height: 44,
      color: _border,
      margin: const EdgeInsets.symmetric(horizontal: 4));

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFFD97706);
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'resolved':
        return const Color(0xFF059669);
      default:
        return _textSecondary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF059669);
      default:
        return _textSecondary;
    }
  }
}
