import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/accounts_service.dart';
import '../services/export_service.dart';
import '../services/salary_service.dart';
import '../models/salary_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _accountsService = AccountsService();
  final _salaryService = SalaryService();
  late TabController _tabController;

  // Filter
  String _filterType = 'month';
  String _selectedMonth = '';
  String _selectedYear = '';
  DateTime? _customFrom;
  DateTime? _customTo;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _selectedYear = '${now.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  bool _dateInRange(DateTime? date) {
    if (date == null) return false;
    switch (_filterType) {
      case 'month':
        final p = _selectedMonth.split('-');
        final start = DateTime(int.parse(p[0]), int.parse(p[1]), 1);
        final end = DateTime(int.parse(p[0]), int.parse(p[1]) + 1, 1);
        return !date.isBefore(start) && date.isBefore(end);
      case 'year':
        return date.year.toString() == _selectedYear;
      case 'custom':
        if (_customFrom == null || _customTo == null) return true;
        return !date.isBefore(_customFrom!) &&
            date.isBefore(_customTo!.add(const Duration(days: 1)));
      case 'all':
        return true;
      default:
        return true;
    }
  }

  String get _filterLabel {
    switch (_filterType) {
      case 'year':
        return 'Year $_selectedYear';
      case 'custom':
        if (_customFrom != null && _customTo != null) {
          return '${_customFrom!.day}/${_customFrom!.month} – ${_customTo!.day}/${_customTo!.month}';
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Reports',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _showExportSheet,
            tooltip: 'Export',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.black45,
          indicatorColor: const Color(0xFF2196F3),
          tabs: const [
            Tab(text: '📊 Overview'),
            Tab(text: '💰 Income'),
            Tab(text: '💸 Expense'),
            Tab(text: '💼 Salary'),
          ],
        ),
      ),
      body: Column(children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today,
                    size: 12, color: Color(0xFF2196F3)),
                const SizedBox(width: 4),
                Text(_filterLabel,
                    style: const TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 16),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
              ),
            )),
          ]),
        ),

        Expanded(
            child: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(
              accountsService: _accountsService,
              salaryService: _salaryService,
              filterLabel: _filterLabel,
              dateInRange: _dateInRange,
            ),
            _IncomeTab(
                service: _accountsService,
                dateInRange: _dateInRange,
                search: _search),
            _ExpenseTab(
                service: _accountsService,
                dateInRange: _dateInRange,
                search: _search),
            _SalaryTab(
                service: _salaryService,
                search: _search,
                selectedMonth: _selectedMonth),
          ],
        )),
      ]),
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
                const Text('Filter Period',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                Wrap(spacing: 8, children: [
                  _Chip(
                      label: 'Month',
                      selected: _filterType == 'month',
                      onTap: () => setSheet(() => _filterType = 'month')),
                  _Chip(
                      label: 'Year',
                      selected: _filterType == 'year',
                      onTap: () => setSheet(() => _filterType = 'year')),
                  _Chip(
                      label: 'Custom',
                      selected: _filterType == 'custom',
                      onTap: () => setSheet(() => _filterType = 'custom')),
                  _Chip(
                      label: 'All',
                      selected: _filterType == 'all',
                      onTap: () {
                        setState(() => _filterType = 'all');
                        Navigator.pop(ctx);
                      }),
                ]),
                const SizedBox(height: 16),
                if (_filterType == 'month') ...[
                  const Text('Month',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (i) {
                        final now = DateTime.now();
                        final d = DateTime(now.year, now.month - i, 1);
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
                          },
                        );
                      })),
                ],
                if (_filterType == 'year') ...[
                  const Text('Year',
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
                          },
                        );
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
                          : 'From'),
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
                          : 'To'),
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
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      )),
                ],
              ]),
        ),
      ),
    );
  }

  void _showExportSheet() {
    final tab =
        _tabController.index; // 0=Overview, 1=Income, 2=Expense, 3=Salary
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.download_rounded, color: Color(0xFF1976D2)),
                const SizedBox(width: 8),
                const Text('Export Report',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(_filterLabel,
                      style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 4),
              const Text('Choose format to export current tab data',
                  style: TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 18),
              _ExportTile(
                icon: Icons.picture_as_pdf,
                color: Colors.red,
                title: 'Export as PDF',
                subtitle:
                    'Professional report — shareable via WhatsApp, Email etc.',
                onTap: () {
                  Navigator.pop(ctx);
                  _doExport('pdf', tab);
                },
              ),
              const SizedBox(height: 10),
              _ExportTile(
                icon: Icons.text_snippet_outlined,
                color: Colors.blue,
                title: 'Export as CSV',
                subtitle: 'Spreadsheet data — open in Excel, Google Sheets',
                onTap: () {
                  Navigator.pop(ctx);
                  _doExport('csv', tab);
                },
              ),
            ]),
      ),
    );
  }

  Future<void> _doExport(String format, int tab) async {
    // Fetch data fresh for the selected period
    List<Map<String, dynamic>> incomeData = [];
    List<Map<String, dynamic>> expenseData = [];
    List<Map<String, dynamic>> salaryData = [];

    // Fetch income
    final incomeSnap = await FirebaseFirestore.instance
        .collection('income')
        .orderBy('date', descending: true)
        .get();
    incomeData = incomeSnap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .where((m) =>
            m['isDeleted'] != true &&
            _dateInRange((m['date'] as Timestamp?)?.toDate()))
        .toList();

    // Fetch expense
    final expenseSnap = await FirebaseFirestore.instance
        .collection('expense')
        .orderBy('date', descending: true)
        .get();
    expenseData = expenseSnap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .where((m) =>
            m['isDeleted'] != true &&
            _dateInRange((m['date'] as Timestamp?)?.toDate()))
        .toList();

    // Fetch salary
    final salarySnap =
        await FirebaseFirestore.instance.collection('salary_records').get();
    salaryData = salarySnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

    final totalIncome = incomeData.fold(
        0.0, (s, i) => s + ((i['amount'] ?? 0) as num).toDouble());
    final totalExpense = expenseData.fold(
        0.0, (s, e) => s + ((e['amount'] ?? 0) as num).toDouble());
    final totalSalary = salaryData.fold(
        0.0,
        (s, e) =>
            s + ((e['finalSalary'] ?? e['grandTotal'] ?? 0) as num).toDouble());

    if (tab == 0) {
      // Overview
      if (format == 'pdf') {
        await ExportService.exportOverviewPDF(
          context: context,
          period: _filterLabel,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          totalSalary: totalSalary,
          netProfit: totalIncome - totalExpense - totalSalary,
          incomeData: incomeData,
          expenseData: expenseData,
        );
      } else {
        // CSV: merge income + expense
        final rows = [
          ...incomeData.map((i) => [
                'INCOME',
                _fmtDate(i['date']),
                i['category'] ?? '',
                i['paymentMode'] ?? '',
                i['note'] ?? '',
                '₹${(i['amount'] ?? 0).toStringAsFixed(2)}'
              ]),
          ...expenseData.map((e) => [
                'EXPENSE',
                _fmtDate(e['date']),
                e['category'] ?? '',
                e['paymentMode'] ?? '',
                e['note'] ?? '',
                '₹${(e['amount'] ?? 0).toStringAsFixed(2)}'
              ]),
        ];
        await ExportService.exportCSV(
            context: context,
            title: 'Overview — $_filterLabel',
            headers: ['Type', 'Date', 'Category', 'Mode', 'Note', 'Amount'],
            rows: rows,
            fileName: 'overview_${_filterLabel.replaceAll(' ', '')}');
      }
    } else if (tab == 1) {
      // Income
      if (format == 'pdf') {
        await ExportService.exportIncomePDF(context, incomeData, _filterLabel,
            total: totalIncome);
      } else {
        await ExportService.exportIncomeCSV(
            context, incomeData, _filterLabel.replaceAll(' ', ''));
      }
    } else if (tab == 2) {
      // Expense
      if (format == 'pdf') {
        await ExportService.exportExpensePDF(context, expenseData, _filterLabel,
            total: totalExpense);
      } else {
        await ExportService.exportExpenseCSV(
            context, expenseData, _filterLabel.replaceAll(' ', ''));
      }
    } else if (tab == 3) {
      // Salary
      if (format == 'pdf') {
        await ExportService.exportSalaryPDF(context, salaryData, _filterLabel,
            total: totalSalary);
      } else {
        await ExportService.exportSalaryCSV(
            context, salaryData, _filterLabel.replaceAll(' ', ''));
      }
    }
  }

  String _fmtDate(dynamic ts) {
    if (ts == null) return '';
    try {
      final date = ts is Timestamp ? ts.toDate() : ts as DateTime;
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}

// ── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final AccountsService accountsService;
  final SalaryService salaryService;
  final String filterLabel;
  final bool Function(DateTime?) dateInRange;
  const _OverviewTab({
    required this.accountsService,
    required this.salaryService,
    required this.filterLabel,
    required this.dateInRange,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: accountsService.getAllIncome(),
      builder: (_, incSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: accountsService.getAllExpense(),
          builder: (_, expSnap) {
            return StreamBuilder<List<SalaryRecord>>(
              stream: salaryService.getAllMonthlyPayouts(),
              builder: (_, salSnap) {
                final income = (incSnap.data ?? [])
                    .where(
                        (i) => dateInRange((i['date'] as Timestamp?)?.toDate()))
                    .toList();
                final expense = (expSnap.data ?? [])
                    .where(
                        (i) => dateInRange((i['date'] as Timestamp?)?.toDate()))
                    .toList();
                final salary = (salSnap.data ?? []);

                final totalIncome = income.fold(
                    0.0, (s, i) => s + (i['amount'] ?? 0).toDouble());
                final totalExpense = expense.fold(
                    0.0, (s, i) => s + (i['amount'] ?? 0).toDouble());
                final totalSalary =
                    salary.fold(0.0, (s, r) => s + r.finalSalary);
                final profit = totalIncome - totalExpense - totalSalary;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary cards
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Income',
                                  amount: totalIncome,
                                  color: Colors.green,
                                  icon: Icons.arrow_upward)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Expense',
                                  amount: totalExpense,
                                  color: Colors.red,
                                  icon: Icons.arrow_downward)),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Salary Paid',
                                  amount: totalSalary,
                                  color: Colors.purple,
                                  icon: Icons.payments)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _SummaryCard(
                            label: 'Net Profit',
                            amount: profit,
                            color: profit >= 0 ? Colors.teal : Colors.red,
                            icon: profit >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                          )),
                        ]),
                        const SizedBox(height: 20),

                        // Income vs Expense bar
                        const Text('Income vs Expense',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        if (totalIncome + totalExpense > 0) ...[
                          _ProgressBar(
                              label: 'Income',
                              value: totalIncome,
                              max: totalIncome + totalExpense,
                              color: Colors.green),
                          const SizedBox(height: 8),
                          _ProgressBar(
                              label: 'Expense',
                              value: totalExpense,
                              max: totalIncome + totalExpense,
                              color: Colors.red),
                        ] else
                          const Center(
                              child: Text('No data',
                                  style: TextStyle(color: Colors.black38))),

                        const SizedBox(height: 20),

                        // Category breakdown — income
                        if (income.isNotEmpty) ...[
                          const Text('Income by Category',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 10),
                          ..._groupByCategory(income).entries.map((e) =>
                              _CategoryRow(
                                  label: e.key,
                                  amount: e.value,
                                  total: totalIncome,
                                  color: Colors.green)),
                          const SizedBox(height: 16),
                        ],

                        // Category breakdown — expense
                        if (expense.isNotEmpty) ...[
                          const Text('Expense by Category',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 10),
                          ..._groupByCategory(expense).entries.map((e) =>
                              _CategoryRow(
                                  label: e.key,
                                  amount: e.value,
                                  total: totalExpense,
                                  color: Colors.red)),
                        ],
                      ]),
                );
              },
            );
          },
        );
      },
    );
  }

  Map<String, double> _groupByCategory(List<Map<String, dynamic>> items) {
    final map = <String, double>{};
    for (final i in items) {
      final cat = i['category'] ?? 'Other';
      map[cat] = (map[cat] ?? 0) + (i['amount'] ?? 0).toDouble();
    }
    final sorted = Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return sorted;
  }
}

// ── Income Tab ────────────────────────────────────────────────────────────────
class _IncomeTab extends StatelessWidget {
  final AccountsService service;
  final bool Function(DateTime?) dateInRange;
  final String search;
  const _IncomeTab(
      {required this.service, required this.dateInRange, required this.search});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getAllIncome(),
      builder: (_, snap) {
        var items = (snap.data ?? [])
            .where((i) => dateInRange((i['date'] as Timestamp?)?.toDate()))
            .toList();
        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          items = items
              .where((i) =>
                  (i['category'] ?? '').toString().toLowerCase().contains(q) ||
                  (i['note'] ?? '').toString().toLowerCase().contains(q))
              .toList();
        }
        final total =
            items.fold(0.0, (s, i) => s + (i['amount'] ?? 0).toDouble());
        return _TransactionListView(
            items: items,
            total: total,
            color: Colors.green,
            icon: Icons.arrow_upward,
            label: 'Income');
      },
    );
  }
}

// ── Expense Tab ───────────────────────────────────────────────────────────────
class _ExpenseTab extends StatelessWidget {
  final AccountsService service;
  final bool Function(DateTime?) dateInRange;
  final String search;
  const _ExpenseTab(
      {required this.service, required this.dateInRange, required this.search});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.getAllExpense(),
      builder: (_, snap) {
        var items = (snap.data ?? [])
            .where((i) => dateInRange((i['date'] as Timestamp?)?.toDate()))
            .toList();
        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          items = items
              .where((i) =>
                  (i['category'] ?? '').toString().toLowerCase().contains(q) ||
                  (i['note'] ?? '').toString().toLowerCase().contains(q))
              .toList();
        }
        final total =
            items.fold(0.0, (s, i) => s + (i['amount'] ?? 0).toDouble());
        return _TransactionListView(
            items: items,
            total: total,
            color: Colors.red,
            icon: Icons.arrow_downward,
            label: 'Expense');
      },
    );
  }
}

// ── Salary Tab ────────────────────────────────────────────────────────────────
class _SalaryTab extends StatelessWidget {
  final SalaryService service;
  final String search;
  final String selectedMonth;
  const _SalaryTab(
      {required this.service,
      required this.search,
      required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SalaryRecord>>(
      stream: service.getAllMonthlyPayouts(),
      builder: (_, snap) {
        var records = snap.data ?? [];
        if (search.isNotEmpty) {
          final q = search.toLowerCase();
          records = records.where((r) => r.month.contains(q)).toList();
        }
        final total = records.fold(0.0, (s, r) => s + r.finalSalary);
        final paid = records
            .where((r) => r.isPaid)
            .fold(0.0, (s, r) => s + r.finalSalary);

        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                  child: _MiniStatCard(
                      label: 'Total Payout',
                      amount: total,
                      color: Colors.purple)),
              const SizedBox(width: 8),
              Expanded(
                  child: _MiniStatCard(
                      label: 'Paid', amount: paid, color: Colors.green)),
              const SizedBox(width: 8),
              Expanded(
                  child: _MiniStatCard(
                      label: 'Pending',
                      amount: total - paid,
                      color: Colors.orange)),
            ]),
          ),
          Expanded(
              child: records.isEmpty
                  ? const Center(
                      child: Text('No salary records',
                          style: TextStyle(color: Colors.black38)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = records[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: r.isPaid
                                ? Border.all(
                                    color: Colors.green.withOpacity(0.3))
                                : null,
                          ),
                          child: Row(children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.month,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      'Present ${r.presentDays.toStringAsFixed(0)}  •  Absent ${r.absentDays.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.black45)),
                                ]),
                            const Spacer(),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${r.finalSalary.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.purple)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: r.isPaid
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(r.isPaid ? 'PAID' : 'PENDING',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: r.isPaid
                                                ? Colors.green
                                                : Colors.orange)),
                                  ),
                                ]),
                          ]),
                        );
                      },
                    )),
        ]);
      },
    );
  }
}

// ── Shared list view ─────────────────────────────────────────────────────────
class _TransactionListView extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double total;
  final Color color;
  final IconData icon;
  final String label;

  const _TransactionListView({
    required this.items,
    required this.total,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
              child: _MiniStatCard(
                  label: 'Total $label', amount: total, color: color)),
          const SizedBox(width: 8),
          Expanded(
              child: _MiniStatCard(
                  label: 'Entries',
                  amount: items.length.toDouble(),
                  color: Colors.blueGrey,
                  isCount: true)),
        ]),
      ),
      Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text('No $label records',
                      style: const TextStyle(color: Colors.black38)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final date = (item['date'] as Timestamp?)?.toDate();
                    final note = (item['note'] ?? '').toString();
                    final mode = (item['paymentMode'] ?? '').toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(icon, color: color, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(item['category'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Row(children: [
                                if (date != null)
                                  Text('${date.day}/${date.month}/${date.year}',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.black38)),
                                if (mode.isNotEmpty) ...[
                                  const Text('  •  ',
                                      style: TextStyle(color: Colors.black26)),
                                  Text(mode,
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.black38))
                                ],
                              ]),
                              if (note.isNotEmpty)
                                Text(note,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.black45)),
                            ])),
                        Text('₹${(item['amount'] ?? 0).toStringAsFixed(2)}',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ]),
                    );
                  },
                )),
    ]);
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _SummaryCard(
      {required this.label,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          ]),
          const SizedBox(height: 6),
          Text('₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 20)),
        ]),
      );
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isCount;
  const _MiniStatCard(
      {required this.label,
      required this.amount,
      required this.color,
      this.isCount = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
          Text(
              isCount
                  ? amount.toStringAsFixed(0)
                  : '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ]),
      );
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  const _ProgressBar(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(
            '₹${value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 8,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  const _CategoryRow(
      {required this.label,
      required this.amount,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ])),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${amount.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            Text('${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10, color: Colors.black38)),
          ]),
        ]),
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ExportTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, color: color)),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 11, color: Colors.black45)),
                ])),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: color.withOpacity(0.5)),
          ]),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2196F3) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : Colors.black54,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      );
}
