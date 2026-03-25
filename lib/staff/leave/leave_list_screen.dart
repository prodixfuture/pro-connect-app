// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leave_request_screen.dart';

// ─── Design Tokens — Light Theme ─────────────────────────────────────────────
const _bg = Color(0xFFF0F3F8);
const _surface = Color(0xFFFFFFFF);
const _surfaceEl = Color(0xFFF4F6FB);
const _border = Color(0xFFE2E8F0);

const _accent = Color(0xFF4F46E5);
const _accentSoft = Color(0xFFEEF2FF);

const _green = Color(0xFF059669);
const _greenSoft = Color(0xFFD1FAE5);
const _amber = Color(0xFFD97706);
const _amberSoft = Color(0xFFFEF3C7);
const _red = Color(0xFFDC2626);
const _redSoft = Color(0xFFFEE2E2);

const _textPri = Color(0xFF0F172A);
const _textSec = Color(0xFF475569);
const _textMuted = Color(0xFF94A3B8);

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Tokens ────────────────────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return _green;
      case 'rejected':
        return _red;
      default:
        return _amber;
    }
  }

  Color _statusSoft(String s) {
    switch (s) {
      case 'approved':
        return _greenSoft;
      case 'rejected':
        return _redSoft;
      default:
        return _amberSoft;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _fmtDate(Timestamp? t) {
    if (t == null) return '—';
    final d = t.toDate();
    const m = [
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
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _deleteLeave(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration:
                  BoxDecoration(color: _redSoft, shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded,
                  color: _red, size: 26),
            ),
            const SizedBox(height: 16),
            const Text('Delete Leave?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPri)),
            const SizedBox(height: 8),
            const Text('This action is permanent and cannot be undone.',
                style: TextStyle(color: _textSec, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textSec,
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ))),
              const SizedBox(width: 12),
              Expanded(
                  child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Delete',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ))),
            ]),
          ]),
        ),
      ),
    );

    if (ok != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
    );

    try {
      await FirebaseFirestore.instance.collection('leaves').doc(id).delete();
      Navigator.pop(context);
      _snack('Leave request deleted', false);
    } catch (e) {
      Navigator.pop(context);
      _snack('Delete failed: $e', true);
    }
  }

  void _snack(String msg, bool err) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: err ? _red : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Leave List ────────────────────────────────────────────────────────────
  Widget _leaveList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leaves')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2));
        }

        if (!snap.hasData) return _emptyState(status);

        var docs = snap.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return (d['status'] ?? 'pending') == status;
        }).toList();

        docs.sort((a, b) {
          final aT =
              (a['appliedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bT =
              (b['appliedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bT.compareTo(aT);
        });

        if (docs.isEmpty) return _emptyState(status);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          itemCount: docs.length,
          itemBuilder: (_, i) => _leaveCard(docs[i], status),
        );
      },
    );
  }

  // ── Leave Card ────────────────────────────────────────────────────────────
  Widget _leaveCard(QueryDocumentSnapshot doc, String status) {
    final data = doc.data() as Map<String, dynamic>;
    final from = data['startDate'] as Timestamp?;
    final to = data['endDate'] as Timestamp?;
    final reason = (data['reason'] ?? '').toString();
    final leaveType = (data['leaveType'] ?? 'Leave').toString();
    final days = data['days']?.toString() ?? '1';
    final isHalf = data['isHalfDay'] == true;
    final isPending = status == 'pending';
    final sColor = _statusColor(status);
    final sSoft = _statusSoft(status);

    return GestureDetector(
      onTap: () => _showDetails(data, doc.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(children: [
          // Coloured top bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: sColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Status icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: sSoft, borderRadius: BorderRadius.circular(13)),
                child: Icon(_statusIcon(status), color: sColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(leaveType,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _textPri),
                                overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                              color: sSoft,
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: sColor, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: sColor,
                                    letterSpacing: 0.6)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 7),
                      Row(children: [
                        const Icon(Icons.date_range_rounded,
                            size: 13, color: _textMuted),
                        const SizedBox(width: 5),
                        Text('${_fmtDate(from)} → ${_fmtDate(to)}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: _textSec,
                                fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: _textMuted),
                        const SizedBox(width: 5),
                        Text(
                            '$days day${days == '1' ? '' : 's'} • ${isHalf ? 'Half Day' : 'Full Day'}',
                            style:
                                const TextStyle(fontSize: 12, color: _textSec)),
                      ]),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: _surfaceEl,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: _border),
                          ),
                          child: Text(reason,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: _textSec, height: 1.4)),
                        ),
                      ],
                    ]),
              ),
              // Delete button for pending
              if (isPending) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteLeave(doc.id),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: _redSoft,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: _red, size: 17),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _emptyState(String status) {
    final sColor = _statusColor(status);
    final sSoft = _statusSoft(status);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: sSoft, shape: BoxShape.circle),
          child: Icon(_statusIcon(status), size: 36, color: sColor),
        ),
        const SizedBox(height: 18),
        Text('No $status leaves',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _textPri)),
        const SizedBox(height: 6),
        Text('Your $status leave requests will appear here',
            style: const TextStyle(fontSize: 13, color: _textMuted)),
      ]),
    );
  }

  // ── Details Bottom Sheet ──────────────────────────────────────────────────
  void _showDetails(Map<String, dynamic> data, String docId) {
    final isPending = data['status'] == 'pending';
    final status = (data['status'] ?? 'pending').toString();
    final sColor = _statusColor(status);
    final sSoft = _statusSoft(status);
    final leaveType = (data['leaveType'] ?? 'Leave').toString();
    final days = data['days']?.toString() ?? '1';
    final isHalf = data['isHalfDay'] == true;
    final reason = (data['reason'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2)),
            ),

            // Header row
            Row(children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: sSoft, borderRadius: BorderRadius.circular(15)),
                child: Icon(_statusIcon(status), color: sColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(leaveType,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _textPri)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                          color: sSoft, borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: sColor, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(status.toUpperCase(),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: sColor,
                                letterSpacing: 0.6)),
                      ]),
                    ),
                  ])),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _surfaceEl,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 17, color: _textSec)),
              ),
            ]),
            const SizedBox(height: 20),

            // Info cards
            Row(children: [
              Expanded(
                  child: _infoCard('From', _fmtDate(data['startDate']),
                      Icons.calendar_today_rounded, _accent, _accentSoft)),
              const SizedBox(width: 10),
              Expanded(
                  child: _infoCard('To', _fmtDate(data['endDate']),
                      Icons.event_rounded, _accent, _accentSoft)),
            ]),
            const SizedBox(height: 10),
            _infoCardWide(
              '$days day${days == '1' ? '' : 's'} — ${isHalf ? 'Half Day' : 'Full Day'}',
              Icons.access_time_rounded,
              _amber,
              _amberSoft,
            ),

            // Reason
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(children: [
                const Text('Reason',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textPri)),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 1, color: _border)),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surfaceEl,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _border),
                ),
                child: Text(reason,
                    style: const TextStyle(
                        fontSize: 13, color: _textSec, height: 1.55)),
              ),
            ],

            // Pending actions
            if (isPending) ...[
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit_rounded, size: 17),
                          label: const Text('Edit',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accent,
                            side: BorderSide(color: _accent.withOpacity(0.35)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => LeaveRequestScreen(
                                        editId: docId, existingData: data)));
                          },
                        ))),
                const SizedBox(width: 12),
                Expanded(
                    child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 17),
                          label: const Text('Delete',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteLeave(docId);
                          },
                        ))),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _infoCard(
          String label, String val, IconData icon, Color c, Color soft) =>
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.withOpacity(0.15)),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: c,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(val,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPri)),
          ]),
        ]),
      );

  Widget _infoCardWide(String val, IconData icon, Color c, Color soft) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.withOpacity(0.15)),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 10),
          Text(val,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: c)),
        ]),
      );

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_sliverHeader()],
        body: TabBarView(
          controller: _tab,
          children: [
            _leaveList('pending'),
            _leaveList('approved'),
            _leaveList('rejected'),
          ],
        ),
      ),
      floatingActionButton: _fab(),
    );
  }

  Widget _sliverHeader() {
    return SliverAppBar(
      expandedHeight: 148,
      pinned: true,
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      forceElevated: true,
      shadowColor: Colors.black.withOpacity(0.06),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _surfaceEl,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _textPri, size: 16),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: _surface,
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: _accent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('HR MODULE',
                      style: TextStyle(
                          color: _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6)),
                ]),
              ),
              const SizedBox(height: 8),
              const Text('Leave Management',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _textPri,
                      letterSpacing: -0.6)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: Container(
          color: _surface,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TabBar(
              controller: _tab,
              indicatorColor: _accent,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: _accent,
              unselectedLabelColor: _textMuted,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
            Container(height: 1, color: _border),
          ]),
        ),
      ),
    );
  }

  Widget _fab() => Container(
        height: 52,
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _accent.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LeaveRequestScreen())),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Apply Leave',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ]),
            ),
          ),
        ),
      );
}
