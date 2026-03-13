import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';

class AccountsService {
  final _db = FirebaseFirestore.instance;

  // ─── Income ───────────────────────────────────────────────────────────────
  Future<void> addIncome({
    required double amount,
    required String category,
    String note = '',
    String paymentMode = 'Cash',
    String reference = '',
    required DateTime date,
  }) async {
    await _db.collection('income').add({
      'amount': amount,
      'category': category,
      'note': note,
      'paymentMode': paymentMode,
      'reference': reference,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateIncome(String id, Map<String, dynamic> data) async {
    await _db.collection('income').doc(id).update(data);
  }

  // Soft delete — marks deleted, only super_admin can purge
  Future<void> deleteIncome(String id) async {
    await _db.collection('income').doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> purgeIncome(String id) async {
    // Hard delete — super_admin only
    await _db.collection('income').doc(id).delete();
  }

  Future<void> restoreIncome(String id) async {
    await _db
        .collection('income')
        .doc(id)
        .update({'isDeleted': false, 'deletedAt': null});
  }

  Stream<List<Map<String, dynamic>>> getMonthlyIncome(String month) {
    final parts = month.split('-');
    final start = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    final end = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 1);
    return _db
        .collection('income')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((m) => m['isDeleted'] != true)
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getDeletedIncome() {
    return _db
        .collection('income')
        .where('isDeleted', isEqualTo: true)
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getAllIncome() {
    return _db
        .collection('income')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => {'id': d.id, ...d.data()})
            .where((m) => m['isDeleted'] != true)
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getTodayIncome() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('income')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ─── Expense ──────────────────────────────────────────────────────────────
  Future<void> addExpense({
    required double amount,
    required String category,
    String note = '',
    String paymentMode = 'Cash',
    String reference = '',
    required DateTime date,
  }) async {
    await _db.collection('expense').add({
      'amount': amount,
      'category': category,
      'note': note,
      'paymentMode': paymentMode,
      'reference': reference,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    await _db.collection('expense').doc(id).update(data);
  }

  Future<void> deleteExpense(String id) async {
    await _db.collection('expense').doc(id).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> purgeExpense(String id) async {
    await _db.collection('expense').doc(id).delete();
  }

  Future<void> restoreExpense(String id) async {
    await _db
        .collection('expense')
        .doc(id)
        .update({'isDeleted': false, 'deletedAt': null});
  }

  Stream<List<Map<String, dynamic>>> getMonthlyExpense(String month) {
    final parts = month.split('-');
    final start = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    final end = DateTime(int.parse(parts[0]), int.parse(parts[1]) + 1, 1);
    return _db
        .collection('expense')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getDeletedExpense() {
    return _db
        .collection('expense')
        .where('isDeleted', isEqualTo: true)
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getAllExpense() {
    return _db
        .collection('expense')
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getTodayExpense() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('expense')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ─── Invoice ──────────────────────────────────────────────────────────────
  Future<void> createInvoice({
    required String clientName,
    required String clientEmail,
    required String clientPhone,
    required String clientAddress,
    required String category,
    String customCategory = '',
    required String title,
    required double amount,
    required double tax,
    String notes = '',
    String paymentMode = 'Bank Transfer',
    required DateTime dueDate,
    required clientId,
  }) async {
    final invoiceNo =
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    await _db.collection('invoices').add({
      'invoiceNo': invoiceNo,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientPhone': clientPhone,
      'clientAddress': clientAddress,
      'category': category,
      'customCategory': customCategory,
      'title': title,
      'amount': amount,
      'tax': tax,
      'totalAmount': amount + (amount * tax / 100),
      'notes': notes,
      'paymentMode': paymentMode,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': 'draft', // always start as draft
      'createdAt': FieldValue.serverTimestamp(),
      'paidAt': null,
    });
  }

  Future<void> sendInvoiceToClient(String id) async {
    await _db.collection('invoices').doc(id).update({
      'status': 'sent',
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateInvoice(String id, Map<String, dynamic> data) async {
    await _db.collection('invoices').doc(id).update(data);
  }

  Future<void> deleteInvoice(String id) async {
    await _db.collection('invoices').doc(id).delete();
  }

  // Mark invoice paid AND auto-add to income list
  Future<void> markInvoicePaid(
    String invoiceId, {
    required String clientName,
    required double totalAmount,
    required DateTime paidDate,
  }) async {
    // 1. Update invoice status
    await _db.collection('invoices').doc(invoiceId).update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      'incomeLinked': true,
    });
    // 2. Auto-add to income collection (from invoice)
    await _db.collection('income').add({
      'amount': totalAmount,
      'category': 'Invoice',
      'note': 'From Invoice — $clientName',
      'paymentMode': 'Invoice',
      'reference': invoiceId,
      'date': Timestamp.fromDate(paidDate),
      'source': 'invoice', // mark as invoice-sourced
      'invoiceId': invoiceId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markInvoiceUnpaid(String invoiceId) async {
    // Get invoice to find linked income entry
    final doc = await _db.collection('invoices').doc(invoiceId).get();
    // Remove linked income entry if it exists
    final incomeSnap = await _db
        .collection('income')
        .where('invoiceId', isEqualTo: invoiceId)
        .get();
    for (final d in incomeSnap.docs) {
      await d.reference.delete();
    }
    await _db.collection('invoices').doc(invoiceId).update({
      'status': 'unpaid',
      'paidAt': null,
      'incomeLinked': false,
    });
  }

  Stream<List<Invoice>> getAllInvoices() {
    return _db
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Invoice.fromDoc(d)).toList());
  }

  Stream<List<Invoice>> getClientInvoices(String clientId) {
    return _db
        .collection('invoices')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Invoice.fromDoc(d)).toList());
  }

  Stream<List<Invoice>> getUnpaidInvoices() {
    return _db
        .collection('invoices')
        .where('status', isEqualTo: 'unpaid')
        .snapshots()
        .map((s) => s.docs.map((d) => Invoice.fromDoc(d)).toList());
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  double sumAmounts(List<Map<String, dynamic>> list) =>
      list.fold(0.0, (s, i) => s + (i['amount'] ?? 0).toDouble());
}
