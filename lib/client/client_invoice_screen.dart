import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:app_links/app_links.dart'; // deep link — pubspec: app_links: ^6.0.0

// ══════════════════════════════════════════════════════
const _kApi = 'https://prodix.in/payment/invoice_payment.php';
// Deep link scheme — AndroidManifest & Info.plist-ൽ configure ചെയ്യണം
// prodix://payment/success?form_id=xxx&status=COMPLETED
const _kDeepLinkScheme = 'prodix';
// ══════════════════════════════════════════════════════

class ClientInvoiceScreen extends StatefulWidget {
  final String clientId;
  const ClientInvoiceScreen({super.key, required this.clientId});
  @override
  State<ClientInvoiceScreen> createState() => _ClientInvoiceScreenState();
}

class _ClientInvoiceScreenState extends State<ClientInvoiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';
  String _sortBy = 'newest'; // newest / oldest / amount_high / amount_low
  static const _teal = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _sortInvoices(List<Map<String, dynamic>> list) {
    final sorted = List<Map<String, dynamic>>.from(list);
    switch (_sortBy) {
      case 'oldest':
        sorted.sort((a, b) => _getDate(a).compareTo(_getDate(b)));
        break;
      case 'amount_high':
        sorted.sort((a, b) => _getAmount(b).compareTo(_getAmount(a)));
        break;
      case 'amount_low':
        sorted.sort((a, b) => _getAmount(a).compareTo(_getAmount(b)));
        break;
      case 'newest':
      default:
        sorted.sort((a, b) => _getDate(b).compareTo(_getDate(a)));
    }
    return sorted;
  }

  DateTime _getDate(Map<String, dynamic> inv) {
    try {
      return (inv['createdAt'] as Timestamp).toDate();
    } catch (_) {
      return DateTime(2000);
    }
  }

  double _getAmount(Map<String, dynamic> inv) =>
      ((inv['totalAmount'] ?? inv['amount'] ?? 0) as num).toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Invoices',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.black54),
            tooltip: 'Sort',
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest First')),
              PopupMenuItem(value: 'oldest', child: Text('Oldest First')),
              PopupMenuItem(
                  value: 'amount_high', child: Text('Amount: High → Low')),
              PopupMenuItem(
                  value: 'amount_low', child: Text('Amount: Low → High')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(children: [
            TabBar(
              controller: _tabCtrl,
              labelColor: _teal,
              unselectedLabelColor: Colors.black38,
              indicatorColor: _teal,
              tabs: const [
                Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.all_inbox_rounded, size: 15),
                  SizedBox(width: 4),
                  Text('All')
                ])),
                Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.pending_rounded, size: 15),
                  SizedBox(width: 4),
                  Text('Pending')
                ])),
                Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_rounded, size: 15),
                  SizedBox(width: 4),
                  Text('Paid')
                ])),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search invoice, category...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => setState(() => _search = ''),
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                ),
              ),
            ),
          ]),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.clientId)
            .get(),
        builder: (_, uSnap) {
          final userData = (uSnap.data?.data() as Map<String, dynamic>?) ?? {};
          final clientName = (userData['name'] ?? '').toString();
          final clientEmail = (userData['email'] ?? '').toString();
          final clientPhone = (userData['phone'] ??
                  userData['phoneNumber'] ??
                  userData['mobile'] ??
                  '')
              .toString()
              .replaceAll('+91', '')
              .replaceAll(' ', '')
              .trim();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('invoices')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: _teal));
              }

              var all = (snap.data?.docs ?? [])
                  .map((d) => <String, dynamic>{
                        'id': d.id,
                        ...d.data() as Map<String, dynamic>
                      })
                  .where((inv) {
                final uid = widget.clientId;
                if ((inv['clientId'] ?? '') == uid) return true;
                if (clientEmail.isNotEmpty &&
                    (inv['clientEmail'] ?? '')
                            .toString()
                            .toLowerCase()
                            .trim() ==
                        clientEmail.toLowerCase().trim()) return true;
                if (clientName.isNotEmpty &&
                    (inv['clientName'] ?? '').toString().toLowerCase().trim() ==
                        clientName.toLowerCase().trim()) return true;
                return false;
              }).toList();

              if (_search.isNotEmpty) {
                final q = _search.toLowerCase();
                all = all
                    .where((i) =>
                        (i['invoiceNo'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q) ||
                        (i['category'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q) ||
                        (i['title'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q) ||
                        (i['clientName'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(q))
                    .toList();
              }

              all = _sortInvoices(all);

              // status == 'sent' → pending | status == 'paid' → paid
              final pending = all.where((i) => i['status'] == 'sent').toList();
              final paid = all.where((i) => i['status'] == 'paid').toList();

              final totalPending =
                  pending.fold(0.0, (s, i) => s + _getAmount(i));
              final totalPaid = paid.fold(0.0, (s, i) => s + _getAmount(i));

              return Column(children: [
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    _SummCard(
                        label: 'Total',
                        value: '${all.length}',
                        color: Colors.blueGrey,
                        isCount: true),
                    const SizedBox(width: 8),
                    _SummCard(
                        label: 'Pending',
                        value: '₹${totalPending.toStringAsFixed(0)}',
                        color: Colors.orange),
                    const SizedBox(width: 8),
                    _SummCard(
                        label: 'Paid',
                        value: '₹${totalPaid.toStringAsFixed(0)}',
                        color: Colors.green),
                  ]),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _InvList(
                          invoices: all,
                          clientName: clientName,
                          clientPhone: clientPhone,
                          clientEmail: clientEmail,
                          clientId: widget.clientId),
                      _InvList(
                          invoices: pending,
                          clientName: clientName,
                          clientPhone: clientPhone,
                          clientEmail: clientEmail,
                          clientId: widget.clientId),
                      _InvList(
                          invoices: paid,
                          clientName: clientName,
                          clientPhone: clientPhone,
                          clientEmail: clientEmail,
                          clientId: widget.clientId),
                    ],
                  ),
                ),
              ]);
            },
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
class _InvList extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;
  final String clientName, clientPhone, clientEmail, clientId;
  static const _teal = Color(0xFF00897B);

  const _InvList({
    required this.invoices,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: _teal.withOpacity(0.2)),
          const SizedBox(height: 12),
          const Text('No invoices', style: TextStyle(color: Colors.black38)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _InvCard(
        data: invoices[i],
        clientName: clientName,
        clientPhone: clientPhone,
        clientEmail: clientEmail,
        clientId: clientId,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
class _InvCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String clientName, clientPhone, clientEmail, clientId;

  const _InvCard({
    required this.data,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'draft';
    final total =
        ((data['totalAmount'] ?? data['amount'] ?? 0) as num).toDouble();
    final now = DateTime.now();

    DateTime? dueDate;
    try {
      dueDate = (data['dueDate'] as Timestamp?)?.toDate();
    } catch (_) {}
    DateTime? paidAt;
    try {
      paidAt = (data['paidAt'] as Timestamp?)?.toDate();
    } catch (_) {}
    DateTime? createdAt;
    try {
      createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    } catch (_) {}

    final overdue = status == 'sent' && (dueDate?.isBefore(now) ?? false);

    Color sc;
    String sl;
    IconData sIcon;
    if (status == 'paid') {
      sc = Colors.green;
      sl = 'PAID';
      sIcon = Icons.check_circle_rounded;
    } else if (overdue) {
      sc = Colors.red;
      sl = 'OVERDUE';
      sIcon = Icons.warning_rounded;
    } else if (status == 'sent') {
      sc = Colors.orange;
      sl = 'PENDING';
      sIcon = Icons.schedule_rounded;
    } else {
      sc = Colors.grey;
      sl = 'DRAFT';
      sIcon = Icons.edit_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: overdue ? Border.all(color: Colors.red.withOpacity(0.4)) : null,
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: sc.withOpacity(0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(sIcon, size: 14, color: sc),
            const SizedBox(width: 6),
            Text(data['invoiceNo'] ?? 'Invoice',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: sc, fontSize: 13)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: sc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(sl,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: sc)),
            ),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['category'] ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45)),
                      const SizedBox(height: 2),
                      Text(data['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ]),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20, color: sc)),
                if ((data['tax'] ?? 0) > 0)
                  Text('incl. ${data['tax']}% tax',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black38)),
              ]),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 12, runSpacing: 4, children: [
              if (dueDate != null)
                _Meta(
                  icon: Icons.calendar_today_rounded,
                  text: 'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                  color: overdue ? Colors.red : null,
                ),
              if (createdAt != null)
                _Meta(
                  icon: Icons.access_time_rounded,
                  text:
                      'Created: ${DateFormat('dd MMM yyyy').format(createdAt)}',
                ),
            ]),
            // Paid info
            if (status == 'paid' && paidAt != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text('Paid on ${DateFormat('dd MMM yyyy').format(paidAt)}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ],
            // Payment mode badge
            if (status == 'paid' &&
                (data['paymentMode'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('via ${data['paymentMode']}',
                    style: const TextStyle(fontSize: 10, color: Colors.green)),
              ),
            ],
            // Progress timeline for pending
            if (status == 'sent') ...[
              const SizedBox(height: 12),
              _PaymentTimeline(
                  createdAt: createdAt, dueDate: dueDate, overdue: overdue),
            ],
            // Notes
            if ((data['notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(data['notes'],
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black38,
                      fontStyle: FontStyle.italic)),
            ],
            // Pay button — only for sent (pending)
            if (status == 'sent')
              _PayNowButton(
                invoiceId: data['id'],
                invoiceNo: data['invoiceNo'] ?? 'Invoice',
                amount: total,
                clientName: clientName,
                clientPhone: clientPhone,
                clientEmail: clientEmail,
                clientId: clientId,
              ),
          ]),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  PAYMENT TIMELINE
// ══════════════════════════════════════════════════════════
class _PaymentTimeline extends StatelessWidget {
  final DateTime? createdAt, dueDate;
  final bool overdue;
  const _PaymentTimeline({this.createdAt, this.dueDate, required this.overdue});

  @override
  Widget build(BuildContext context) {
    if (createdAt == null || dueDate == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final total = dueDate!.difference(createdAt!).inDays.clamp(1, 999);
    final passed = now.difference(createdAt!).inDays.clamp(0, total);
    final pct = (passed / total).clamp(0.0, 1.0);
    final daysLeft = dueDate!.difference(now).inDays;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Payment deadline',
            style: TextStyle(fontSize: 11, color: Colors.black45)),
        Text(
          overdue
              ? 'Overdue by ${now.difference(dueDate!).inDays} days'
              : '$daysLeft days left',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: overdue ? Colors.red : Colors.orange),
        ),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 6,
          backgroundColor: Colors.grey.shade200,
          valueColor:
              AlwaysStoppedAnimation(overdue ? Colors.red : Colors.orange),
        ),
      ),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(DateFormat('dd MMM').format(createdAt!),
            style: const TextStyle(fontSize: 9, color: Colors.black38)),
        Text(DateFormat('dd MMM yyyy').format(dueDate!),
            style: const TextStyle(fontSize: 9, color: Colors.black38)),
      ]),
    ]);
  }
}

// ══════════════════════════════════════════════════════════
//  PAY NOW BUTTON — Auto-polling + Deep Link
// ══════════════════════════════════════════════════════════
class _PayNowButton extends StatefulWidget {
  final String invoiceId,
      invoiceNo,
      clientName,
      clientPhone,
      clientEmail,
      clientId;
  final double amount;

  const _PayNowButton({
    required this.invoiceId,
    required this.invoiceNo,
    required this.amount,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.clientId,
  });

  @override
  State<_PayNowButton> createState() => _PayNowButtonState();
}

class _PayNowButtonState extends State<_PayNowButton> {
  bool _loading = false;
  bool _waitingForPayment = false;
  String? _formId;

  Timer? _pollTimer;
  AppLinks? _appLinks;
  StreamSubscription? _linkSub;

  int _pollCount = 0;
  static const _maxPolls = 24; // 24 × 5s = 2 min auto-poll
  static const _pollInterval = Duration(seconds: 5);

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  // ── Deep link listener ─────────────────────────────────
  void _setupDeepLink() {
    _appLinks = AppLinks();
    _linkSub = _appLinks!.uriLinkStream.listen((uri) {
      if (!mounted) return;
      // prodix://payment/success?form_id=xxx&status=COMPLETED
      if (uri.scheme == _kDeepLinkScheme &&
          uri.host == 'payment' &&
          uri.path == '/success') {
        final status = uri.queryParameters['status'] ?? '';
        final fid = uri.queryParameters['form_id'] ?? '';
        if (fid == _formId && status == 'COMPLETED') {
          _stopPolling();
          _onPaymentSuccess();
        }
      }
    });
  }

  // ── Start auto-polling ─────────────────────────────────
  void _startPolling() {
    _pollCount = 0;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollStatus());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _linkSub?.cancel();
    _linkSub = null;
  }

  // ── Poll status API ────────────────────────────────────
  Future<void> _pollStatus() async {
    if (_formId == null || !mounted) return;
    _pollCount++;

    try {
      final resp = await http
          .get(Uri.parse('$_kApi?action=status&form_id=$_formId&api=1'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      final body = jsonDecode(resp.body);
      final state = (body['status'] ?? 'PENDING').toString().toUpperCase();

      if (body['success'] == true && state == 'COMPLETED') {
        _stopPolling();
        await _onPaymentSuccess();
        return;
      }

      if (state == 'FAILED') {
        _stopPolling();
        if (mounted) {
          setState(() {
            _loading = false;
            _waitingForPayment = false;
          });
          _showError('Payment failed. Please try again.');
        }
        return;
      }
    } catch (_) {
      // Network hiccup — keep polling
    }

    // Max polls reached — show manual confirm
    if (_pollCount >= _maxPolls && mounted) {
      _stopPolling();
      setState(() => _loading = false);
      _showManualConfirm();
    }
  }

  // ── Payment confirmed ──────────────────────────────────
  Future<void> _onPaymentSuccess() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _waitingForPayment = false;
    });
    await _markPaid();
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SuccessPage(
          invoiceNo: widget.invoiceNo,
          amount: widget.amount,
        ),
      ),
    );
  }

  // ── Step 1: Create payment → open browser ─────────────
  Future<void> _startPayment() async {
    setState(() => _loading = true);
    try {
      final resp = await http
          .post(
            Uri.parse('$_kApi?action=create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'invoice_id': widget.invoiceId,
              'invoice_no': widget.invoiceNo,
              'amount': widget.amount,
              'client_name': widget.clientName,
              'client_phone': widget.clientPhone,
              'client_email': widget.clientEmail,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;
      final json = jsonDecode(resp.body);

      if (json['success'] == true) {
        _formId = json['form_id'] as String;
        final payUrl = json['pay_url'] as String;

        await launchUrl(Uri.parse(payUrl),
            mode: LaunchMode.externalApplication);

        if (mounted) {
          setState(() {
            _loading = false;
            _waitingForPayment = true;
          });
          _setupDeepLink();
          _startPolling();
        }
      } else {
        setState(() => _loading = false);
        _showError(json['message'] ?? 'Server error. Try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Connection error. Check your internet and try again.');
      }
    }
  }

  // ── Firestore: mark paid ───────────────────────────────
  Future<void> _markPaid() async {
    final now = FieldValue.serverTimestamp();
    final db = FirebaseFirestore.instance;

    await db.collection('invoices').doc(widget.invoiceId).update({
      'status': 'paid',
      'paidAt': now,
      'paymentMode': 'PhonePe',
      'formId': _formId ?? '',
    });

    await db.collection('income').add({
      'title': 'Invoice Payment - ${widget.invoiceNo}',
      'amount': widget.amount,
      'category': 'Invoice Payment',
      'paymentMode': 'PhonePe',
      'invoiceId': widget.invoiceId,
      'clientId': widget.clientId,
      'reference': _formId ?? '',
      'note': 'Online payment via PhonePe by client',
      'date': now,
      'createdAt': now,
      'isDeleted': false,
    });
  }

  // ── Dialogs ────────────────────────────────────────────
  void _showManualConfirm() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.help_outline_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Confirm Payment?', style: TextStyle(fontSize: 16)),
        ]),
        content: const Text(
          'PhonePe-ൽ payment successful ആണോ?\n\nYes ആണെങ്കിൽ confirm ചെയ്യൂ.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _onPaymentSuccess();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Yes, Paid'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.error_outline_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Error', style: TextStyle(fontSize: 16)),
        ]),
        content: Text(msg, style: const TextStyle(fontSize: 13, height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 14),
      const Divider(height: 1, color: Color(0xFFEEEEEE)),
      const SizedBox(height: 14),

      // ── Pay button ──────────────────────────────────────
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: (_loading || _waitingForPayment) ? null : _startPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F259F),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade200,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            elevation: 3,
            shadowColor: const Color(0xFF5F259F).withOpacity(0.35),
          ),
          child: _loading && !_waitingForPayment
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Center(
                      child: Text('P',
                          style: TextStyle(
                              color: Color(0xFF5F259F),
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Pay ₹${widget.amount.toStringAsFixed(2)}  via PhonePe',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
        ),
      ),
      const SizedBox(height: 6),
      const Center(
        child: Text('🔒  UPI · Cards · Net Banking · Wallets',
            style: TextStyle(fontSize: 10, color: Colors.black38)),
      ),

      // ── Waiting / polling state ─────────────────────────
      if (_waitingForPayment) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F0FF),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0xFF5F259F).withOpacity(0.25)),
          ),
          child: Column(children: [
            // Polling indicator
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF5F259F).withOpacity(0.7)),
              ),
              const SizedBox(width: 8),
              const Text('Payment verify ചെയ്യുന്നു...',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5F259F),
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            const Text(
              'PhonePe-ൽ payment complete ചെയ്‌താൽ automatically update ആകും.\nBrowser close ചെയ്‌ത് app-ലേക്ക് return ചെയ്യൂ.',
              style: TextStyle(fontSize: 11, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Manual confirm — fallback only
            TextButton.icon(
              onPressed: _loading ? null : _showManualConfirm,
              icon: const Icon(Icons.help_outline, size: 14),
              label:
                  const Text('Manual confirm', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Colors.black45),
            ),
          ]),
        ),
      ],
    ]);
  }
}

// ══════════════════════════════════════════════════════════
//  SUCCESS PAGE
// ══════════════════════════════════════════════════════════
class _SuccessPage extends StatelessWidget {
  final String invoiceNo;
  final double amount;
  const _SuccessPage({required this.invoiceNo, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                    color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 80),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Payment Successful!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Text('₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.green)),
            const SizedBox(height: 4),
            Text('paid for $invoiceNo',
                style: const TextStyle(fontSize: 14, color: Colors.black45)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(children: [
                _RR('Invoice', invoiceNo),
                const Divider(height: 20),
                _RR('Amount Paid', '₹${amount.toStringAsFixed(2)}',
                    green: true),
                const Divider(height: 20),
                _RR('Payment Via', 'PhonePe'),
                const Divider(height: 20),
                _RR('Status', '✅  Paid'),
              ]),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Done',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════════════════════
class _RR extends StatelessWidget {
  final String l, v;
  final bool green;
  const _RR(this.l, this.v, {this.green = false});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 13, color: Colors.black45)),
          Text(v,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: green ? Colors.green : Colors.black87)),
        ],
      );
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _Meta({required this.icon, required this.text, this.color});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color ?? Colors.black38),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(fontSize: 11, color: color ?? Colors.black45)),
      ]);
}

class _SummCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isCount;
  const _SummCard({
    required this.label,
    required this.value,
    required this.color,
    this.isCount = false,
  });
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          ]),
        ),
      );
}
