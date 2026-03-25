import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LeaveRequestScreen extends StatefulWidget {
  final String? editId;
  final Map<String, dynamic>? existingData;

  const LeaveRequestScreen({super.key, this.editId, this.existingData});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? startDate;
  DateTime? endDate;
  bool oneDay = false;
  bool halfDay = false;
  String leaveType = "Annual Leave";
  bool isSubmitting = false;

  final leaveTypes = [
    {"name": "Annual Leave", "icon": Icons.calendar_today_outlined},
    {"name": "Sick Leave", "icon": Icons.medical_services_outlined},
    {"name": "Emergency Leave", "icon": Icons.warning_amber_outlined},
    {"name": "Casual Leave", "icon": Icons.beach_access_outlined},
  ];

  // Leave balances (you can fetch these from Firestore)
  Map<String, double> leaveBalances = {
    "Annual Leave": 15.0,
    "Sick Leave": 10.0,
    "Emergency Leave": 5.0,
    "Casual Leave": 12.0,
  };

  @override
  void initState() {
    super.initState();
    _loadLeaveBalances();

    if (widget.existingData != null) {
      final d = widget.existingData!;
      startDate = (d['startDate'] as Timestamp).toDate();
      endDate = (d['endDate'] as Timestamp).toDate();
      leaveType = d['leaveType'];
      halfDay = d['isHalfDay'] ?? false;
      reasonCtrl.text = d['reason'] ?? '';
      oneDay = startDate == endDate;
    }
  }

  Future<void> _loadLeaveBalances() async {
    // Fetch used leaves for current year
    final yearStart = DateTime(DateTime.now().year, 1, 1);
    final yearEnd = DateTime(DateTime.now().year, 12, 31);

    final snapshot = await FirebaseFirestore.instance
        .collection('leaves')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(yearEnd))
        .get();

    Map<String, double> usedLeaves = {
      "Annual Leave": 0,
      "Sick Leave": 0,
      "Emergency Leave": 0,
      "Casual Leave": 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = data['leaveType'] as String;
      final days = (data['days'] ?? 0).toDouble();
      usedLeaves[type] = (usedLeaves[type] ?? 0) + days;
    }

    setState(() {
      leaveBalances = {
        "Annual Leave": 15.0 - (usedLeaves["Annual Leave"] ?? 0),
        "Sick Leave": 10.0 - (usedLeaves["Sick Leave"] ?? 0),
        "Emergency Leave": 5.0 - (usedLeaves["Emergency Leave"] ?? 0),
        "Casual Leave": 12.0 - (usedLeaves["Casual Leave"] ?? 0),
      };
    });
  }

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  double totalDays() {
    if (startDate == null) return 0;
    if (oneDay) return halfDay ? 0.5 : 1;
    if (endDate == null) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }

  Future pickDateRange() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      startDate = picked;
      if (oneDay) {
        endDate = picked;
      } else if (endDate == null || endDate!.isBefore(picked)) {
        endDate = picked;
      }
    });
  }

  Future pickEndDate() async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select start date first")),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate!,
      firstDate: startDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  bool validateForm() {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select start date"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return false;
    }

    if (!oneDay && endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select end date"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return false;
    }

    final days = totalDays();
    final balance = leaveBalances[leaveType] ?? 0;

    if (days > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Insufficient leave balance. Available: $balance days",
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return false;
    }

    if (reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please provide a reason"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return false;
    }

    return true;
  }

  Future submit() async {
    if (!validateForm()) return;

    setState(() => isSubmitting = true);

    try {
      final data = {
        'uid': uid,
        'leaveType': leaveType,
        'startDate': Timestamp.fromDate(startDate!),
        'endDate': Timestamp.fromDate(oneDay ? startDate! : endDate!),
        'isHalfDay': halfDay,
        'days': totalDays(),
        'reason': reasonCtrl.text.trim(),
        'status': 'pending',
        'appliedAt': Timestamp.now(),
      };

      if (widget.editId != null) {
        await FirebaseFirestore.instance
            .collection('leaves')
            .doc(widget.editId)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('leaves').add(data);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(widget.editId != null
                  ? "Leave updated successfully"
                  : "Leave applied successfully"),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBalance = leaveBalances[leaveType] ?? 0;
    final days = totalDays();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editId != null ? "Edit Leave" : "Apply Leave",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leave Type Selection
              const Text(
                "Leave Type",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: leaveTypes.map((type) {
                    final isSelected = leaveType == type['name'];
                    return InkWell(
                      onTap: () =>
                          setState(() => leaveType = type['name'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1).withOpacity(0.1)
                              : Colors.transparent,
                          border: Border(
                            bottom: leaveTypes.last != type
                                ? BorderSide(color: Colors.grey[200]!)
                                : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                type['icon'] as IconData,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type['name'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF6366F1)
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF6366F1),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Date Selection
              const Text(
                "Duration",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // One Day Checkbox
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: CheckboxListTile(
                  value: oneDay,
                  onChanged: (v) => setState(() {
                    oneDay = v!;
                    if (oneDay && startDate != null) {
                      endDate = startDate;
                    }
                  }),
                  title: const Text(
                    "Single Day Leave",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  activeColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Start Date
              InkWell(
                onTap: pickDateRange,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Start Date",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              startDate == null
                                  ? "Select start date"
                                  : DateFormat('EEEE, dd MMM yyyy')
                                      .format(startDate!),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: startDate == null
                                    ? Colors.grey[400]
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),

              // End Date
              if (!oneDay) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: pickEndDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.event_outlined,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "End Date",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                endDate == null
                                    ? "Select end date"
                                    : DateFormat('EEEE, dd MMM yyyy')
                                        .format(endDate!),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: endDate == null
                                      ? Colors.grey[400]
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Half Day Checkbox
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: CheckboxListTile(
                  value: halfDay,
                  onChanged: (v) => setState(() => halfDay = v!),
                  title: const Text(
                    "Half Day",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text("Apply for half day leave"),
                  activeColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Reason
              const Text(
                "Reason",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: reasonCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Enter reason for leave...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Leave Summary",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Days:",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          "${days.toStringAsFixed(1)} day(s)",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded),
                            const SizedBox(width: 8),
                            Text(
                              widget.editId != null
                                  ? "Update Leave"
                                  : "Submit Leave Request",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
