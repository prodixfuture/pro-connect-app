import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/salary_model.dart';

class SalaryService {
  final _db = FirebaseFirestore.instance;

  static const int latesBeforeDeduction = 5;
  static const List<String> salaryRoles = [
    'staff',
    'manager',
    'admin',
    'accountant',
  ];

  Future<SalaryRecord> generateSalary(String uid, String month) async {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);
    final monthStart = DateTime(year, monthNum, 1);
    final monthEnd = DateTime(year, monthNum + 1, 1);

    // Always use max(30, actualDays) — Feb=28 uses 28, Mar=31 uses 30 cap
    final int actualDays = monthEnd.difference(monthStart).inDays;
    final int totalDaysInMonth = actualDays < 30 ? actualDays : 30;

    // ── Parallel fetch ─────────────────────────────────────────────────────
    final results = await Future.wait([
      _db.collection('users').doc(uid).get(),
      _db.collection('attendance').where('uid', isEqualTo: uid).get(),
      _db
          .collection('leaves')
          .where('uid', isEqualTo: uid)
          .where('status', isEqualTo: 'approved')
          .get(),
    ]);

    final userDoc = results[0] as DocumentSnapshot;
    final attSnap = results[1] as QuerySnapshot;
    final leaveSnap = results[2] as QuerySnapshot;

    final Map<String, dynamic> userData =
        (userDoc.data() as Map<String, dynamic>?) ?? {};

    final double salaryPerMonth = (userData['salaryPerMonth'] ?? 0).toDouble();
    final double perDaySalary = salaryPerMonth / totalDaysInMonth;

    // ── Parse attendance for this month ────────────────────────────────────
    int presentCount = 0;
    int lateCount = 0;
    int halfdayCount = 0;

    for (final doc in attSnap.docs) {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final DateTime? date = _parseDate(data['date']);
      if (date == null) continue;
      if (date.isBefore(monthStart) || !date.isBefore(monthEnd)) continue;

      final String status =
          (data['status'] ?? '').toString().toLowerCase().trim();

      switch (status) {
        case 'present':
          presentCount++;
          break;
        case 'late':
          presentCount++; // late = present day
          lateCount++;
          break;
        case 'halfday':
        case 'half day':
        case 'half-day':
          halfdayCount++;
          break;
        default:
          break;
      }
    }

    // ── Weekly paid leave ──────────────────────────────────────────────────
    // 6-day working week (Mon–Sat), Sunday = weekly off
    // If staff came at least 1 day in the week → earns 1 paid leave (Sunday)
    // If staff was absent the full week → no paid leave for that week
    int earnedPaidLeaves = 0;
    final List<WeekResult> weekResults = [];
    int weekNum = 0;

    for (DateTime weekStart = monthStart;
        weekStart.isBefore(monthEnd);
        weekStart = weekStart.add(const Duration(days: 7))) {
      weekNum++;
      final DateTime weekEnd = weekStart.add(const Duration(days: 7));
      final DateTime effectiveEnd =
          weekEnd.isAfter(monthEnd) ? monthEnd : weekEnd;

      // Count present/late days this week (not halfday)
      int weekPresentDays = 0;
      for (DateTime d = weekStart;
          d.isBefore(effectiveEnd);
          d = d.add(const Duration(days: 1))) {
        final String key = _dateKey(d);
        // Check if this date had present or late status
        bool dayPresent = false;
        for (final doc in attSnap.docs) {
          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          final DateTime? attDate = _parseDate(data['date']);
          if (attDate == null) continue;
          if (_dateKey(attDate) != key) continue;
          final String s =
              (data['status'] ?? '').toString().toLowerCase().trim();
          if (s == 'present' || s == 'late') {
            dayPresent = true;
            break;
          }
        }
        if (dayPresent) weekPresentDays++;
      }

      final bool earned = weekPresentDays >= 1;
      if (earned) earnedPaidLeaves++;

      weekResults.add(WeekResult(
        weekNumber: weekNum,
        presentDays: weekPresentDays,
        earnedLeave: earned,
      ));
    }

    // ── Manager-approved leaves ────────────────────────────────────────────
    int approvedLeaveDays = 0;
    for (final doc in leaveSnap.docs) {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final DateTime? from = _parseDate(data['fromDate']);
      final DateTime? to = _parseDate(data['toDate']);
      if (from == null || to == null) continue;
      for (DateTime d = from;
          !d.isAfter(to);
          d = d.add(const Duration(days: 1))) {
        if (!d.isBefore(monthStart) && d.isBefore(monthEnd)) {
          approvedLeaveDays++;
        }
      }
    }
    // Approved leaves beyond earned paid leaves = unpaid
    final int uncoveredLeaveDays =
        (approvedLeaveDays - earnedPaidLeaves).clamp(0, 999);

    // ── FORMULA ───────────────────────────────────────────────────────────
    //
    // perDaySalary = salaryPerMonth / totalDaysInMonth (max 30)
    //
    // GRAND TOTAL = perDay × (presentDays + lateDays + halfDays + paidLeaves)
    //   where:
    //     present days  → full day each
    //     late days     → already counted in presentDays (full day present)
    //     half days     → 0.5 day each
    //     paid leaves   → full day each (weekly Sunday leave)
    //
    // absentDays = totalDaysInMonth − presentDays − halfDays − paidLeaves − approvedLeaves
    //
    // DEDUCTIONS shown in history (informational breakdown):
    //   present:    presentCount × perDay
    //   late:       lateCount × (perDay / 2)       ← extra late penalty per late
    //   halfday:    halfdayCount × (perDay / 2)
    //   paidLeave:  earnedPaidLeaves × perDay
    //   absent:     absentDays × perDay             ← these are NOT paid
    //
    // Final salary = grand total (what they earned)
    //

    final double absentDays = (totalDaysInMonth.toDouble() -
            presentCount.toDouble() -
            halfdayCount.toDouble() -
            earnedPaidLeaves.toDouble() -
            approvedLeaveDays.toDouble())
        .clamp(0.0, totalDaysInMonth.toDouble());

    // Earned salary components
    final double presentSalary = presentCount.toDouble() * perDaySalary;
    final double halfDaySalary = halfdayCount.toDouble() * 0.5 * perDaySalary;
    final double paidLeaveSalary = earnedPaidLeaves.toDouble() * perDaySalary;

    // Late penalty: each late = half day deduction ON TOP of their present salary
    final double latePenalty = lateCount.toDouble() * (perDaySalary / 2.0);

    // Unpaid approved leave deduction
    final double unpaidLeaveDeduction =
        uncoveredLeaveDays.toDouble() * perDaySalary;

    // Grand total = sum of all earned − penalties
    final double grandTotal = presentSalary +
        halfDaySalary +
        paidLeaveSalary -
        latePenalty -
        unpaidLeaveDeduction;

    final double finalSalary = grandTotal.clamp(0.0, salaryPerMonth);

    final double totalDeduction =
        (salaryPerMonth - finalSalary).clamp(0.0, salaryPerMonth);

    // Absent "cost" for display only
    final double absentDeduction = absentDays * perDaySalary;

    // ── Build record ───────────────────────────────────────────────────────
    final Map<String, dynamic> recordMap = {
      'uid': uid,
      'month': month,
      'totalDaysInMonth': totalDaysInMonth,
      'presentDays': presentCount.toDouble(),
      'absentDays': absentDays,
      'halfdayCount': halfdayCount.toDouble(),
      'lateCount': lateCount,
      'approvedLeaveDays': approvedLeaveDays,
      'earnedPaidLeaves': earnedPaidLeaves,
      'uncoveredLeaveDays': uncoveredLeaveDays,
      'perDaySalary': perDaySalary,
      // breakdown for display
      'presentSalary': presentSalary,
      'halfDaySalary': halfDaySalary,
      'paidLeaveSalary': paidLeaveSalary,
      'latePenalty': latePenalty,
      'unpaidLeaveDeduction': unpaidLeaveDeduction,
      'absentDeduction': absentDeduction,
      'deductionAmount': totalDeduction,
      'finalSalary': finalSalary,
      'salaryPerMonth': salaryPerMonth,
      'weekResults': weekResults.map((w) => w.toMap()).toList(),
      'generatedAt': Timestamp.fromDate(DateTime.now()),
    };

    // ── Upsert ─────────────────────────────────────────────────────────────
    final QuerySnapshot existing = await _db
        .collection('salary_records')
        .where('uid', isEqualTo: uid)
        .where('month', isEqualTo: month)
        .limit(1)
        .get();

    String docId;
    if (existing.docs.isNotEmpty) {
      docId = existing.docs.first.id;
      final String prevStatus = ((existing.docs.first.data()
              as Map<String, dynamic>)['paymentStatus'] ??
          'unpaid') as String;
      await existing.docs.first.reference
          .update({...recordMap, 'paymentStatus': prevStatus});
    } else {
      final DocumentReference ref = await _db
          .collection('salary_records')
          .add({...recordMap, 'paymentStatus': 'unpaid', 'paidAt': null});
      docId = ref.id;
    }

    return SalaryRecord(
      id: docId,
      uid: uid,
      month: month,
      totalDaysInMonth: totalDaysInMonth,
      presentDays: presentCount.toDouble(),
      absentDays: absentDays,
      halfdayCount: halfdayCount.toDouble(),
      lateCount: lateCount,
      approvedLeaveDays: approvedLeaveDays,
      earnedPaidLeaves: earnedPaidLeaves,
      uncoveredLeaveDays: uncoveredLeaveDays,
      perDaySalary: perDaySalary,
      presentSalary: presentSalary,
      halfDaySalary: halfDaySalary,
      paidLeaveSalary: paidLeaveSalary,
      latePenalty: latePenalty,
      unpaidLeaveDeduction: unpaidLeaveDeduction,
      absentDeduction: absentDeduction,
      deductionAmount: totalDeduction,
      finalSalary: finalSalary,
      salaryPerMonth: salaryPerMonth,
      generatedAt: DateTime.now(),
      weekResults: weekResults,
    );
  }

  Future<void> generateSalaryForAll(String month) async {
    final QuerySnapshot snap = await _db.collection('users').get();
    final List<QueryDocumentSnapshot> eligible = snap.docs.where((d) {
      final String role = ((d.data() as Map<String, dynamic>)['role'] ?? '')
          .toString()
          .toLowerCase();
      return salaryRoles.contains(role);
    }).toList();
    await Future.wait(eligible.map((d) => generateSalary(d.id, month)));
  }

  Stream<List<SalaryRecord>> getSalaryRecords(String month) {
    return _db
        .collection('salary_records')
        .where('month', isEqualTo: month)
        .snapshots()
        .map((s) => s.docs.map((d) => SalaryRecord.fromDoc(d)).toList());
  }

  Stream<List<SalaryRecord>> getEmployeeSalaryHistory(String uid) {
    return _db
        .collection('salary_records')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final List<SalaryRecord> list =
          s.docs.map((d) => SalaryRecord.fromDoc(d)).toList();
      list.sort((a, b) => b.month.compareTo(a.month));
      return list;
    });
  }

  Stream<List<SalaryRecord>> getAllMonthlyPayouts() {
    return _db.collection('salary_records').snapshots().map((s) {
      final List<SalaryRecord> list =
          s.docs.map((d) => SalaryRecord.fromDoc(d)).toList();
      list.sort((a, b) => b.month.compareTo(a.month));
      return list;
    });
  }

  Future<void> markSalaryPaid(String id) async {
    await _db.collection('salary_records').doc(id).update({
      'paymentStatus': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markSalaryUnpaid(String id) async {
    await _db.collection('salary_records').doc(id).update({
      'paymentStatus': 'unpaid',
      'paidAt': null,
    });
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
