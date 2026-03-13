import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AccountantExpenseScreen extends StatefulWidget {
  const AccountantExpenseScreen({super.key});

  @override
  State<AccountantExpenseScreen> createState() =>
      _AccountantExpenseScreenState();
}

class _AccountantExpenseScreenState extends State<AccountantExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _bg = Color(0xFFF4F6FB);
  static const _surface = Colors.white;
  static const _accent = Color(0xFFDC2626);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

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
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 130,
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
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('ACCOUNTANT',
                          style: TextStyle(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Expense Approval',
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
                    border: Border(bottom: BorderSide(color: _border))),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: _accent,
                  indicatorWeight: 2.5,
                  labelColor: _accent,
                  unselectedLabelColor: _textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'Approved'),
                    Tab(text: 'Rejected'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildExpenseList('approved'),
            _buildExpenseList('accountant_approved'),
            _buildExpenseList('accountant_rejected'),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseList(String status) {
    Query query;
    if (status == 'approved') {
      query = FirebaseFirestore.instance
          .collection('expense_requests')
          .where('status', isEqualTo: 'approved')
          .where('accountantStatus', isEqualTo: null);
    } else {
      query = FirebaseFirestore.instance
          .collection('expense_requests')
          .where('accountantStatus', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return _buildErrorState('${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(status);
        }

        double total = 0;
        for (var doc in snapshot.data!.docs) {
          total +=
              ((doc.data() as Map<String, dynamic>)['amount'] ?? 0).toDouble();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child:
                  _buildSummaryCard(total, snapshot.data!.docs.length, status),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  return _buildExpenseCard(
                      doc.id, doc.data() as Map<String, dynamic>, status);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(double total, int count, String status) {
    Color color = status == 'accountant_approved'
        ? const Color(0xFF059669)
        : status == 'accountant_rejected'
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);
    Color soft = status == 'accountant_approved'
        ? const Color(0xFFD1FAE5)
        : status == 'accountant_rejected'
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Amount',
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('₹${_compact(total)}',
                    style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: soft, borderRadius: BorderRadius.circular(10)),
            child: Text('$count expenses',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(
      String expenseId, Map<String, dynamic> data, String status) {
    final amount = (data['amount'] ?? 0).toDouble();
    final category = data['category'] ?? 'Other';
    final raisedByName = data['raisedByName'] ?? 'Unknown';
    final approvedByName = data['approvedByName'] ?? 'Manager';
    final paymentMode = data['paymentMode'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return GestureDetector(
      onTap: () => _showExpenseDetails(expenseId, data, status),
      child: Container(
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
                  borderRadius: BorderRadius.circular(13)),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('By: $raisedByName',
                      style:
                          const TextStyle(color: _textSecondary, fontSize: 12)),
                  if (status == 'approved')
                    Row(children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 11, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text('Manager: $approvedByName',
                          style: const TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                  if (paymentMode.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.payments_rounded,
                          size: 11, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(paymentMode,
                          style: const TextStyle(
                              color: _textSecondary, fontSize: 11)),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _bg, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.chevron_right_rounded,
                  color: _textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetails(
      String expenseId, Map<String, dynamic> data, String status) {
    final remarkController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    Row(
                      children: [
                        const Text('Expense Details',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _border)),
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: _textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Column(
                        children: [
                          const Text('Amount',
                              style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            '₹${(data['amount'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailTile('Category', data['category'] ?? 'Other',
                        Icons.category_rounded),
                    _buildDetailTile('Payment Mode',
                        data['paymentMode'] ?? 'N/A', Icons.payments_rounded),
                    _buildDetailTile(
                        'Raised By',
                        data['raisedByName'] ?? 'Unknown',
                        Icons.person_rounded),
                    _buildDetailTile('Manager Approved By',
                        data['approvedByName'] ?? 'N/A', Icons.verified_rounded,
                        color: const Color(0xFF059669)),
                    if ((data['reference'] ?? '').toString().isNotEmpty)
                      _buildDetailTile('Reference', data['reference'],
                          Icons.receipt_long_rounded),
                    if ((data['note'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildLabel('Description'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border)),
                        child: Text(data['note'],
                            style: const TextStyle(
                                fontSize: 14, color: _textPrimary)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (status == 'approved') ...[
                      _buildLabel('Accountant Remark (Optional)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: remarkController,
                        maxLines: 3,
                        style:
                            const TextStyle(fontSize: 14, color: _textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Add your remark...',
                          hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                          filled: true,
                          fillColor: _bg,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _border)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: _accent, width: 1.5)),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () => _processExpense(
                                    expenseId,
                                    'accountant_rejected',
                                    remarkController.text.trim()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEE2E2),
                                  foregroundColor: const Color(0xFFDC2626),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Reject',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () => _processExpense(
                                    expenseId,
                                    'accountant_approved',
                                    remarkController.text.trim()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Approve',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildStatusBanner(status),
                      if ((data['accountantRemark'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildLabel('Accountant Remark'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border)),
                          child: Text(data['accountantRemark'],
                              style: const TextStyle(
                                  fontSize: 14, color: _textPrimary)),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    final isApproved = status == 'accountant_approved';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isApproved ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isApproved ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Icon(isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isApproved
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              size: 20),
          const SizedBox(width: 10),
          Text(
            isApproved ? 'Approved by Accountant' : 'Rejected by Accountant',
            style: TextStyle(
              color: isApproved
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon,
      {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? _textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: color ?? _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          color: _textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6));

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined,
                size: 34, color: Color(0xFFDC2626))),
        const SizedBox(height: 16),
        Text(status == 'approved' ? 'No Pending Expenses' : 'No Expenses',
            style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(status == 'approved' ? 'All caught up!' : 'Nothing here yet',
            style: const TextStyle(color: _textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded,
            size: 48, color: Color(0xFFDC2626)),
        const SizedBox(height: 12),
        Text('Error: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textSecondary, fontSize: 13)),
      ]),
    );
  }

  Future<void> _processExpense(
      String expenseId, String newStatus, String remark) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final accountantName = userDoc.data()?['name'] ?? 'Accountant';
      await FirebaseFirestore.instance
          .collection('expense_requests')
          .doc(expenseId)
          .update({
        'accountantStatus': newStatus,
        'accountantApprovedBy': user.uid,
        'accountantApprovedByName': accountantName,
        'accountantRemark': remark,
        'finalUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Expense ${newStatus == 'accountant_approved' ? 'approved' : 'rejected'}'),
          backgroundColor: newStatus == 'accountant_approved'
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
