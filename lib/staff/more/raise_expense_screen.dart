import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RaiseExpenseScreen extends StatefulWidget {
  const RaiseExpenseScreen({super.key});

  @override
  State<RaiseExpenseScreen> createState() => _RaiseExpenseScreenState();
}

class _RaiseExpenseScreenState extends State<RaiseExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();

  String _selectedCategory = 'Travel';
  String _selectedPaymentMode = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _bg = Color(0xFFF4F6FB);
  static const _surface = Colors.white;
  static const _accent = Color(0xFFDC2626);
  static const _accentSoft = Color(0xFFFEE2E2);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Travel', 'icon': Icons.flight_takeoff_rounded},
    {'label': 'Food', 'icon': Icons.restaurant_rounded},
    {'label': 'Supplies', 'icon': Icons.inventory_2_rounded},
    {'label': 'Utilities', 'icon': Icons.bolt_rounded},
    {'label': 'Marketing', 'icon': Icons.campaign_rounded},
    {'label': 'Client Meeting', 'icon': Icons.handshake_rounded},
    {'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  final List<Map<String, dynamic>> _paymentModes = [
    {'label': 'Cash', 'icon': Icons.payments_rounded},
    {'label': 'Bank Transfer', 'icon': Icons.account_balance_rounded},
    {'label': 'UPI', 'icon': Icons.qr_code_scanner_rounded},
    {'label': 'Card', 'icon': Icons.credit_card_rounded},
    {'label': 'Other', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _referenceController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _accent),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showSnack('Please enter a valid amount', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';
      await FirebaseFirestore.instance.collection('expense_requests').add({
        'amount': amount,
        'category': _selectedCategory,
        'paymentMode': _selectedPaymentMode,
        'reference': _referenceController.text.trim(),
        'note': _noteController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'status': 'pending',
        'raisedBy': user.uid,
        'raisedByName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSnack('Expense submitted successfully!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to submit: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor:
          isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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
                      child: const Text('EXPENSE',
                          style: TextStyle(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Raise Request',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary)),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _border),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAmountCard(),
                        const SizedBox(height: 20),
                        _buildLabel('Category'),
                        const SizedBox(height: 10),
                        _buildCategoryChips(),
                        const SizedBox(height: 20),
                        _buildLabel('Payment Mode'),
                        const SizedBox(height: 10),
                        _buildPaymentModeChips(),
                        const SizedBox(height: 20),
                        _buildLabel('Expense Date'),
                        const SizedBox(height: 10),
                        _buildDatePicker(),
                        const SizedBox(height: 20),
                        _buildLabel('Reference / Bill No.'),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _referenceController,
                          hint: 'e.g. INV-001, Receipt #123',
                          icon: Icons.receipt_long_rounded,
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Description *'),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _noteController,
                          hint: 'Describe the expense in detail...',
                          icon: Icons.notes_rounded,
                          maxLines: 4,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Description is required'
                              : null,
                        ),
                        const SizedBox(height: 28),
                        _buildSubmitButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Amount',
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
            ],
            style: const TextStyle(
                color: _accent,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -1),
            decoration: const InputDecoration(
              hintText: '0.00',
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                  color: _accent,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1),
              hintStyle: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 40,
                  fontWeight: FontWeight.w800),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Please enter amount' : null,
          ),
          Container(height: 1, color: _border),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.info_outline_rounded,
                size: 13, color: _textSecondary),
            const SizedBox(width: 6),
            const Text('Will be sent for manager approval',
                style: TextStyle(fontSize: 11, color: _textSecondary)),
          ]),
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

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final selected = _selectedCategory == cat['label'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['label']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _accentSoft : _surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: selected ? _accent : _border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat['icon'] as IconData,
                    size: 14, color: selected ? _accent : _textSecondary),
                const SizedBox(width: 6),
                Text(cat['label'] as String,
                    style: TextStyle(
                        color: selected ? _accent : _textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentModeChips() {
    const selColor = Color(0xFF2563EB);
    const selSoft = Color(0xFFDBEAFE);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _paymentModes.map((mode) {
          final selected = _selectedPaymentMode == mode['label'];
          return GestureDetector(
            onTap: () => setState(() => _selectedPaymentMode = mode['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? selSoft : _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? selColor : _border, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(mode['icon'] as IconData,
                      size: 14, color: selected ? selColor : _textSecondary),
                  const SizedBox(width: 6),
                  Text(mode['label'] as String,
                      style: TextStyle(
                          color: selected ? selColor : _textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _accentSoft, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.calendar_month_rounded,
                  color: _accent, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              '${_selectedDate.day.toString().padLeft(2, '0')} / '
              '${_selectedDate.month.toString().padLeft(2, '0')} / '
              '${_selectedDate.year}',
              style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.unfold_more_rounded,
                color: _textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: _textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: _textSecondary, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFFCA5A5),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Submit Expense',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}
