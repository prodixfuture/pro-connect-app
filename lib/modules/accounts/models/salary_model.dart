import 'package:cloud_firestore/cloud_firestore.dart';

class WeekResult {
  final int weekNumber;
  final int presentDays;
  final bool earnedLeave;

  const WeekResult({
    required this.weekNumber,
    required this.presentDays,
    required this.earnedLeave,
  });

  Map<String, dynamic> toMap() => {
        'weekNumber': weekNumber,
        'presentDays': presentDays,
        'earnedLeave': earnedLeave,
      };

  static WeekResult fromMap(Map<String, dynamic> m) => WeekResult(
        weekNumber: (m['weekNumber'] ?? 0).toInt(),
        presentDays: (m['presentDays'] ?? 0).toInt(),
        earnedLeave: m['earnedLeave'] ?? false,
      );
}

class SalaryRecord {
  final String id;
  final String uid;
  final String month;
  final int totalDaysInMonth;
  final double presentDays;
  final double absentDays;
  final double halfdayCount;
  final int lateCount;
  final int approvedLeaveDays;
  final int earnedPaidLeaves;
  final int uncoveredLeaveDays;
  final double perDaySalary;
  // Breakdown for history display
  final double presentSalary;
  final double halfDaySalary;
  final double paidLeaveSalary;
  final double latePenalty;
  final double unpaidLeaveDeduction;
  final double absentDeduction;
  final double deductionAmount;
  final double finalSalary;
  final double salaryPerMonth;
  final DateTime generatedAt;
  final String paymentStatus;
  final DateTime? paidAt;
  final List<WeekResult> weekResults;

  SalaryRecord({
    required this.id,
    required this.uid,
    required this.month,
    this.totalDaysInMonth = 30,
    required this.presentDays,
    required this.absentDays,
    this.halfdayCount = 0,
    this.lateCount = 0,
    this.approvedLeaveDays = 0,
    this.earnedPaidLeaves = 0,
    this.uncoveredLeaveDays = 0,
    this.perDaySalary = 0,
    this.presentSalary = 0,
    this.halfDaySalary = 0,
    this.paidLeaveSalary = 0,
    this.latePenalty = 0,
    this.unpaidLeaveDeduction = 0,
    this.absentDeduction = 0,
    required this.deductionAmount,
    required this.finalSalary,
    required this.salaryPerMonth,
    required this.generatedAt,
    this.paymentStatus = 'unpaid',
    this.paidAt,
    this.weekResults = const [],
  });

  bool get isPaid => paymentStatus == 'paid';

  factory SalaryRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawWeeks = d['weekResults'] as List<dynamic>? ?? [];
    final weeks = rawWeeks
        .map((w) => WeekResult.fromMap(w as Map<String, dynamic>))
        .toList();

    return SalaryRecord(
      id: doc.id,
      uid: d['uid'] ?? '',
      month: d['month'] ?? '',
      totalDaysInMonth: (d['totalDaysInMonth'] ?? 30).toInt(),
      presentDays: (d['presentDays'] ?? 0).toDouble(),
      absentDays: (d['absentDays'] ?? 0).toDouble(),
      halfdayCount: (d['halfdayCount'] ?? 0).toDouble(),
      lateCount: (d['lateCount'] ?? 0).toInt(),
      approvedLeaveDays: (d['approvedLeaveDays'] ?? 0).toInt(),
      earnedPaidLeaves: (d['earnedPaidLeaves'] ?? 0).toInt(),
      uncoveredLeaveDays: (d['uncoveredLeaveDays'] ?? 0).toInt(),
      perDaySalary: (d['perDaySalary'] ?? 0).toDouble(),
      presentSalary: (d['presentSalary'] ?? 0).toDouble(),
      halfDaySalary: (d['halfDaySalary'] ?? 0).toDouble(),
      paidLeaveSalary: (d['paidLeaveSalary'] ?? 0).toDouble(),
      latePenalty: (d['latePenalty'] ?? 0).toDouble(),
      unpaidLeaveDeduction: (d['unpaidLeaveDeduction'] ?? 0).toDouble(),
      absentDeduction: (d['absentDeduction'] ?? 0).toDouble(),
      deductionAmount: (d['deductionAmount'] ?? 0).toDouble(),
      finalSalary: (d['finalSalary'] ?? 0).toDouble(),
      salaryPerMonth: (d['salaryPerMonth'] ?? 0).toDouble(),
      generatedAt: (d['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentStatus: d['paymentStatus'] ?? 'unpaid',
      paidAt: (d['paidAt'] as Timestamp?)?.toDate(),
      weekResults: weeks,
    );
  }
}
