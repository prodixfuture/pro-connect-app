import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import '../services/accounts_service.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});
  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = AccountsService();
  String _filterType = 'all';
  String _selectedMonth = '';
  String _selectedYear = '';
  DateTime? _customFrom;
  DateTime? _customTo;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _selectedYear = '${now.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _inRange(DateTime? d) {
    if (d == null) return _filterType == 'all';
    switch (_filterType) {
      case 'month':
        final p = _selectedMonth.split('-');
        final s = DateTime(int.parse(p[0]), int.parse(p[1]), 1);
        final e = DateTime(int.parse(p[0]), int.parse(p[1]) + 1, 1);
        return !d.isBefore(s) && d.isBefore(e);
      case 'year':
        return d.year.toString() == _selectedYear;
      case 'custom':
        if (_customFrom == null || _customTo == null) return true;
        return !d.isBefore(_customFrom!) &&
            d.isBefore(_customTo!.add(const Duration(days: 1)));
      default:
        return true;
    }
  }

  String get _filterLabel {
    switch (_filterType) {
      case 'month':
        final p = _selectedMonth.split('-');
        const mn = [
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
        return '${mn[int.parse(p[1]) - 1]} ${p[0]}';
      case 'year':
        return 'Year $_selectedYear';
      case 'custom':
        if (_customFrom != null && _customTo != null)
          return '${_customFrom!.day}/${_customFrom!.month} – ${_customTo!.day}/${_customTo!.month}';
        return 'Custom';
      default:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Invoices',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
              icon: const Icon(Icons.tune_rounded), onPressed: _showFilter)
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(92),
          child: Column(children: [
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF9800),
              unselectedLabelColor: Colors.black45,
              indicatorColor: const Color(0xFFFF9800),
              tabs: const [
                Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_note, size: 15),
                  SizedBox(width: 4),
                  Text('Drafts')
                ])),
                Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.send, size: 15),
                  SizedBox(width: 4),
                  Text('Sent')
                ])),
                Tab(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline, size: 15),
                  SizedBox(width: 4),
                  Text('Paid')
                ])),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                    hintText: 'Search client, invoice no, category...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5)),
              ),
            ),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
        backgroundColor: const Color(0xFFFF9800),
      ),
      body: StreamBuilder<List<Invoice>>(
        stream: _service.getAllInvoices(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF9800)));
          var all = snap.data ?? [];
          all = all.where((i) => _inRange(i.createdAt)).toList();
          if (_search.trim().isNotEmpty) {
            final q = _search.toLowerCase();
            all = all
                .where((i) =>
                    i.clientName.toLowerCase().contains(q) ||
                    i.invoiceNo.toLowerCase().contains(q) ||
                    i.category.toLowerCase().contains(q) ||
                    i.title.toLowerCase().contains(q))
                .toList();
          }
          final drafts = all.where((i) => i.status == 'draft').toList();
          final sents = all.where((i) => i.status == 'sent').toList();
          final paids = all.where((i) => i.status == 'paid').toList();
          final total = all.fold(0.0, (s, i) => s + i.effectiveTotal);
          final paid = paids.fold(0.0, (s, i) => s + i.effectiveTotal);
          final pending = sents.fold(0.0, (s, i) => s + i.effectiveTotal);
          return Column(children: [
            if (_filterType != 'all')
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Row(children: [
                  const Icon(Icons.filter_alt,
                      size: 13, color: Color(0xFFFF9800)),
                  const SizedBox(width: 4),
                  Text(_filterLabel,
                      style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => setState(() => _filterType = 'all'),
                      child: const Icon(Icons.close,
                          size: 15, color: Colors.black38)),
                ]),
              ),
            Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  _SummTile(
                      label: 'Total', amount: total, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  _SummTile(
                      label: 'Pending', amount: pending, color: Colors.orange),
                  const SizedBox(width: 8),
                  _SummTile(
                      label: 'Collected', amount: paid, color: Colors.green),
                ])),
            Expanded(
                child: TabBarView(
              controller: _tabController,
              children: [
                _InvList(
                    invoices: drafts,
                    onEdit: _showDialog,
                    onAction: _handleAction),
                _InvList(
                    invoices: sents,
                    onEdit: _showDialog,
                    onAction: _handleAction),
                _InvList(
                    invoices: paids,
                    onEdit: _showDialog,
                    onAction: _handleAction),
              ],
            )),
          ]);
        },
      ),
    );
  }

  Future<void> _handleAction(String action, Invoice inv) async {
    switch (action) {
      case 'send':
        final ok = await _confirm(
            icon: Icons.send_rounded,
            iconColor: Colors.blue,
            title: 'Send to Client?',
            body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('₹${inv.effectiveTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 10),
                  _warnBox(Icons.lock_outline, Colors.orange,
                      'After sending, this invoice cannot be edited or deleted.'),
                ]),
            confirmLabel: 'Send Invoice',
            confirmColor: Colors.blue);
        if (ok) {
          await _service.sendInvoiceToClient(inv.id);
          _snack('📤 Invoice sent!', Colors.blue);
        }
        break;
      case 'paid':
        final ok = await _confirm(
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            title: 'Mark as Paid?',
            body: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('₹${inv.effectiveTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  const SizedBox(height: 10),
                  _warnBox(Icons.arrow_upward, Colors.green,
                      'Amount will be auto-added to Income list.'),
                ]),
            confirmLabel: 'Mark Paid & Add Income',
            confirmColor: Colors.green);
        if (ok) {
          await _service.markInvoicePaid(inv.id,
              clientName: inv.clientName,
              totalAmount: inv.effectiveTotal,
              paidDate: DateTime.now());
          _snack('✅ Paid & added to Income!', Colors.green);
        }
        break;
      case 'delete':
        if (inv.status != 'draft') return;
        final ok = await _confirm(
            icon: Icons.delete_outline,
            iconColor: Colors.red,
            title: 'Delete Draft?',
            body: Text(
                'Delete ${inv.invoiceNo.isNotEmpty ? inv.invoiceNo : "draft"} for ${inv.clientName}?'),
            confirmLabel: 'Delete',
            confirmColor: Colors.red);
        if (ok) await _service.deleteInvoice(inv.id);
        break;
    }
  }

  Future<bool> _confirm(
      {required IconData icon,
      required Color iconColor,
      required String title,
      required Widget body,
      required String confirmLabel,
      required Color confirmColor}) async {
    return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  title: Row(children: [
                    Icon(icon, color: iconColor),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 17))
                  ]),
                  content: body,
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            foregroundColor: Colors.white),
                        child: Text(confirmLabel)),
                  ],
                )) ??
        false;
  }

  Widget _warnBox(IconData icon, Color color, String text) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: TextStyle(fontSize: 12, color: color)))
        ]),
      );

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating));

  void _showFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx2, ss) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Filter',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 14),
                      Wrap(spacing: 8, children: [
                        _FilterChip(
                            label: 'All',
                            selected: _filterType == 'all',
                            onTap: () {
                              setState(() => _filterType = 'all');
                              Navigator.pop(ctx);
                            }),
                        _FilterChip(
                            label: 'Month',
                            selected: _filterType == 'month',
                            onTap: () => ss(() => _filterType = 'month')),
                        _FilterChip(
                            label: 'Year',
                            selected: _filterType == 'year',
                            onTap: () => ss(() => _filterType = 'year')),
                        _FilterChip(
                            label: 'Custom',
                            selected: _filterType == 'custom',
                            onTap: () => ss(() => _filterType = 'custom')),
                      ]),
                      const SizedBox(height: 14),
                      if (_filterType == 'month') ...[
                        const Text('Select Month',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(12, (i) {
                              final d = DateTime(DateTime.now().year,
                                  DateTime.now().month - i, 1);
                              final m =
                                  '${d.year}-${d.month.toString().padLeft(2, '0')}';
                              const mn = [
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
                              return ChoiceChip(
                                  label: Text('${mn[d.month - 1]} ${d.year}',
                                      style: const TextStyle(fontSize: 11)),
                                  selected: _selectedMonth == m,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedMonth = m;
                                      _filterType = 'month';
                                    });
                                    Navigator.pop(ctx);
                                  });
                            })),
                      ],
                      if (_filterType == 'year') ...[
                        const Text('Select Year',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 8,
                            children: List.generate(5, (i) {
                              final y = '${DateTime.now().year - i}';
                              return ChoiceChip(
                                  label: Text(y),
                                  selected: _selectedYear == y,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedYear = y;
                                      _filterType = 'year';
                                    });
                                    Navigator.pop(ctx);
                                  });
                            })),
                      ],
                      if (_filterType == 'custom') ...[
                        const Text('Date Range',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today,
                                      size: 13),
                                  label: Text(_customFrom != null
                                      ? '${_customFrom!.day}/${_customFrom!.month}/${_customFrom!.year}'
                                      : 'From'),
                                  onPressed: () async {
                                    final d = await showDatePicker(
                                        context: ctx2,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now());
                                    if (d != null) ss(() => _customFrom = d);
                                  })),
                          const SizedBox(width: 8),
                          Expanded(
                              child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today,
                                      size: 13),
                                  label: Text(_customTo != null
                                      ? '${_customTo!.day}/${_customTo!.month}/${_customTo!.year}'
                                      : 'To'),
                                  onPressed: () async {
                                    final d = await showDatePicker(
                                        context: ctx2,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now());
                                    if (d != null) ss(() => _customTo = d);
                                  })),
                        ]),
                        const SizedBox(height: 10),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: () {
                                  setState(() {});
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Apply'))),
                      ],
                    ]),
              )),
    );
  }

  // ── Invoice Form Dialog ────────────────────────────────────────────────────
  void _showDialog({Invoice? existing}) {
    final isEdit = existing != null;
    if (isEdit && existing.status != 'draft') return;

    // pre-fill client for edit mode
    Map<String, dynamic>? selClient = isEdit && existing.clientName.isNotEmpty
        ? {
            'id': existing.clientId,
            'name': existing.clientName,
            'email': existing.clientEmail,
            'phone': existing.clientPhone,
            'address': existing.clientAddress
          }
        : null;

    final titleC = TextEditingController(text: existing?.title ?? '');
    final amtC = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(0) : '');
    final taxC = TextEditingController(
        text: existing != null ? existing.tax.toStringAsFixed(0) : '0');
    final notesC = TextEditingController(text: existing?.notes ?? '');
    final customC = TextEditingController(text: existing?.customCategory ?? '');

    const cats = [
      'Monthly Package',
      'Yearly Package',
      'One-time Service',
      'Consultation',
      'Others'
    ];
    const modes = ['Bank Transfer', 'UPI', 'Cash', 'Cheque', 'Card'];

    String cat = existing?.category ?? 'Monthly Package';
    String mode = existing?.paymentMode ?? 'Bank Transfer';
    DateTime dueDate =
        existing?.dueDate ?? DateTime.now().add(const Duration(days: 15));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, sm) {
        final isOthers = cat == 'Others';
        final amt = double.tryParse(amtC.text) ?? 0;
        final tax = double.tryParse(taxC.text) ?? 0;
        final tot = amt + (amt * tax / 100);

        return Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Title row
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.orange)),
                  const SizedBox(width: 10),
                  Text(isEdit ? 'Edit Draft' : 'New Invoice',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ]),
                Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.edit_note, size: 13, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Saves as Draft — Send to Client to publish',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
                const SizedBox(height: 18),

                // ── CLIENT SELECTION ──
                const _Label(text: '👤 Select Client'),
                const SizedBox(height: 8),
                _ClientSelector(
                  selected: selClient,
                  onSelect: (c) => sm(() => selClient = c),
                ),
                if (selClient != null) ...[
                  const SizedBox(height: 10),
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.orange.withOpacity(0.25))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.person,
                                  size: 15, color: Colors.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(selClient!['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14))),
                              GestureDetector(
                                  onTap: () => sm(() => selClient = null),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.black38)),
                            ]),
                            if ((selClient!['email'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.email_outlined,
                                    size: 12, color: Colors.black38),
                                const SizedBox(width: 5),
                                Text(selClient!['email'],
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54))
                              ])
                            ],
                            if ((selClient!['phone'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.phone_outlined,
                                    size: 12, color: Colors.black38),
                                const SizedBox(width: 5),
                                Text(selClient!['phone'],
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54))
                              ])
                            ],
                            if ((selClient!['address'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 12, color: Colors.black38),
                                const SizedBox(width: 5),
                                Expanded(
                                    child: Text(selClient!['address'],
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54)))
                              ])
                            ],
                          ])),
                ],
                const SizedBox(height: 18),

                // ── INVOICE DETAILS ──
                const _Label(text: '📋 Invoice Details'),
                const SizedBox(height: 10),
                _DDField(
                    label: 'Category',
                    value: cats.contains(cat) ? cat : 'Monthly Package',
                    items: cats,
                    onChange: (v) => sm(() => cat = v!)),
                if (isOthers) ...[
                  const SizedBox(height: 10),
                  _TField(
                      label: 'Type Category *',
                      ctrl: customC,
                      hint: 'Specify category')
                ],
                const SizedBox(height: 10),
                _TField(
                    label: 'Title / Description *',
                    ctrl: titleC,
                    hint: 'e.g. Website Development Package'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _TField(
                    label: 'Amount (₹) *',
                    ctrl: amtC,
                    hint: '0.00',
                    kb: const TextInputType.numberWithOptions(decimal: true),
                    onChange: (_) => sm(() {}),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _TField(
                    label: 'Tax (%)',
                    ctrl: taxC,
                    hint: '0',
                    kb: const TextInputType.numberWithOptions(decimal: true),
                    onChange: (_) => sm(() {}),
                  )),
                ]),
                if (amt > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                tax > 0
                                    ? '₹${amt.toStringAsFixed(0)} + ${tax.toStringAsFixed(0)}% tax'
                                    : '₹${amt.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black45)),
                            Text('₹${tot.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.orange)),
                          ])),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _DDField(
                          label: 'Payment Mode',
                          value: modes.contains(mode) ? mode : 'Bank Transfer',
                          items: modes,
                          onChange: (v) => sm(() => mode = v!))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Due Date',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        GestureDetector(
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: ctx2,
                                  initialDate: dueDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)));
                              if (d != null) sm(() => dueDate = d);
                            },
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0xFFE0E0E0))),
                                child: Row(children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Text(
                                      '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600))
                                ]))),
                      ])),
                ]),
                const SizedBox(height: 10),
                _TField(
                    label: 'Notes (optional)',
                    ctrl: notesC,
                    hint: 'Payment terms, additional info...',
                    maxLines: 3),
                const SizedBox(height: 22),

                // Save
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selClient == null) {
                          _snack('⚠️ Please select a client', Colors.orange);
                          return;
                        }
                        final a = double.tryParse(amtC.text.trim()) ?? 0;
                        if (a <= 0) {
                          _snack('⚠️ Enter a valid amount', Colors.orange);
                          return;
                        }
                        if (titleC.text.trim().isEmpty) {
                          _snack('⚠️ Enter title / description', Colors.orange);
                          return;
                        }
                        final t = double.tryParse(taxC.text.trim()) ?? 0;
                        final payload = {
                          'clientId': selClient!['id'] ?? '',
                          'clientName': selClient!['name'] ?? '',
                          'clientEmail': selClient!['email'] ?? '',
                          'clientPhone': selClient!['phone'] ?? '',
                          'clientAddress': selClient!['address'] ?? '',
                          'category': cat,
                          'customCategory': isOthers ? customC.text.trim() : '',
                          'title': titleC.text.trim(),
                          'amount': a,
                          'tax': t,
                          'totalAmount': a + (a * t / 100),
                          'notes': notesC.text.trim(),
                          'paymentMode': mode,
                          'dueDate': Timestamp.fromDate(dueDate),
                        };
                        if (isEdit) {
                          await _service.updateInvoice(existing.id, payload);
                        } else {
                          await _service.createInvoice(
                            clientId: selClient!['id'] ?? '',
                            clientName: selClient!['name'] ?? '',
                            clientEmail: selClient!['email'] ?? '',
                            clientPhone: selClient!['phone'] ?? '',
                            clientAddress: selClient!['address'] ?? '',
                            category: cat,
                            customCategory: isOthers ? customC.text.trim() : '',
                            title: titleC.text.trim(),
                            amount: a,
                            tax: t,
                            notes: notesC.text.trim(),
                            paymentMode: mode,
                            dueDate: dueDate,
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: Text(isEdit ? 'Update Draft' : 'Save as Draft',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    )),
              ])),
        );
      }),
    );
  }
}

// ── Client Selector (Firestore search dropdown) ───────────────────────────────
class _ClientSelector extends StatefulWidget {
  final Map<String, dynamic>? selected;
  final void Function(Map<String, dynamic>) onSelect;
  const _ClientSelector({required this.selected, required this.onSelect});
  @override
  State<_ClientSelector> createState() => _ClientSelectorState();
}

class _ClientSelectorState extends State<_ClientSelector> {
  final _ctrl = TextEditingController();
  bool _open = false;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Trigger button
      GestureDetector(
        onTap: () => setState(() => _open = !_open),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _open ? Colors.orange : const Color(0xFFE0E0E0),
                  width: _open ? 1.5 : 1)),
          child: Row(children: [
            const Icon(Icons.person_search_rounded,
                size: 18, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    widget.selected != null
                        ? widget.selected!['name'] ?? 'Select Client'
                        : 'Tap to select client...',
                    style: TextStyle(
                        color: widget.selected != null
                            ? Colors.black87
                            : Colors.black38,
                        fontSize: 14,
                        fontWeight: widget.selected != null
                            ? FontWeight.w600
                            : FontWeight.normal))),
            Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.black38),
          ]),
        ),
      ),

      // Dropdown panel
      if (_open) ...[
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]),
          child: Column(children: [
            // Search box inside dropdown
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                      hintText: 'Search name, email, phone...',
                      prefixIcon: const Icon(Icons.search, size: 17),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA))),
            ),
            // Client list — try both role:'client' and roles array
            _ClientListFromFirestore(
                query: _q,
                selected: widget.selected,
                onSelect: (c) {
                  widget.onSelect(c);
                  setState(() {
                    _open = false;
                    _q = '';
                    _ctrl.clear();
                  });
                }),
            const SizedBox(height: 8),
          ]),
        ),
      ],
    ]);
  }
}

// Fetches clients from Firestore (handles both role string and roles array)
class _ClientListFromFirestore extends StatelessWidget {
  final String query;
  final Map<String, dynamic>? selected;
  final void Function(Map<String, dynamic>) onSelect;
  const _ClientListFromFirestore(
      {required this.query, required this.selected, required this.onSelect});

  List<Map<String, dynamic>> _parse(List<QueryDocumentSnapshot> docs) {
    return docs
        .map((d) {
          final data = d.data() as Map<String, dynamic>;
          return {
            'id': d.id,
            'name': data['name'] ?? data['displayName'] ?? '',
            'email': data['email'] ?? '',
            'phone': data['phone'] ?? data['phoneNumber'] ?? '',
            'address': data['address'] ?? '',
          };
        })
        .where((c) => (c['name'] as String).isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> list) {
    if (query.trim().isEmpty) return list;
    final q = query.toLowerCase();
    return list
        .where((c) =>
            (c['name'] as String).toLowerCase().contains(q) ||
            (c['email'] as String).toLowerCase().contains(q) ||
            (c['phone'] as String).toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // We use FutureBuilder to merge both queries
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Colors.orange, strokeWidth: 2)));

        // Filter: role == 'client'/'customer' OR roles array contains 'client'/'customer'
        final allDocs = snap.data!.docs;
        final clientDocs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final role = (data['role'] ?? '').toString().toLowerCase();
          final roles = data['roles'];
          final roleList = roles is List
              ? roles.map((r) => r.toString().toLowerCase()).toList()
              : <String>[];
          return role == 'client' ||
              role == 'customer' ||
              roleList.contains('client') ||
              roleList.contains('customer');
        }).toList();

        final clients = _filter(_parse(clientDocs));

        if (clients.isEmpty) {
          return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_off_outlined,
                    size: 38, color: Colors.black26),
                const SizedBox(height: 8),
                Text(
                    query.isEmpty
                        ? 'No clients found.\nAdd users with role "client" in Firestore.'
                        : 'No match for "$query"',
                    style: const TextStyle(color: Colors.black38, fontSize: 13),
                    textAlign: TextAlign.center),
              ]));
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: clients.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 14, endIndent: 14),
            itemBuilder: (_, i) {
              final c = clients[i];
              final isSel = selected?['id'] == c['id'];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        isSel ? Colors.orange : Colors.orange.withOpacity(0.12),
                    child: Text((c['name'] as String)[0].toUpperCase(),
                        style: TextStyle(
                            color: isSel ? Colors.white : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13))),
                title: Text(c['name'] as String,
                    style: TextStyle(
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14)),
                subtitle: (c['email'] as String).isNotEmpty
                    ? Text(c['email'] as String,
                        style: const TextStyle(fontSize: 11))
                    : null,
                trailing: isSel
                    ? const Icon(Icons.check_circle,
                        color: Colors.orange, size: 18)
                    : null,
                onTap: () => onSelect(c),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Invoice List ──────────────────────────────────────────────────────────────
class _InvList extends StatelessWidget {
  final List<Invoice> invoices;
  final void Function({Invoice? existing}) onEdit;
  final Future<void> Function(String, Invoice) onAction;
  const _InvList(
      {required this.invoices, required this.onEdit, required this.onAction});
  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty)
      return const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.black12),
        SizedBox(height: 12),
        Text('No invoices here',
            style: TextStyle(color: Colors.black38, fontSize: 15)),
      ]));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _InvCard(
          invoice: invoices[i],
          onEdit: () => onEdit(existing: invoices[i]),
          onAction: onAction),
    );
  }
}

// ── Invoice Card ──────────────────────────────────────────────────────────────
class _InvCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onEdit;
  final Future<void> Function(String, Invoice) onAction;
  const _InvCard(
      {required this.invoice, required this.onEdit, required this.onAction});
  @override
  Widget build(BuildContext context) {
    final inv = invoice;
    final overdue = inv.status == 'sent' &&
        (inv.dueDate?.isBefore(DateTime.now()) ?? false);
    Color sc;
    String sl;
    if (inv.status == 'draft') {
      sc = Colors.grey;
      sl = '✏️ DRAFT';
    } else if (inv.status == 'paid') {
      sc = Colors.green;
      sl = '✅ PAID';
    } else if (overdue) {
      sc = Colors.red;
      sl = '⚠️ OVERDUE';
    } else {
      sc = Colors.blue;
      sl = '📤 SENT';
    }
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
          ],
          border:
              overdue ? Border.all(color: Colors.red.withOpacity(0.35)) : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: sc.withOpacity(0.06),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(inv.invoiceNo.isNotEmpty ? inv.invoiceNo : 'Draft',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: sc,
                            fontSize: 13)),
                    Text(
                        inv.category +
                            (inv.customCategory.isNotEmpty
                                ? ' — ${inv.customCategory}'
                                : ''),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45)),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: sc.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sc.withOpacity(0.4))),
                  child: Text(sl,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: sc))),
            ])),
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
                      Text(inv.clientName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (inv.clientEmail.isNotEmpty)
                        Text(inv.clientEmail,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black45)),
                      if (inv.clientPhone.isNotEmpty)
                        Text(inv.clientPhone,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black45)),
                    ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${inv.effectiveTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: sc)),
                  if (inv.tax > 0)
                    Text('+ ${inv.tax.toStringAsFixed(0)}% tax',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black38)),
                ]),
              ]),
              const SizedBox(height: 6),
              Text(inv.title,
                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(spacing: 12, runSpacing: 4, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.payment, size: 12, color: Colors.black38),
                  const SizedBox(width: 4),
                  Text(inv.paymentMode,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black38))
                ]),
                if (inv.dueDate != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: overdue ? Colors.red : Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                        'Due: ${inv.dueDate!.day}/${inv.dueDate!.month}/${inv.dueDate!.year}',
                        style: TextStyle(
                            fontSize: 11,
                            color: overdue ? Colors.red : Colors.black38))
                  ]),
                if (inv.status == 'paid' && inv.paidAt != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.check_circle,
                        size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                        'Paid: ${inv.paidAt!.day}/${inv.paidAt!.month}/${inv.paidAt!.year}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.green))
                  ]),
              ]),
              if (inv.notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(inv.notes,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                        fontStyle: FontStyle.italic))
              ],
              const Divider(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (inv.status == 'draft') ...[
                  _Act(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: Colors.blue,
                      onTap: onEdit),
                  const SizedBox(width: 14),
                  _Act(
                      icon: Icons.send_outlined,
                      label: 'Send',
                      color: Colors.blue,
                      onTap: () => onAction('send', inv)),
                  const SizedBox(width: 14),
                  _Act(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: Colors.red,
                      onTap: () => onAction('delete', inv)),
                ],
                if (inv.status == 'sent')
                  _Act(
                      icon: Icons.check_circle_outline,
                      label: 'Mark Paid',
                      color: Colors.green,
                      onTap: () => onAction('paid', inv)),
                if (inv.status == 'paid')
                  const Row(children: [
                    Icon(Icons.lock_outline, size: 13, color: Colors.black26),
                    SizedBox(width: 4),
                    Text('Invoice closed',
                        style: TextStyle(fontSize: 12, color: Colors.black38))
                  ]),
              ]),
            ])),
      ]),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54));
}

class _TField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final int maxLines;
  final TextInputType? kb;
  final void Function(String)? onChange;
  const _TField(
      {required this.label,
      required this.ctrl,
      required this.hint,
      this.maxLines = 1,
      this.kb,
      this.onChange});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0))),
            child: TextField(
                controller: ctrl,
                maxLines: maxLines,
                keyboardType: kb,
                onChanged: onChange,
                decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        const TextStyle(color: Colors.black26, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true))),
      ]);
}

class _DDField extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final void Function(String?) onChange;
  const _DDField(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChange});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0))),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    items: items
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child:
                                Text(c, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: onChange))),
      ]);
}

class _SummTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummTile(
      {required this.label, required this.amount, required this.color});
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
            Text('₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          ])));
}

class _Act extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Act(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: color))
      ]));
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFF2196F3) : const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(20)),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.black54,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal))));
}
