import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final String invoiceNo;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;
  final String category;
  final String customCategory;
  final String title;
  final double amount;
  final double tax;
  final double totalAmount;
  final String notes;
  final String paymentMode;
  final String status; // draft | sent | paid
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? sentAt;
  final DateTime? paidAt;

  Invoice({
    required this.id,
    this.invoiceNo = '',
    this.clientId = '',
    this.clientName = '',
    this.clientEmail = '',
    this.clientPhone = '',
    this.clientAddress = '',
    this.category = 'Monthly Package',
    this.customCategory = '',
    required this.title,
    required this.amount,
    this.tax = 0,
    this.totalAmount = 0,
    this.notes = '',
    this.paymentMode = 'Bank Transfer',
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.sentAt,
    this.paidAt,
  });

  // ── Status getters ────────────────────────────────────────────────────────
  bool get isPaid => status == 'paid';
  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get canEdit => status == 'draft'; // locked after sending

  double get effectiveTotal => totalAmount > 0 ? totalAmount : amount;

  factory Invoice.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    // Legacy support: old records may have status 'unpaid' — treat as sent
    String rawStatus = d['status'] ?? 'draft';
    if (rawStatus == 'unpaid') rawStatus = 'sent';

    return Invoice(
      id: doc.id,
      invoiceNo: d['invoiceNo'] ?? '',
      clientId: d['clientId'] ?? '',
      clientName: d['clientName'] ?? '',
      clientEmail: d['clientEmail'] ?? '',
      clientPhone: d['clientPhone'] ?? '',
      clientAddress: d['clientAddress'] ?? '',
      category: d['category'] ?? 'Monthly Package',
      customCategory: d['customCategory'] ?? '',
      title: d['title'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      tax: (d['tax'] ?? 0).toDouble(),
      totalAmount: (d['totalAmount'] ?? d['amount'] ?? 0).toDouble(),
      notes: d['notes'] ?? '',
      paymentMode: d['paymentMode'] ?? 'Bank Transfer',
      status: rawStatus,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      paidAt: (d['paidAt'] as Timestamp?)?.toDate(),
    );
  }
}
