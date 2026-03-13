import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CREATE USER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final salaryCtrl = TextEditingController();

  String role = 'staff';
  String department = 'sales';
  bool loading = false;
  bool _obscurePass = true;

  final List<Map<String, String>> _roles = [
    {'value': 'staff', 'label': 'Staff'},
    {'value': 'manager', 'label': 'Manager'},
    {'value': 'admin', 'label': 'Admin'},
    {'value': 'accountant', 'label': 'Accountant'},
    {'value': 'client', 'label': 'Client'},
  ];

  final List<Map<String, String>> _departments = [
    {'value': 'sales', 'label': 'Sales'},
    {'value': 'design', 'label': 'Design'},
    {'value': 'accounts', 'label': 'Accounts'},
    {'value': 'hr', 'label': 'HR'},
    {'value': 'it', 'label': 'IT'},
    {'value': 'operations', 'label': 'Operations'},
  ];

  bool get _showSalary => role != 'client';

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    phoneCtrl.dispose();
    salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
      final salary = double.tryParse(salaryCtrl.text.trim()) ?? 0.0;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'role': role,
        'department': department,
        'status': 'active',
        if (_showSalary) 'salaryPerMonth': salary,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ User created successfully'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Create User',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _SectionCard(title: 'Personal Info', children: [
                _AppField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Name required' : null),
                const SizedBox(height: 12),
                _AppField(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
              ]),
              const SizedBox(height: 14),
              _SectionCard(title: 'Account Info', children: [
                _AppField(
                  controller: emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: _obscurePass,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _SectionCard(title: 'Role & Department', children: [
                _RoleDropdown(
                    value: role,
                    items: _roles,
                    label: 'Role',
                    icon: Icons.badge_outlined,
                    onChanged: (v) => setState(() => role = v!)),
                const SizedBox(height: 12),
                _RoleDropdown(
                    value: department,
                    items: _departments,
                    label: 'Department',
                    icon: Icons.business_outlined,
                    onChanged: (v) => setState(() => department = v!)),
              ]),
              if (_showSalary) ...[
                const SizedBox(height: 14),
                _SectionCard(title: 'Salary', children: [
                  _AppField(
                    controller: salaryCtrl,
                    label: 'Monthly Salary (₹)',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Salary required';
                      if (double.tryParse(v) == null) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  StatefulBuilder(
                    builder: (_, s) => Text(
                      'Per day: ₹${((double.tryParse(salaryCtrl.text) ?? 0) / 26).toStringAsFixed(0)}  •  26 working days/month',
                      style:
                          const TextStyle(color: Colors.black38, fontSize: 11),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : createUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Create User',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT USER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class EditUserScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const EditUserScreen({super.key, required this.uid, required this.userData});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nameCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController salaryCtrl;
  late String role;
  late String department;
  late String status;
  bool loading = false;

  final List<Map<String, String>> _roles = [
    {'value': 'staff', 'label': 'Staff'},
    {'value': 'manager', 'label': 'Manager'},
    {'value': 'admin', 'label': 'Admin'},
    {'value': 'accountant', 'label': 'Accountant'},
    {'value': 'client', 'label': 'Client'},
  ];

  final List<Map<String, String>> _departments = [
    {'value': 'sales', 'label': 'Sales'},
    {'value': 'design', 'label': 'Design'},
    {'value': 'accounts', 'label': 'Accounts'},
    {'value': 'hr', 'label': 'HR'},
    {'value': 'it', 'label': 'IT'},
    {'value': 'operations', 'label': 'Operations'},
  ];

  bool get _showSalary => role != 'client';

  // Valid dropdown values — if Firestore has unknown value, fall back to default
  static const _validRoles = [
    'staff',
    'manager',
    'admin',
    'accountant',
    'client'
  ];
  static const _validDepartments = [
    'sales',
    'design',
    'accounts',
    'hr',
    'it',
    'operations'
  ];
  static const _validStatuses = ['active', 'inactive'];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.userData['name'] ?? '');
    phoneCtrl = TextEditingController(text: widget.userData['phone'] ?? '');
    salaryCtrl = TextEditingController(
        text: (widget.userData['salaryPerMonth'] ?? '').toString());

    final rawRole =
        (widget.userData['role'] ?? '').toString().toLowerCase().trim();
    final rawDept =
        (widget.userData['department'] ?? '').toString().toLowerCase().trim();
    final rawStatus =
        (widget.userData['status'] ?? '').toString().toLowerCase().trim();

    role = _validRoles.contains(rawRole) ? rawRole : 'staff';
    department = _validDepartments.contains(rawDept) ? rawDept : 'sales';
    status = _validStatuses.contains(rawStatus) ? rawStatus : 'active';
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final salary = double.tryParse(salaryCtrl.text.trim()) ?? 0.0;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'role': role,
        'department': department,
        'status': status,
        if (_showSalary) 'salaryPerMonth': salary,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ User updated'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final initName = widget.userData['name'] ?? 'E';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Edit Employee',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile header card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF2196F3).withOpacity(0.15),
                    child: Text(initName[0].toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userData['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(widget.userData['email'] ?? '',
                            style: const TextStyle(
                                color: Colors.black45, fontSize: 12)),
                      ]),
                ]),
              ),
              const SizedBox(height: 14),
              _SectionCard(title: 'Personal Info', children: [
                _AppField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _AppField(
                    controller: phoneCtrl,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
              ]),
              const SizedBox(height: 14),
              _SectionCard(title: 'Role & Department', children: [
                _RoleDropdown(
                  value: role,
                  items: _roles,
                  label: 'Role',
                  icon: Icons.badge_outlined,
                  onChanged: (v) => setState(() => role = v!),
                ),
                const SizedBox(height: 12),
                _RoleDropdown(
                  value: department,
                  items: _departments,
                  label: 'Department',
                  icon: Icons.business_outlined,
                  onChanged: (v) => setState(() => department = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    prefixIcon: const Icon(Icons.toggle_on_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (v) => setState(() => status = v!),
                ),
              ]),
              if (_showSalary) ...[
                const SizedBox(height: 14),
                _SectionCard(title: 'Salary', children: [
                  _AppField(
                    controller: salaryCtrl,
                    label: 'Monthly Salary (₹)',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Per day: ₹${((double.tryParse(salaryCtrl.text) ?? 0) / 26).toStringAsFixed(0)}  •  26 working days/month',
                    style: const TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                ]),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _update,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAFF SALARY VIEW (read-only, for staff role)
// ─────────────────────────────────────────────────────────────────────────────
class StaffSalaryScreen extends StatelessWidget {
  final String uid;
  const StaffSalaryScreen({super.key, required this.uid});

  String _monthLabel(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    const names = [
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
    final m = int.tryParse(parts[1]) ?? 1;
    return '${names[(m - 1).clamp(0, 11)]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Salary',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('salary_records')
            .where('uid', isEqualTo: uid)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          docs.sort((a, b) {
            final ma = (a.data() as Map)['month'] ?? '';
            final mb = (b.data() as Map)['month'] ?? '';
            return mb.compareTo(ma);
          });

          if (docs.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.payments_outlined, size: 64, color: Colors.black26),
                SizedBox(height: 12),
                Text('No salary records yet',
                    style: TextStyle(color: Colors.black45)),
              ]),
            );
          }

          final latestData = docs.first.data() as Map<String, dynamic>;
          final latestSalary = (latestData['finalSalary'] ?? 0).toDouble();
          final latestMonth = latestData['month'] ?? '';
          final isPaid = latestData['paymentStatus'] == 'paid';
          final totalReceived = docs
              .where((d) => (d.data() as Map)['paymentStatus'] == 'paid')
              .fold(
                  0.0,
                  (s, d) =>
                      s + ((d.data() as Map)['finalSalary'] ?? 0).toDouble());

          return Column(
            children: [
              // Hero card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPaid
                        ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                        : [const Color(0xFF1E88E5), const Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_monthLabel(latestMonth),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('₹${latestSalary.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          isPaid ? '✅ Salary Credited' : '⏳ Payment Pending',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      _WhiteStat(
                          label: 'Present',
                          value: (latestData['presentDays'] ?? 0)
                              .toStringAsFixed(0)),
                      const SizedBox(width: 20),
                      _WhiteStat(
                          label: 'Absent',
                          value: (latestData['absentDays'] ?? 0)
                              .toStringAsFixed(1)),
                      const SizedBox(width: 20),
                      _WhiteStat(
                          label: 'Total Received',
                          value: '₹${totalReceived.toStringAsFixed(0)}'),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(children: [
                  const Text('Salary History',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Text('${docs.length} months',
                      style:
                          const TextStyle(color: Colors.black38, fontSize: 12)),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final salary = (data['finalSalary'] ?? 0).toDouble();
                    final month = data['month'] ?? '';
                    final paid = data['paymentStatus'] == 'paid';
                    final paidAt = data['paidAt'] != null
                        ? (data['paidAt'] as Timestamp).toDate()
                        : null;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: paid
                            ? Border.all(color: Colors.green.withOpacity(0.3))
                            : null,
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_monthLabel(month),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  'Present: ${(data['presentDays'] ?? 0).toStringAsFixed(0)}  •  Deduction: ₹${(data['deductionAmount'] ?? 0).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Colors.black45, fontSize: 11),
                                ),
                                if (paid && paidAt != null)
                                  Text(
                                      'Paid on ${paidAt.day}/${paidAt.month}/${paidAt.year}',
                                      style: const TextStyle(
                                          color: Colors.green, fontSize: 11)),
                              ]),
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${salary.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF2196F3))),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: paid
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(paid ? 'PAID' : 'PENDING',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: paid
                                            ? Colors.green
                                            : Colors.orange)),
                              ),
                            ]),
                      ]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black54)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _AppField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final String value;
  final List<Map<String, String>> items;
  final String label;
  final IconData icon;
  final void Function(String?) onChanged;

  const _RoleDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items
          .map((r) =>
              DropdownMenuItem(value: r['value'], child: Text(r['label']!)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _WhiteStat extends StatelessWidget {
  final String label;
  final String value;
  const _WhiteStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }
}
