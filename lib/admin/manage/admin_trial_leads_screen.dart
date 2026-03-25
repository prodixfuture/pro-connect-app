import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminTrialLeadsScreen extends StatefulWidget {
  const AdminTrialLeadsScreen({super.key});

  @override
  State<AdminTrialLeadsScreen> createState() => _AdminTrialLeadsScreenState();
}

class _AdminTrialLeadsScreenState extends State<AdminTrialLeadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _bg = Color(0xFFF4F6FB);
  static const _surface = Colors.white;
  static const _accent = Color(0xFF059669);
  static const _accentSoft = Color(0xFFD1FAE5);
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
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('ADMIN',
                          style: TextStyle(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Trial Leads',
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
                      fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'Approved'),
                    Tab(text: 'Rejected')
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLeadsList('pending'),
            _buildLeadsList('approved'),
            _buildLeadsList('rejected'),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadsList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trial_leads')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Color(0xFFDC2626)),
                const SizedBox(height: 12),
                Text('${snapshot.error}',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: _textSecondary, fontSize: 13)),
              ]));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(status);
        }

        int totalLeads = snapshot.data!.docs.length;
        double totalValue = 0;
        for (var doc in snapshot.data!.docs) {
          totalValue += ((doc.data() as Map<String, dynamic>)['dealValue'] ?? 0)
              .toDouble();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildSummaryCard(totalLeads, totalValue, status),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  return _buildLeadCard(
                      doc.id, doc.data() as Map<String, dynamic>, status);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(int count, double totalValue, String status) {
    Color color = status == 'approved'
        ? const Color(0xFF059669)
        : status == 'rejected'
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);
    Color soft = status == 'approved'
        ? const Color(0xFFD1FAE5)
        : status == 'rejected'
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
                const Text('Total Deal Value',
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('₹${_formatNumber(totalValue)}',
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: soft, borderRadius: BorderRadius.circular(10)),
            child: Text('$count leads',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(
      String leadId, Map<String, dynamic> data, String status) {
    final name = data['name'] ?? 'Unknown';
    final company = data['company'] ?? '';
    final priority = data['priority'] ?? 'medium';
    final dealValue = (data['dealValue'] ?? 0).toDouble();
    final createdByName = data['createdByName'] ?? 'Unknown';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final priorityColor = _getPriorityColor(priority);
    final prioritySoft = _getPrioritySoft(priority);

    return GestureDetector(
      onTap: () => _showLeadDetails(leadId, data),
      child: Container(
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
                        const BorderRadius.vertical(top: Radius.circular(16)))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: prioritySoft,
                            borderRadius: BorderRadius.circular(12)),
                        child: Center(
                            child: Text(name[0].toUpperCase(),
                                style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800))),
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
                          ])),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: prioritySoft,
                            borderRadius: BorderRadius.circular(7)),
                        child: Text(priority.toUpperCase(),
                            style: TextStyle(
                                color: priorityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 12, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text('By: $createdByName',
                          style: const TextStyle(
                              fontSize: 11, color: _textSecondary)),
                      const Spacer(),
                      if (dealValue > 0) ...[
                        const Icon(Icons.currency_rupee_rounded,
                            size: 12, color: Color(0xFF059669)),
                        Text(_formatNumber(dealValue),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669))),
                      ],
                    ]),
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.access_time_rounded,
                            size: 11, color: _textSecondary),
                        const SizedBox(width: 4),
                        Text(DateFormat('MMM d, h:mm a').format(createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: _textSecondary)),
                      ]),
                    ],
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeadDetails(String leadId, Map<String, dynamic> data) {
    final remarkController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    Row(children: [
                      const Text('Lead Details',
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
                                size: 16, color: _textSecondary)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildDetailTile('Name', data['name'] ?? 'Unknown',
                        Icons.person_rounded),
                    _buildDetailTile(
                        'Phone', data['phone'] ?? 'N/A', Icons.phone_rounded),
                    _buildDetailTile(
                        'Email', data['email'] ?? 'N/A', Icons.email_rounded),
                    _buildDetailTile('Company', data['company'] ?? 'N/A',
                        Icons.business_rounded),
                    _buildDetailTile(
                        'Priority',
                        (data['priority'] ?? 'medium').toString().toUpperCase(),
                        Icons.flag_rounded,
                        color: _getPriorityColor(data['priority'] ?? 'medium')),
                    _buildDetailTile(
                        'Source',
                        _formatSource(data['source'] ?? 'N/A'),
                        Icons.source_rounded),
                    if ((data['dealValue'] ?? 0) > 0)
                      _buildDetailTile(
                          'Deal Value',
                          '₹${_formatNumber((data['dealValue'] ?? 0).toDouble())}',
                          Icons.currency_rupee_rounded,
                          color: _accent),
                    _buildDetailTile(
                        'Created By',
                        data['createdByName'] ?? 'Unknown',
                        Icons.person_outline_rounded),
                    if ((data['notes'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Notes',
                          style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border)),
                          child: Text(data['notes'],
                              style: const TextStyle(
                                  fontSize: 14, color: _textPrimary))),
                      const SizedBox(height: 16),
                    ],
                    if (data['status'] == 'pending') ...[
                      const Text('Remark (Optional)',
                          style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: remarkController,
                        maxLines: 3,
                        style:
                            const TextStyle(fontSize: 14, color: _textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Add a remark...',
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
                      Row(children: [
                        Expanded(
                            child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateLeadStatus(leadId,
                                'rejected', remarkController.text.trim()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: const Color(0xFFDC2626),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Reject',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => _showApproveDialog(
                                leadId, data, remarkController.text.trim()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Approve',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        )),
                      ]),
                    ] else ...[
                      _buildStatusBanner(data['status'] ?? 'pending', data),
                      if ((data['remark'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Remark',
                            style: TextStyle(
                                color: _textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _border)),
                            child: Text(data['remark'],
                                style: const TextStyle(
                                    fontSize: 14, color: _textPrimary))),
                      ],
                    ],
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showApproveDialog(
      String leadId, Map<String, dynamic> data, String remark) {
    String? selectedStaff;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: _accentSoft,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.check_circle_rounded,
                            color: _accent, size: 22)),
                    const SizedBox(width: 12),
                    const Text('Approve Lead',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary)),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded,
                          color: Color(0xFF2563EB), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text('This will convert to a regular lead.',
                              style: TextStyle(
                                  color: Color(0xFF1E40AF), fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Assign to Sales Staff',
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  // ─── FIXED: fetch users by role OR department = 'sales' ───
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)));
                      }

                      // Filter: role == 'sales' OR role contains 'sales' OR department == 'sales'
                      final salesStaff = snapshot.data!.docs.where((doc) {
                        final d = doc.data() as Map<String, dynamic>;

                        // Check 'role' field (string)
                        final role = (d['role'] ?? '').toString().toLowerCase();
                        if (role.contains('sales')) return true;

                        // Check 'department' field (string)
                        final dept =
                            (d['department'] ?? '').toString().toLowerCase();
                        if (dept.contains('sales')) return true;

                        // Check 'roles' field (array or string)
                        final roles = d['roles'];
                        if (roles is List)
                          return roles.any((r) =>
                              r.toString().toLowerCase().contains('sales'));
                        if (roles is String)
                          return roles.toLowerCase().contains('sales');

                        return false;
                      }).toList();

                      if (salesStaff.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Row(children: [
                            Icon(Icons.error_outline_rounded,
                                color: Color(0xFFDC2626), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    'No sales staff found. Add users with role or department "sales".',
                                    style: TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 12))),
                          ]),
                        );
                      }

                      final creatorId = data['createdBy'];

                      return Container(
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedStaff,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12)),
                          hint: const Text('Select staff member',
                              style: TextStyle(
                                  color: Color(0xFFCBD5E1), fontSize: 14)),
                          items: salesStaff.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            final name = d['name'] ?? 'Unknown';
                            final isCreator = doc.id == creatorId;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Row(children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: isCreator
                                        ? _accentSoft
                                        : const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                      child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        color: isCreator
                                            ? _accent
                                            : const Color(0xFF2563EB),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  )),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                        '$name${isCreator ? ' (Creator)' : ''}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: _textPrimary,
                                            fontWeight: FontWeight.w600))),
                              ]),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setDialogState(() => selectedStaff = value),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                        child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: _textSecondary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: _border)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: selectedStaff != null
                            ? () {
                                Navigator.pop(context);
                                _approveAndConvertLead(
                                    leadId, data, remark, selectedStaff!);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF6EE7B7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Approve & Assign',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    )),
                  ]),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status, Map<String, dynamic> data) {
    final isApproved = status == 'approved';
    final actionByName = data['approvedByName'] ?? 'Admin';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isApproved ? _accentSoft : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isApproved ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5)),
      ),
      child: Row(children: [
        Icon(isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isApproved ? _accent : const Color(0xFFDC2626), size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isApproved ? 'Approved' : 'Rejected',
              style: TextStyle(
                  color: isApproved ? _accent : const Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text('by $actionByName',
              style: TextStyle(
                  color: isApproved ? _accent : const Color(0xFFDC2626),
                  fontSize: 11)),
        ]),
        if (isApproved && data['assignedToName'] != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _accent.withOpacity(0.3))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_rounded, size: 12, color: _accent),
              const SizedBox(width: 4),
              Text(data['assignedToName'],
                  style: const TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ]),
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
          border: Border.all(color: _border)),
      child: Row(children: [
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
      ]),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 76,
            height: 76,
            decoration:
                BoxDecoration(color: _accentSoft, shape: BoxShape.circle),
            child: const Icon(Icons.person_add_outlined,
                size: 34, color: _accent)),
        const SizedBox(height: 16),
        Text('No $status leads',
            style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Trial leads will appear here',
            style: TextStyle(color: _textSecondary, fontSize: 13)),
      ]),
    );
  }

  Future<void> _approveAndConvertLead(String leadId, Map<String, dynamic> data,
      String remark, String assignedToUid) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final adminName = userDoc.data()?['name'] ?? 'Admin';
      final assignedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(assignedToUid)
          .get();
      final assignedName = assignedDoc.data()?['name'] ?? 'Unknown';

      await FirebaseFirestore.instance
          .collection('trial_leads')
          .doc(leadId)
          .update({
        'status': 'approved',
        'approvedBy': user.uid,
        'approvedByName': adminName,
        'assignedTo': assignedToUid,
        'assignedToName': assignedName,
        'remark': remark,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('leads').add({
        'name': data['name'] ?? '',
        'phone': data['phone'] ?? '',
        'email': data['email'] ?? '',
        'company': data['company'] ?? '',
        'dealValue': data['dealValue'] ?? 0,
        'notes': data['notes'] ?? '',
        'priority': data['priority'] ?? 'medium',
        'status': 'new',
        'source': data['source'] ?? 'other',
        'assignedTo': assignedToUid,
        'trialLeadId': leadId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lead approved & assigned to $assignedName'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: const Color(0xFFDC2626)));
    }
  }

  Future<void> _updateLeadStatus(
      String leadId, String newStatus, String remark) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final adminName = userDoc.data()?['name'] ?? 'Admin';
      await FirebaseFirestore.instance
          .collection('trial_leads')
          .doc(leadId)
          .update({
        'status': newStatus,
        'approvedBy': user.uid,
        'approvedByName': adminName,
        'remark': remark,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lead $newStatus'),
          backgroundColor:
              newStatus == 'approved' ? _accent : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: const Color(0xFFDC2626)));
    }
  }

  Color _getPriorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return _accent;
      default:
        return _textSecondary;
    }
  }

  Color _getPrioritySoft(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return const Color(0xFFFEE2E2);
      case 'medium':
        return const Color(0xFFFEF3C7);
      default:
        return _accentSoft;
    }
  }

  String _formatSource(String s) =>
      s.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  String _formatNumber(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
