import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffAddLeadScreen extends StatefulWidget {
  const StaffAddLeadScreen({super.key});

  @override
  State<StaffAddLeadScreen> createState() => _StaffAddLeadScreenState();
}

class _StaffAddLeadScreenState extends State<StaffAddLeadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _dealValueController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPriority = 'medium';
  String _selectedSource = 'website';
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _bg = Color(0xFFF4F6FB);
  static const _surface = Colors.white;
  static const _accent = Color(0xFF059669);
  static const _accentSoft = Color(0xFFD1FAE5);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  final List<Map<String, dynamic>> _sources = [
    {'value': 'website', 'label': 'Website', 'icon': Icons.language_rounded},
    {'value': 'referral', 'label': 'Referral', 'icon': Icons.people_rounded},
    {
      'value': 'cold_call',
      'label': 'Cold Call',
      'icon': Icons.phone_in_talk_rounded
    },
    {
      'value': 'social_media',
      'label': 'Social',
      'icon': Icons.trending_up_rounded
    },
    {'value': 'event', 'label': 'Event', 'icon': Icons.event_available_rounded},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz_rounded},
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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _dealValueController.dispose();
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Color _priorityColor(String p) {
    switch (p) {
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

  Color _prioritySoft(String p) {
    switch (p) {
      case 'high':
        return const Color(0xFFFEE2E2);
      case 'medium':
        return const Color(0xFFFEF3C7);
      case 'low':
        return _accentSoft;
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';
      await FirebaseFirestore.instance.collection('trial_leads').add({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'company': _companyController.text.trim(),
        'dealValue': _dealValueController.text.isNotEmpty
            ? double.tryParse(_dealValueController.text) ?? 0
            : 0,
        'notes': _notesController.text.trim(),
        'priority': _selectedPriority,
        'source': _selectedSource,
        'status': 'pending',
        'createdBy': user.uid,
        'createdByName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSnack('Lead submitted for approval!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to add lead: $e', isError: true);
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
                      child: const Text('TRIAL LEAD',
                          style: TextStyle(
                              color: _accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Add New Lead',
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
                        _buildSectionHeader('Contact Details'),
                        const SizedBox(height: 16),
                        _buildLabeledField(
                          label: 'Full Name *',
                          controller: _nameController,
                          hint: 'Enter lead name',
                          icon: Icons.person_rounded,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        _buildLabeledField(
                          label: 'Phone Number *',
                          controller: _phoneController,
                          hint: '+91 XXXXX XXXXX',
                          icon: Icons.phone_rounded,
                          keyboard: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        _buildLabeledField(
                          label: 'Email',
                          controller: _emailController,
                          hint: 'email@company.com',
                          icon: Icons.email_rounded,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _buildLabeledField(
                          label: 'Company',
                          controller: _companyController,
                          hint: 'Company / Organization',
                          icon: Icons.business_rounded,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Lead Details'),
                        const SizedBox(height: 16),
                        _buildLabel('Priority'),
                        const SizedBox(height: 10),
                        _buildPrioritySelector(),
                        const SizedBox(height: 16),
                        _buildLabel('Lead Source'),
                        const SizedBox(height: 10),
                        _buildSourceChips(),
                        const SizedBox(height: 16),
                        _buildLabeledField(
                          label: 'Est. Deal Value (₹)',
                          controller: _dealValueController,
                          hint: 'e.g. 50000',
                          icon: Icons.currency_rupee_rounded,
                          keyboard: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Additional Notes'),
                        const SizedBox(height: 16),
                        _buildLabeledField(
                          label: 'Notes',
                          controller: _notesController,
                          hint: 'Any context or additional information...',
                          icon: Icons.sticky_note_2_rounded,
                          maxLines: 4,
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: _border)),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          color: _textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6));

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          keyboardType: keyboard,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: _textSecondary, size: 18),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
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
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    const priorities = ['low', 'medium', 'high'];
    final labels = ['Low', 'Medium', 'High'];
    final icons = [
      Icons.south_rounded,
      Icons.remove_rounded,
      Icons.north_rounded
    ];
    return Row(
      children: List.generate(3, (i) {
        final p = priorities[i];
        final selected = _selectedPriority == p;
        final color = _priorityColor(p);
        final soft = _prioritySoft(p);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: selected ? soft : _surface,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: selected ? color : _border, width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(icons[i],
                      color: selected ? color : _textSecondary, size: 20),
                  const SizedBox(height: 5),
                  Text(labels[i],
                      style: TextStyle(
                          color: selected ? color : _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSourceChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _sources.map((s) {
        final selected = _selectedSource == s['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedSource = s['value']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _accentSoft : _surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: selected ? _accent : _border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s['icon'] as IconData,
                    size: 13, color: selected ? _accent : _textSecondary),
                const SizedBox(width: 6),
                Text(s['label'] as String,
                    style: TextStyle(
                        color: selected ? _accent : _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveLead,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF6EE7B7),
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
                  Text('Submit Lead',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}
