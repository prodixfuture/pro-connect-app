// FILE: lib/payment/pay_now_button.dart
//
// USAGE — invoice card-ൽ ഇത് add ചെയ്യൂ:
//
//   PayNowButton(
//     invoiceId: data['id'],
//     invoiceNo: data['invoiceNo'] ?? '',
//     amount:    (data['totalAmount'] ?? data['amount'] ?? 0).toDouble(),
//     clientPhone: '9876543210',
//   )

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'phonepe_page.dart';
import 'payment_success_page.dart';

class PayNowButton extends StatefulWidget {
  final String invoiceId;
  final String invoiceNo;
  final double amount;
  final String clientPhone;

  const PayNowButton({
    super.key,
    required this.invoiceId,
    required this.invoiceNo,
    required this.amount,
    required this.clientPhone,
  });

  @override
  State<PayNowButton> createState() => _PayNowButtonState();
}

class _PayNowButtonState extends State<PayNowButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      const Divider(),
      const SizedBox(height: 8),

      // ── Pay Now button ─────────────────────────────────────────────────
      SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F259F),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade200,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 3,
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  // PhonePe logo
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Center(
                      child: Text('P',
                          style: TextStyle(
                              color: Color(0xFF5F259F),
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pay ₹${widget.amount.toStringAsFixed(2)}  via PhonePe',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ]),
        ),
      ),

      const SizedBox(height: 6),
      const Center(
        child: Text(
          '🔒  UPI · Cards · Net Banking · Wallets',
          style: TextStyle(fontSize: 10, color: Colors.black38),
        ),
      ),
    ]);
  }

  Future<void> _pay() async {
    setState(() => _loading = true);

    // Open PhonePe page
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PhonePePage(
                amount: widget.amount,
                invoiceId: widget.invoiceId,
                mobileNumber: widget.clientPhone,
              )),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (paid == true) {
      // Mark invoice as paid in Firestore
      await _markPaid();

      if (mounted) {
        // Go to success page
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(
                invoiceNo: widget.invoiceNo,
                amount: widget.amount,
              ),
            ));
      }
    }
    // if paid == false or null → user cancelled, do nothing
  }

  Future<void> _markPaid() async {
    final now = FieldValue.serverTimestamp();

    // ── Update invoice status → paid ────────────────────────────────────
    await FirebaseFirestore.instance
        .collection('invoices')
        .doc(widget.invoiceId)
        .update({
      'status': 'paid',
      'paidAt': now,
      'paymentMode': 'PhonePe',
    });

    // ── Create income record for accountant ──────────────────────────────
    // This shows up in the accountant's Income list automatically
    await FirebaseFirestore.instance.collection('income').add({
      'title': 'Invoice Payment - ${widget.invoiceNo}',
      'amount': widget.amount,
      'category': 'Invoice Payment',
      'paymentMode': 'PhonePe',
      'invoiceId': widget.invoiceId,
      'note': 'Online payment via PhonePe',
      'date': now,
      'createdAt': now,
      'isDeleted': false,
    });
  }
}
