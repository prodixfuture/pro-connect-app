import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/accounts_service.dart';

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({super.key});
  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = AccountsService();
  bool _isSuperAdmin = false;

  String _filterType = 'month';
  String _selectedMonth = '';
  String _selectedYear = '';
  DateTime? _customFrom;
  DateTime? _customTo;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _selectedYear = '${now.year}';
    _checkSuperAdmin();
  }

  Future<void> _checkSuperAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = (doc.data()?['role'] ?? '').toString().toLowerCase();
    if (mounted) setState(() => _isSuperAdmin = role == 'super_admin');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isIncome => _tabController.index == 0;

  Stream<List<Map<String, dynamic>>> get _stream {
    if (_filterType == 'month') {
      return _isIncome
          ? _service.getMonthlyIncome(_selectedMonth)
          : _service.getMonthlyExpense(_selectedMonth);
    }
    return _isIncome ? _service.getAllIncome() : _service.getAllExpense();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> raw) {
    var list = List<Map<String, dynamic>>.from(raw);
    if (_filterType == 'year') {
      list = list.where((item) {
        final date = (item['date'] as Timestamp?)?.toDate();
        return date != null && date.year.toString() == _selectedYear;
      }).toList();
    } else if (_filterType == 'custom' &&
        _customFrom != null &&
        _customTo != null) {
      list = list.where((item) {
        final date = (item['date'] as Timestamp?)?.toDate();
        if (date == null) return false;
        return !date.isBefore(_customFrom!) &&
            date.isBefore(_customTo!.add(const Duration(days: 1)));
      }).toList();
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((item) =>
              (item['category'] ?? '').toString().toLowerCase().contains(q) ||
              (item['note'] ?? '').toString().toLowerCase().contains(q) ||
              (item['paymentMode'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q) ||
              (item['reference'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Income & Expense',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              tooltip: 'Deleted Items',
              onPressed: _showDeletedItemsSheet,
            ),
          IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: _showFilterSheet),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(children: [
            TabBar(
              controller: _tabController,
              labelColor: _isIncome ? Colors.green : Colors.red,
              unselectedLabelColor: Colors.black45,
              indicatorColor: _isIncome ? Colors.green : Colors.red,
              tabs: const [Tab(text: 'Income'), Tab(text: 'Expense')],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search category, note, reference...',
                  prefixIcon: const Icon(Icons.search, size: 18),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(isIncome: _isIncome),
        icon: const Icon(Icons.add),
        label: Text(_isIncome ? 'Add Income' : 'Add Expense'),
        backgroundColor: _isIncome ? Colors.green : Colors.red,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = _applyFilters(snap.data ?? []);
          final total = _service.sumAmounts(items);
          final color = _isIncome ? Colors.green : Colors.red;
          final icon = _isIncome ? Icons.arrow_upward : Icons.arrow_downward;

          return Column(children: [
            if (_filterType != 'month')
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: [
                  Icon(Icons.filter_alt, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(_filterLabel,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => setState(() => _filterType = 'month'),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.black38)),
                ]),
              ),
            // Total banner
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: _isIncome
                        ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                        : [const Color(0xFFE53935), const Color(0xFFEF5350)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_isIncome ? 'Total Income' : 'Total Expense',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${items.length} entries',
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 11)),
                  Text(_filterLabel,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
              ]),
            ),
            items.isEmpty
                ? Expanded(
                    child: Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 64, color: Colors.black12),
                    const SizedBox(height: 8),
                    Text('No ${_isIncome ? 'income' : 'expense'} records',
                        style: const TextStyle(color: Colors.black38)),
                  ])))
                : Expanded(
                    child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _TransactionCard(
                      item: items[i],
                      isIncome: _isIncome,
                      onEdit: () => _showAddEditDialog(
                          isIncome: _isIncome, existing: items[i]),
                      onSoftDelete: () => _softDelete(items[i]),
                    ),
                  )),
          ]);
        },
      ),
    );
  }

  String get _filterLabel {
    switch (_filterType) {
      case 'year':
        return 'Year $_selectedYear';
      case 'custom':
        if (_customFrom != null && _customTo != null)
          return '${_customFrom!.day}/${_customFrom!.month} – ${_customTo!.day}/${_customTo!.month}';
        return 'Custom';
      case 'all':
        return 'All Time';
      default:
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
    }
  }

  Future<void> _softDelete(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Entry?'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹${item['amount']} — ${item['category']}'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          'This entry will be hidden. Only Super Admin can permanently delete it.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.orange))),
                ]),
              ),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (_isIncome)
      await _service.deleteIncome(item['id']);
    else
      await _service.deleteExpense(item['id']);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Entry removed'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () async {
            if (_isIncome)
              await _service.restoreIncome(item['id']);
            else
              await _service.restoreExpense(item['id']);
          },
        ),
      ));
    }
  }

  // Super admin: see & purge deleted items
  void _showDeletedItemsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Icon(Icons.delete_sweep, color: Colors.red),
              SizedBox(width: 8),
              Text('Deleted Entries (Super Admin)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _isIncome
                ? _service.getDeletedIncome()
                : _service.getDeletedExpense(),
            builder: (_, snap) {
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Center(
                    child: Text('No deleted entries',
                        style: TextStyle(color: Colors.black38)));
              }
              return ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final date = (item['date'] as Timestamp?)?.toDate();
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item['category'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                                '₹${item['amount']} • ${date != null ? '${date.day}/${date.month}/${date.year}' : ''}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black45)),
                            if ((item['note'] ?? '').toString().isNotEmpty)
                              Text(item['note'],
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black38)),
                          ])),
                      Column(children: [
                        TextButton.icon(
                          onPressed: () async {
                            if (_isIncome)
                              await _service.restoreIncome(item['id']);
                            else
                              await _service.restoreExpense(item['id']);
                          },
                          icon: const Icon(Icons.restore,
                              size: 14, color: Colors.green),
                          label: const Text('Restore',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.green)),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4)),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: ctx,
                              builder: (c) => AlertDialog(
                                title: const Text('Permanently Delete?',
                                    style: TextStyle(color: Colors.red)),
                                content: const Text('This cannot be undone.'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Cancel')),
                                  ElevatedButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white),
                                      child: const Text('Delete Forever')),
                                ],
                              ),
                            );
                            if (ok == true) {
                              if (_isIncome)
                                await _service.purgeIncome(item['id']);
                              else
                                await _service.purgeExpense(item['id']);
                            }
                          },
                          icon: const Icon(Icons.delete_forever,
                              size: 14, color: Colors.red),
                          label: const Text('Purge',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.red)),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4)),
                        ),
                      ]),
                    ]),
                  );
                },
              );
            },
          )),
        ]),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx2, setSheet) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Filter',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      Wrap(spacing: 8, children: [
                        _FilterChip(
                            label: 'Month',
                            selected: _filterType == 'month',
                            onTap: () {
                              setState(() => _filterType = 'month');
                              Navigator.pop(ctx);
                            }),
                        _FilterChip(
                            label: 'Year',
                            selected: _filterType == 'year',
                            onTap: () => setSheet(() => _filterType = 'year')),
                        _FilterChip(
                            label: 'Custom',
                            selected: _filterType == 'custom',
                            onTap: () =>
                                setSheet(() => _filterType = 'custom')),
                        _FilterChip(
                            label: 'All',
                            selected: _filterType == 'all',
                            onTap: () {
                              setState(() => _filterType = 'all');
                              Navigator.pop(ctx);
                            }),
                      ]),
                      const SizedBox(height: 16),
                      if (_filterType == 'month') ...[
                        const Text('Select Month',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _MonthYearPicker(
                            selected: _selectedMonth,
                            onChanged: (m) {
                              setState(() {
                                _selectedMonth = m;
                                _filterType = 'month';
                              });
                              Navigator.pop(ctx);
                            }),
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
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(_customFrom != null
                                ? '${_customFrom!.day}/${_customFrom!.month}/${_customFrom!.year}'
                                : 'From Date'),
                            onPressed: () async {
                              final d = await showDatePicker(
                                  context: ctx2,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now());
                              if (d != null) setSheet(() => _customFrom = d);
                            },
                          )),
                          const SizedBox(width: 8),
                          Expanded(
                              child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(_customTo != null
                                ? '${_customTo!.day}/${_customTo!.month}/${_customTo!.year}'
                                : 'To Date'),
                            onPressed: () async {
                              final d = await showDatePicker(
                                  context: ctx2,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now());
                              if (d != null) setSheet(() => _customTo = d);
                            },
                          )),
                        ]),
                        const SizedBox(height: 10),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _customFrom != null && _customTo != null
                                      ? () {
                                          setState(() {});
                                          Navigator.pop(ctx);
                                        }
                                      : null,
                              child: const Text('Apply'),
                            )),
                      ],
                    ]),
              )),
    );
  }

  void _showAddEditDialog(
      {required bool isIncome, Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final amountCtrl = TextEditingController(
        text: isEdit ? existing['amount']?.toString() : '');
    final noteCtrl =
        TextEditingController(text: isEdit ? existing['note'] ?? '' : '');
    final refCtrl =
        TextEditingController(text: isEdit ? existing['reference'] ?? '' : '');

    final incomeCategories = [
      'Sales',
      'Service',
      'Consulting',
      'Investment',
      'Refund',
      'Invoice',
      'Other'
    ];
    final expenseCategories = [
      'Operations',
      'Salary',
      'Rent',
      'Utilities',
      'Marketing',
      'Travel',
      'Supplies',
      'Other'
    ];
    final paymentModes = [
      'Cash',
      'Bank Transfer',
      'UPI',
      'Cheque',
      'Card',
      'Other'
    ];

    String category = isEdit
        ? (existing['category'] ?? (isIncome ? 'Sales' : 'Operations'))
        : (isIncome ? 'Sales' : 'Operations');
    String payMode = isEdit ? (existing['paymentMode'] ?? 'Cash') : 'Cash';
    DateTime selDate = isEdit
        ? ((existing['date'] as Timestamp?)?.toDate() ?? DateTime.now())
        : DateTime.now();
    final color = isIncome ? Colors.green : Colors.red;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx2, setModal) => Padding(
                padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20),
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(
                                isIncome
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: color)),
                        const SizedBox(width: 10),
                        Text(
                            isEdit
                                ? 'Edit ${isIncome ? 'Income' : 'Expense'}'
                                : 'Add ${isIncome ? 'Income' : 'Expense'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const Spacer(),
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx)),
                      ]),
                      const SizedBox(height: 16),
                      _FormField(
                          label: 'Amount (₹) *',
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                                hintText: '0.00',
                                prefixText: '₹ ',
                                prefixStyle: TextStyle(
                                    color: color,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                                border: InputBorder.none),
                          )),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _FormField(
                                label: 'Category',
                                child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                  value: (isIncome
                                              ? incomeCategories
                                              : expenseCategories)
                                          .contains(category)
                                      ? category
                                      : (isIncome ? 'Sales' : 'Operations'),
                                  isExpanded: true,
                                  items: (isIncome
                                          ? incomeCategories
                                          : expenseCategories)
                                      .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c,
                                              style: const TextStyle(
                                                  fontSize: 13))))
                                      .toList(),
                                  onChanged: (v) =>
                                      setModal(() => category = v!),
                                )))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _FormField(
                                label: 'Payment Mode',
                                child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                  value: paymentModes.contains(payMode)
                                      ? payMode
                                      : 'Cash',
                                  isExpanded: true,
                                  items: paymentModes
                                      .map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m,
                                              style: const TextStyle(
                                                  fontSize: 13))))
                                      .toList(),
                                  onChanged: (v) =>
                                      setModal(() => payMode = v!),
                                )))),
                      ]),
                      const SizedBox(height: 12),
                      _FormField(
                          label: 'Date',
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: ctx2,
                                  initialDate: selDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365)));
                              if (d != null) setModal(() => selDate = d);
                            },
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(children: [
                                  Icon(Icons.calendar_today,
                                      size: 16, color: color),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${selDate.day}/${selDate.month}/${selDate.year}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ])),
                          )),
                      const SizedBox(height: 12),
                      _FormField(
                          label: 'Reference / Transaction ID',
                          child: TextField(
                              controller: refCtrl,
                              decoration: const InputDecoration(
                                  hintText: 'e.g. UTR12345',
                                  border: InputBorder.none,
                                  isDense: true))),
                      const SizedBox(height: 12),
                      _FormField(
                          label: 'Note / Description',
                          child: TextField(
                              controller: noteCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                  hintText: 'Add a description...',
                                  border: InputBorder.none))),
                      const SizedBox(height: 20),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final amount =
                                  double.tryParse(amountCtrl.text.trim()) ?? 0;
                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Enter a valid amount')));
                                return;
                              }
                              final data = {
                                'amount': amount,
                                'category': category,
                                'paymentMode': payMode,
                                'reference': refCtrl.text.trim(),
                                'note': noteCtrl.text.trim(),
                                'date': Timestamp.fromDate(selDate)
                              };
                              if (isEdit) {
                                if (isIncome)
                                  await _service.updateIncome(
                                      existing['id'], data);
                                else
                                  await _service.updateExpense(
                                      existing['id'], data);
                              } else {
                                if (isIncome)
                                  await _service.addIncome(
                                      amount: amount,
                                      category: category,
                                      paymentMode: payMode,
                                      reference: refCtrl.text.trim(),
                                      note: noteCtrl.text.trim(),
                                      date: selDate);
                                else
                                  await _service.addExpense(
                                      amount: amount,
                                      category: category,
                                      paymentMode: payMode,
                                      reference: refCtrl.text.trim(),
                                      note: noteCtrl.text.trim(),
                                      date: selDate);
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            child: Text(isEdit ? 'Update' : 'Save',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          )),
                    ])),
              )),
    );
  }
}

// ── Transaction Card ──────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isIncome;
  final VoidCallback onEdit;
  final VoidCallback onSoftDelete;
  const _TransactionCard(
      {required this.item,
      required this.isIncome,
      required this.onEdit,
      required this.onSoftDelete});

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;
    final date = (item['date'] as Timestamp?)?.toDate();
    final ref = (item['reference'] ?? '').toString();
    final mode = (item['paymentMode'] ?? '').toString();
    final note = (item['note'] ?? '').toString();
    final isFromInvoice = (item['source'] ?? '') == 'invoice';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))
        ],
        border: isFromInvoice
            ? Border.all(color: Colors.orange.withOpacity(0.3))
            : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(isFromInvoice ? Icons.receipt_long : icon,
                  color: isFromInvoice ? Colors.orange : color, size: 18)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(item['category'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  if (isFromInvoice) ...[
                    const SizedBox(width: 6),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('Invoice',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold))),
                  ],
                ]),
                Row(children: [
                  if (mode.isNotEmpty) ...[
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(mode,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.blueGrey))),
                    const SizedBox(width: 6),
                  ],
                  if (date != null)
                    Text('${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(
                            color: Colors.black38, fontSize: 11)),
                ]),
              ])),
          Text('₹${(item['amount'] ?? 0).toStringAsFixed(2)}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        if (note.isNotEmpty || ref.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),
          if (note.isNotEmpty)
            Text(note,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (ref.isNotEmpty)
            Text('Ref: $ref',
                style: const TextStyle(fontSize: 11, color: Colors.black38)),
        ],
        const SizedBox(height: 8),
        if (!isFromInvoice) // Invoice-sourced entries — no edit/delete
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            GestureDetector(
                onTap: onEdit,
                child: const Row(children: [
                  Icon(Icons.edit_outlined, size: 14, color: Colors.blue),
                  SizedBox(width: 3),
                  Text('Edit',
                      style: TextStyle(fontSize: 12, color: Colors.blue)),
                ])),
            const SizedBox(width: 16),
            GestureDetector(
                onTap: onSoftDelete,
                child: const Row(children: [
                  Icon(Icons.hide_source_outlined, size: 14, color: Colors.red),
                  SizedBox(width: 3),
                  Text('Remove',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                ])),
          ]),
        if (isFromInvoice)
          const Align(
              alignment: Alignment.centerRight,
              child: Text('Auto-added from invoice',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic))),
      ]),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormField({required this.label, required this.child});
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
            child: child),
      ]);
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
            color: selected ? const Color(0xFF2196F3) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.black54,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ));
}

class _MonthYearPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _MonthYearPicker({required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      months.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
    }
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
    return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: months.map((m) {
          final p = m.split('-');
          return ChoiceChip(
              label: Text('${mn[int.parse(p[1]) - 1]} ${p[0]}',
                  style: const TextStyle(fontSize: 12)),
              selected: selected == m,
              onSelected: (_) => onChanged(m));
        }).toList());
  }
}
