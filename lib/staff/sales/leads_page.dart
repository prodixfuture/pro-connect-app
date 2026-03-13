import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Design Tokens — Light Theme ─────────────────────────────────────────────
const _bg = Color(0xFFF0F3F8); // page background
const _surface = Color(0xFFFFFFFF); // card / panel
const _surfaceEl = Color(0xFFF4F6FB); // elevated input bg
const _border = Color(0xFFE2E8F0); // borders
const _borderHi = Color(0xFFCBD5E1); // stronger border

const _accent = Color(0xFF4F46E5); // indigo primary
const _accentLt = Color(0xFF818CF8); // indigo lighter
const _accentSoft = Color(0xFFEEF2FF); // indigo tint bg

const _green = Color(0xFF059669);
const _greenSoft = Color(0xFFD1FAE5);
const _amber = Color(0xFFD97706);
const _amberSoft = Color(0xFFFEF3C7);
const _red = Color(0xFFDC2626);
const _redSoft = Color(0xFFFEE2E2);
const _blue = Color(0xFF2563EB);
const _blueSoft = Color(0xFFDBEAFE);
const _purple = Color(0xFF7C3AED);
const _purpleSoft = Color(0xFFEDE9FE);
const _sky = Color(0xFF0284C7);
const _skySoft = Color(0xFFE0F2FE);

const _textPri = Color(0xFF0F172A); // near-black
const _textSec = Color(0xFF475569); // slate
const _textMuted = Color(0xFF94A3B8); // muted

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});
  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> with TickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _sort = 'date';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  T _f<T>(QueryDocumentSnapshot doc, String field, T def) {
    try {
      final d = doc.data() as Map<String, dynamic>?;
      if (d == null || !d.containsKey(field)) return def;
      return d[field] as T;
    } catch (_) {
      return def;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_sliverHeader()],
        body: TabBarView(
          controller: _tab,
          children: ['all', 'today', 'scheduled', 'high_priority', 'converted']
              .map((f) => _buildList(uid, f))
              .toList(),
        ),
      ),
      floatingActionButton: _fab(),
    );
  }

  // ── Sliver Header ─────────────────────────────────────────────────────────
  Widget _sliverHeader() {
    return SliverAppBar(
      expandedHeight: 155,
      pinned: true,
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.06),
      forceElevated: true,
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
      actions: [_sortMenu(), const SizedBox(width: 12)],
      flexibleSpace: FlexibleSpaceBar(background: _headerBg()),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(108),
        child: _searchAndTabs(),
      ),
    );
  }

  Widget _headerBg() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              const Text('CRM PIPELINE',
                  style: TextStyle(
                      color: _accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6)),
            ]),
          ),
          const SizedBox(height: 10),
          const Text('All Leads',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _textPri,
                  letterSpacing: -0.8)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _searchAndTabs() {
    return Container(
      color: _surface,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: _surfaceEl,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(fontSize: 14, color: _textPri),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email...',
                hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _textMuted, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: const Icon(Icons.close_rounded,
                            color: _textMuted, size: 16))
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Container(
          decoration:
              BoxDecoration(border: Border(bottom: BorderSide(color: _border))),
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: _accent,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: _accent,
            unselectedLabelColor: _textMuted,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Today'),
              Tab(text: 'Scheduled'),
              Tab(text: 'High Priority'),
              Tab(text: 'Converted'),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _sortMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _surfaceEl,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: const Icon(Icons.tune_rounded, color: _textPri, size: 18),
      ),
      color: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      onSelected: (v) => setState(() => _sort = v),
      itemBuilder: (_) => [
        _sortItem('Date Added', 'date', Icons.calendar_today_rounded),
        _sortItem('Name', 'name', Icons.sort_by_alpha_rounded),
        _sortItem('Priority', 'priority', Icons.flag_rounded),
        _sortItem('Status', 'status', Icons.swap_vert_rounded),
      ],
    );
  }

  PopupMenuItem<String> _sortItem(String label, String val, IconData icon) {
    final sel = _sort == val;
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: sel ? _accentSoft : _surfaceEl,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: sel ? _accent : _textMuted),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: sel ? _accent : _textPri,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13)),
        if (sel) ...[
          const Spacer(),
          const Icon(Icons.check_rounded, size: 14, color: _accent)
        ],
      ]),
    );
  }

  Widget _fab() {
    return Container(
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
          onTap: () => Navigator.pushNamed(context, '/sales/add-lead'),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Add Lead',
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

  // ── List ──────────────────────────────────────────────────────────────────
  Widget _buildList(String uid, String filter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('leads')
          .where('assignedTo', isEqualTo: uid)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2));
        var docs = snap.data!.docs;
        docs = _applyFilter(docs, filter);
        if (_query.isNotEmpty) {
          docs = docs.where((d) {
            final n = _f(d, 'name', '').toString().toLowerCase();
            final p = _f(d, 'phone', '').toString().toLowerCase();
            final e = _f(d, 'email', '').toString().toLowerCase();
            return n.contains(_query) ||
                p.contains(_query) ||
                e.contains(_query);
          }).toList();
        }
        docs = _applySort(docs);
        if (docs.isEmpty) return _emptyState();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          itemCount: docs.length,
          itemBuilder: (_, i) => _leadCard(docs[i]),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _applyFilter(
      List<QueryDocumentSnapshot> docs, String f) {
    final now = DateTime.now();
    switch (f) {
      case 'today':
        return docs.where((d) {
          final ts = _f<Timestamp?>(d, 'nextFollowUp', null);
          if (ts == null) return false;
          final dt = ts.toDate();
          return dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day;
        }).toList();
      case 'scheduled':
        return docs
            .where((d) => _f<Timestamp?>(d, 'nextFollowUp', null) != null)
            .toList();
      case 'high_priority':
        return docs
            .where((d) => _f(d, 'priority', 'medium') == 'high')
            .toList();
      case 'converted':
        return docs
            .where((d) => _f(d, 'status', 'new') == 'converted')
            .toList();
      default:
        return docs;
    }
  }

  List<QueryDocumentSnapshot> _applySort(List<QueryDocumentSnapshot> docs) {
    final s = List<QueryDocumentSnapshot>.from(docs);
    switch (_sort) {
      case 'date':
        s.sort((a, b) {
          final aD = _f<Timestamp?>(a, 'createdAt', null);
          final bD = _f<Timestamp?>(b, 'createdAt', null);
          if (aD == null || bD == null) return 0;
          return bD.toDate().compareTo(aD.toDate());
        });
        break;
      case 'name':
        s.sort((a, b) => _f(a, 'name', '')
            .toString()
            .compareTo(_f(b, 'name', '').toString()));
        break;
      case 'priority':
        final o = {'high': 0, 'medium': 1, 'low': 2};
        s.sort((a, b) => (o[_f(a, 'priority', 'medium')] ?? 3)
            .compareTo(o[_f(b, 'priority', 'medium')] ?? 3));
        break;
      case 'status':
        s.sort((a, b) => _f(a, 'status', 'new')
            .toString()
            .compareTo(_f(b, 'status', 'new').toString()));
        break;
    }
    return s;
  }

  // ── Lead Card ─────────────────────────────────────────────────────────────
  Widget _leadCard(QueryDocumentSnapshot doc) {
    final name = _f(doc, 'name', 'Unknown');
    final phone = _f(doc, 'phone', '');
    final company = _f(doc, 'company', '');
    final priority = _f(doc, 'priority', 'medium');
    final status = _f(doc, 'status', 'new');
    final createdAt = _f<Timestamp?>(doc, 'createdAt', null);
    final dealValue = _f<num?>(doc, 'dealValue', null);
    final followUp = _f<Timestamp?>(doc, 'nextFollowUp', null);
    final email = _f(doc, 'email', '');

    final pColor = _priorityColor(priority);
    final pSoft = _prioritySoft(priority);
    final sColor = _statusColor(status);
    final sSoft = _statusSoft(status);

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => LeadDetailsSheet(doc: doc),
      ),
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
          // Priority top bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: pColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Top row
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: pSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: pColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textPri),
                          overflow: TextOverflow.ellipsis),
                      if (company.isNotEmpty)
                        Text(company,
                            style:
                                const TextStyle(fontSize: 12, color: _textSec),
                            overflow: TextOverflow.ellipsis),
                    ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: pSoft, borderRadius: BorderRadius.circular(8)),
                    child: Text(priority.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: pColor,
                            letterSpacing: 0.8)),
                  ),
                  if (dealValue != null) ...[
                    const SizedBox(height: 5),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.currency_rupee_rounded,
                          size: 11, color: _green),
                      Text(_fmt(dealValue),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _green)),
                    ]),
                  ],
                ]),
              ]),
              const SizedBox(height: 10),

              // Status + follow-up
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: sSoft, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_statusIcon(status), size: 12, color: sColor),
                    const SizedBox(width: 4),
                    Text(_statusLabel(status),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sColor)),
                  ]),
                ),
                const SizedBox(width: 8),
                if (followUp != null) ...[
                  Icon(Icons.notifications_active_rounded,
                      size: 12, color: _amber),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(
                    DateFormat('MMM d, h:mm a').format(followUp.toDate()),
                    style: const TextStyle(
                        fontSize: 11,
                        color: _amber,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  )),
                ] else if (createdAt != null) ...[
                  const Icon(Icons.access_time_rounded,
                      size: 12, color: _textMuted),
                  const SizedBox(width: 4),
                  Text(DateFormat('MMM d, y').format(createdAt.toDate()),
                      style: const TextStyle(fontSize: 11, color: _textMuted)),
                ],
              ]),
              const SizedBox(height: 12),

              // Action buttons
              Row(children: [
                Expanded(
                    child: _actionBtn(
                        Icons.chat_bubble_rounded,
                        'WhatsApp',
                        const Color(0xFF16A34A),
                        const Color(0xFFDCFCE7),
                        () => _openWhatsApp(phone))),
                const SizedBox(width: 7),
                Expanded(
                    child: _actionBtn(Icons.call_rounded, 'Call', _blue,
                        _blueSoft, () => _makeCall(phone))),
                const SizedBox(width: 7),
                Expanded(
                    child: _actionBtn(Icons.email_rounded, 'Email', _purple,
                        _purpleSoft, () => _sendEmail(email))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _actionBtn(
          IconData icon, String label, Color c, Color bg, VoidCallback fn) =>
      GestureDetector(
        onTap: fn,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
          child: Column(children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: c)),
          ]),
        ),
      );

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 76,
            height: 76,
            decoration:
                BoxDecoration(color: _accentSoft, shape: BoxShape.circle),
            child: const Icon(Icons.inbox_outlined, size: 34, color: _accent),
          ),
          const SizedBox(height: 16),
          const Text('No leads found',
              style: TextStyle(
                  color: _textPri, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Try adjusting your filters',
              style: TextStyle(color: _textMuted, fontSize: 13)),
        ]),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _openWhatsApp(String p) async {
    if (p.isEmpty) return;
    final u = 'https://wa.me/${p.replaceAll(RegExp(r'[^0-9+]'), '')}';
    if (await canLaunchUrl(Uri.parse(u)))
      launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
  }

  Future<void> _makeCall(String p) async {
    if (p.isEmpty) return;
    if (await canLaunchUrl(Uri.parse('tel:$p'))) launchUrl(Uri.parse('tel:$p'));
  }

  Future<void> _sendEmail(String e) async {
    if (e.isEmpty) return;
    if (await canLaunchUrl(Uri.parse('mailto:$e')))
      launchUrl(Uri.parse('mailto:$e'));
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return _red;
      case 'medium':
        return _amber;
      case 'low':
        return _green;
      default:
        return _textMuted;
    }
  }

  Color _prioritySoft(String p) {
    switch (p) {
      case 'high':
        return _redSoft;
      case 'medium':
        return _amberSoft;
      case 'low':
        return _greenSoft;
      default:
        return _surfaceEl;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'new':
        return _blue;
      case 'contacted':
        return _purple;
      case 'in_progress':
        return _amber;
      case 'converted':
        return _green;
      case 'lost':
        return _red;
      default:
        return _textMuted;
    }
  }

  Color _statusSoft(String s) {
    switch (s) {
      case 'new':
        return _blueSoft;
      case 'contacted':
        return _purpleSoft;
      case 'in_progress':
        return _amberSoft;
      case 'converted':
        return _greenSoft;
      case 'lost':
        return _redSoft;
      default:
        return _surfaceEl;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'new':
        return Icons.fiber_new_rounded;
      case 'contacted':
        return Icons.call_made_rounded;
      case 'in_progress':
        return Icons.autorenew_rounded;
      case 'converted':
        return Icons.check_circle_rounded;
      case 'lost':
        return Icons.cancel_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'new':
        return 'New';
      case 'contacted':
        return 'Contacted';
      case 'in_progress':
        return 'In Progress';
      case 'converted':
        return 'Won ✓';
      case 'lost':
        return 'Lost';
      default:
        return s;
    }
  }

  String _fmt(num v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LEAD DETAILS SHEET
// ══════════════════════════════════════════════════════════════════════════════
class LeadDetailsSheet extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const LeadDetailsSheet({super.key, required this.doc});
  @override
  State<LeadDetailsSheet> createState() => _LeadDetailsSheetState();
}

class _LeadDetailsSheetState extends State<LeadDetailsSheet> {
  String _status = '';

  T _f<T>(QueryDocumentSnapshot doc, String field, T def) {
    try {
      final d = doc.data() as Map<String, dynamic>?;
      if (d == null || !d.containsKey(field)) return def;
      return d[field] as T;
    } catch (_) {
      return def;
    }
  }

  @override
  void initState() {
    super.initState();
    _status = _f(widget.doc, 'status', 'new');
  }

  @override
  Widget build(BuildContext context) {
    final name = _f(widget.doc, 'name', 'Unknown');
    final phone = _f(widget.doc, 'phone', '');
    final email = _f(widget.doc, 'email', '');
    final company = _f(widget.doc, 'company', '');
    final priority = _f(widget.doc, 'priority', 'medium');
    final source = _f(widget.doc, 'source', '');
    final deal = _f<num?>(widget.doc, 'dealValue', null);
    final createdAt = _f<Timestamp?>(widget.doc, 'createdAt', null);
    final notes = _f(widget.doc, 'notes', '');
    final pColor = _pColor(priority);
    final pSoft = _pSoft(priority);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(children: [
          Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // Header
                  Row(children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                          color: pSoft,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                          child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                  color: pColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _textPri)),
                          if (company.isNotEmpty)
                            Text(company,
                                style: const TextStyle(
                                    fontSize: 13, color: _textSec)),
                          if (deal != null) ...[
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.currency_rupee_rounded,
                                  size: 13, color: _green),
                              Text(_fmt(deal),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _green))
                            ])
                          ],
                        ])),
                    GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: _surfaceEl,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: _border)),
                            child: const Icon(Icons.close_rounded,
                                size: 17, color: _textSec))),
                  ]),
                  const SizedBox(height: 14),
                  if (createdAt != null)
                    _infoBar(Icons.access_time_rounded,
                        'Created ${DateFormat('MMM d, y · h:mm a').format(createdAt.toDate())}'),
                  const SizedBox(height: 20),

                  // Status
                  _sectionLabel('Update Status'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: Container(
                      decoration: BoxDecoration(
                          color: _surfaceEl,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: _border)),
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        isExpanded: true,
                        dropdownColor: _surface,
                        style: const TextStyle(color: _textPri, fontSize: 13),
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12)),
                        items: [
                          _ddItem('new', 'New', Icons.fiber_new_rounded, _blue),
                          _ddItem('contacted', 'Contacted',
                              Icons.call_made_rounded, _purple),
                          _ddItem('in_progress', 'In Progress',
                              Icons.autorenew_rounded, _amber),
                          _ddItem('converted', 'Converted',
                              Icons.check_circle_rounded, _green),
                          _ddItem('lost', 'Lost', Icons.cancel_rounded, _red),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                    )),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _updateStatus,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                                color: _accent.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Center(
                            child: Text('Save',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13))),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Notes
                  _sectionLabel('Notes'),
                  const SizedBox(height: 10),
                  if (notes.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: _surfaceEl,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: _border)),
                      child: Text(notes,
                          style: const TextStyle(
                              fontSize: 13, color: _textSec, height: 1.55)),
                    ),
                  _outlineBtn(notes.isEmpty ? 'Add Notes' : 'Edit Notes',
                      Icons.edit_note_rounded, () => _notesDialog(notes)),
                  const SizedBox(height: 20),

                  // Contact
                  _sectionLabel('Contact'),
                  const SizedBox(height: 10),
                  if (phone.isNotEmpty)
                    _contactRow(Icons.phone_rounded, phone, _blue),
                  if (email.isNotEmpty)
                    _contactRow(Icons.email_rounded, email, _purple),
                  if (company.isNotEmpty)
                    _contactRow(Icons.business_rounded, company, _textMuted),
                  const SizedBox(height: 20),

                  // Details
                  _sectionLabel('Details'),
                  const SizedBox(height: 10),
                  if (source.isNotEmpty)
                    _detailRow('Source', _fmtSrc(source), Icons.source_rounded),
                  if (deal != null)
                    _detailRow('Deal Value', '₹${_fmt(deal)}',
                        Icons.currency_rupee_rounded,
                        color: _green),
                  _detailRow(
                      'Priority', priority.toUpperCase(), Icons.flag_rounded,
                      color: _pColor(priority)),
                  const SizedBox(height: 20),

                  _outlineBtn('Edit Lead Details', Icons.edit_rounded, () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/sales/edit-lead',
                        arguments: widget.doc.id);
                  }),
                ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoBar(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: _surfaceEl,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border)),
        child: Row(children: [
          Icon(icon, size: 13, color: _textMuted),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12, color: _textSec))
        ]),
      );

  Widget _sectionLabel(String t) => Row(children: [
        Text(t,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _textPri)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _border)),
      ]);

  Widget _contactRow(IconData icon, String text, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: _surfaceEl,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _border)),
          child: Row(children: [
            Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: c.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 15, color: c)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 13, color: _textPri))),
          ]),
        ),
      );

  Widget _detailRow(String lbl, String val, IconData icon, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
              color: _surfaceEl,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _border)),
          child: Row(children: [
            Icon(icon, size: 15, color: color ?? _textMuted),
            const SizedBox(width: 10),
            Text(lbl, style: const TextStyle(fontSize: 12, color: _textSec)),
            const Spacer(),
            Text(val,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color ?? _textPri)),
          ]),
        ),
      );

  DropdownMenuItem<String> _ddItem(
          String v, String l, IconData icon, Color c) =>
      DropdownMenuItem(
        value: v,
        child: Row(children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 8),
          Text(l,
              style: TextStyle(
                  color: c, fontWeight: FontWeight.w600, fontSize: 13))
        ]),
      );

  Widget _outlineBtn(String lbl, IconData icon, VoidCallback fn) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: fn,
          icon: Icon(icon, size: 16, color: _accent),
          label: Text(lbl,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, color: _accent)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: BorderSide(color: _accent.withOpacity(0.3)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
      );

  Future<void> _updateStatus() async {
    final old = _f(widget.doc, 'status', 'new');
    if (old == _status) {
      _snack('Status unchanged', false);
      return;
    }
    final ok = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                            color: _accentSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.swap_horiz_rounded,
                            color: _accent, size: 24)),
                    const SizedBox(height: 14),
                    const Text('Update Status?',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _textPri)),
                    const SizedBox(height: 8),
                    Text('Change to "${_statusLabel(_status)}"?',
                        style: const TextStyle(color: _textSec, fontSize: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 22),
                    Row(children: [
                      Expanded(
                          child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: _textSec,
                                      side: BorderSide(color: _border),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  child: const Text('Cancel',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600))))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: _accent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12))),
                                  child: const Text('Confirm',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700))))),
                    ]),
                  ])),
            ));
    if (ok == true) {
      try {
        await FirebaseFirestore.instance
            .collection('leads')
            .doc(widget.doc.id)
            .update(
                {'status': _status, 'updatedAt': FieldValue.serverTimestamp()});
        if (mounted) _snack('Status updated', false);
      } catch (e) {
        if (mounted) _snack('Failed: $e', true);
      }
    } else {
      setState(() => _status = old);
    }
  }

  Future<void> _notesDialog(String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
        context: context,
        builder: (_) => Dialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Notes',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _textPri)),
                    const SizedBox(height: 14),
                    TextField(
                        controller: ctrl,
                        maxLines: 5,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14, color: _textPri),
                        decoration: InputDecoration(
                            hintText: 'Write notes...',
                            hintStyle: const TextStyle(color: _textMuted),
                            filled: true,
                            fillColor: _surfaceEl,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide(color: _border)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide(color: _border)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                    color: _accent, width: 1.5)),
                            contentPadding: const EdgeInsets.all(14))),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: _textSec,
                                  side: BorderSide(color: _border),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text('Cancel'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, ctrl.text),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text('Save',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)))),
                    ]),
                  ])),
            ));
    ctrl.dispose();
    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('leads')
            .doc(widget.doc.id)
            .update(
                {'notes': result, 'updatedAt': FieldValue.serverTimestamp()});
        if (mounted) _snack('Notes saved', false);
      } catch (e) {
        if (mounted) _snack('Failed: $e', true);
      }
    }
  }

  void _snack(String msg, bool err) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: err ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));

  Color _pColor(String p) {
    switch (p) {
      case 'high':
        return _red;
      case 'medium':
        return _amber;
      case 'low':
        return _green;
      default:
        return _textMuted;
    }
  }

  Color _pSoft(String p) {
    switch (p) {
      case 'high':
        return _redSoft;
      case 'medium':
        return _amberSoft;
      case 'low':
        return _greenSoft;
      default:
        return _surfaceEl;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'new':
        return 'New';
      case 'contacted':
        return 'Contacted';
      case 'in_progress':
        return 'In Progress';
      case 'converted':
        return 'Converted';
      case 'lost':
        return 'Lost';
      default:
        return s;
    }
  }

  String _fmtSrc(String s) =>
      s.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  String _fmt(num v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toString();
  }
}
