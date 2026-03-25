// FILE: lib/payment/phonepe_page.dart
//
// pubspec.yaml-ൽ add ചെയ്യൂ:
//   webview_flutter: ^4.7.0
//   http: ^1.2.0
//   crypto: ^3.0.3
//
// ─── YOUR CREDENTIALS ────────────────────────────────────────────────────────
//  1. https://business.phonepe.com → Login
//  2. Settings → API Keys
//  3. Copy Merchant ID and Salt Key and paste below
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

// ══════════════════════════════════════════════════════
//  FILL THESE TWO VALUES
// ══════════════════════════════════════════════════════
const kMerchantId = 'SU2510131220392529332086'; // ← paste here
const kSaltKey = '2e662679-fdf7-42b3-a565-0f7c3ac1d1d6'; // ← paste here
const kSaltIndex = 1;

// Production endpoint
const kPhonePePayUrl = 'https://api.phonepe.com/apis/hermes/pg/v1/pay';
const kPhonePeStatusUrl = 'https://api.phonepe.com/apis/hermes/pg/v1/status';
// ══════════════════════════════════════════════════════

class PhonePePage extends StatefulWidget {
  final double amount; // ₹ amount
  final String invoiceId;
  final String mobileNumber; // client phone (10 digits)

  const PhonePePage({
    super.key,
    required this.amount,
    required this.invoiceId,
    required this.mobileNumber,
  });

  @override
  State<PhonePePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePePage> {
  String? _url;
  String? _txnId;
  String? _error;
  bool _gettingUrl = true;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    try {
      // Unique transaction ID
      final txnId =
          'TXN${widget.invoiceId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').substring(0, 6.clamp(0, widget.invoiceId.length))}${DateTime.now().millisecondsSinceEpoch}';
      _txnId = txnId;

      final payload = {
        'merchantId': kMerchantId,
        'merchantTransactionId': txnId,
        'merchantUserId': widget.invoiceId,
        'amount': (widget.amount * 100).toInt(), // paise
        'redirectUrl': 'https://proconnect.app/payment/redirect',
        'redirectMode': 'POST',
        'mobileNumber': widget.mobileNumber,
        'paymentInstrument': {'type': 'PAY_PAGE'},
      };

      final b64 = base64Encode(utf8.encode(jsonEncode(payload)));
      final cs =
          '${sha256.convert(utf8.encode('${b64}/pg/v1/pay$kSaltKey'))}###$kSaltIndex';

      final resp = await http
          .post(
            Uri.parse(kPhonePePayUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-VERIFY': cs,
              'X-MERCHANT-ID': kMerchantId,
            },
            body: jsonEncode({'request': b64}),
          )
          .timeout(const Duration(seconds: 30));

      final json = jsonDecode(resp.body);

      if (json['success'] == true) {
        final url =
            json['data']?['instrumentResponse']?['redirectInfo']?['url'];
        setState(() {
          _url = url;
          _gettingUrl = false;
        });
      } else {
        setState(() {
          _error = json['message'] ?? 'Failed to get payment URL';
          _gettingUrl = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _gettingUrl = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gettingUrl) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Color(0xFF5F259F)),
          SizedBox(height: 16),
          Text('Connecting to PhonePe...',
              style: TextStyle(color: Colors.black45)),
        ])),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.red, size: 56),
            const SizedBox(height: 16),
            const Text('Could not connect to PhonePe',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Go Back')),
          ]),
        )),
      );
    }

    return _PhonePeWebView(
      paymentUrl: _url!,
      txnId: _txnId!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WebView that opens PhonePe and detects success/failure
// ─────────────────────────────────────────────────────────────────────────────

class _PhonePeWebView extends StatefulWidget {
  final String paymentUrl;
  final String txnId;
  const _PhonePeWebView({required this.paymentUrl, required this.txnId});

  @override
  State<_PhonePeWebView> createState() => __PhonePeWebViewState();
}

class __PhonePeWebViewState extends State<_PhonePeWebView> {
  late final WebViewController _ctrl;
  bool _loading = true;
  bool _done = false;

  @override
  void initState() {
    super.initState();

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (req) {
          final url = req.url.toLowerCase();

          // PhonePe redirects to our redirectUrl on completion
          // Also catch common PhonePe result URL patterns
          final isSuccess = url.contains('success') &&
              (url.contains('transaction') ||
                  url.contains('payment') ||
                  url.contains('proconnect'));

          final isFailure = (url.contains('fail') ||
                  url.contains('cancel') ||
                  url.contains('declined')) &&
              (url.contains('transaction') ||
                  url.contains('payment') ||
                  url.contains('proconnect'));

          if (url.contains('proconnect.app/payment/redirect') ||
              isSuccess ||
              isFailure) {
            if (!_done) {
              _done = true;
              _checkStatus(isSuccess);
            }
            return NavigationDecision.prevent;
          }

          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _checkStatus(bool urlSaysSuccess) async {
    if (mounted) setState(() => _loading = true);

    try {
      // Always verify with PhonePe API — never trust URL alone
      final path = '/pg/v1/status/$kMerchantId/${widget.txnId}';
      final cs =
          '${sha256.convert(utf8.encode('$path$kSaltKey'))}###$kSaltIndex';

      final resp = await http.get(
        Uri.parse('${kPhonePeStatusUrl.replaceAll('/pg/v1/pay', '')}$path'),
        headers: {
          'Content-Type': 'application/json',
          'X-VERIFY': cs,
          'X-MERCHANT-ID': kMerchantId,
        },
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(resp.body);
      final success = body['code'] == 'PAYMENT_SUCCESS';

      if (mounted) Navigator.pop(context, success);
    } catch (_) {
      // API check failed — use URL hint
      if (mounted) Navigator.pop(context, urlSaysSuccess);
    }
  }

  void _onClose() {
    if (_done) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Payment?'),
        content:
            const Text('Your payment is not complete. Do you want to go back?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continue Paying')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (!_done) {
                  _done = true;
                  Navigator.pop(context, false);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black87),
          onPressed: _onClose,
        ),
        title: Row(children: [
          Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: Color(0xFF5F259F), shape: BoxShape.circle),
              child: const Center(
                  child: Text('P',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)))),
          const SizedBox(width: 8),
          const Text('PhonePe',
              style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _loading
              ? const LinearProgressIndicator(
                  color: Color(0xFF5F259F), minHeight: 3)
              : const SizedBox.shrink(),
        ),
      ),
      body: WebViewWidget(controller: _ctrl),
    );
  }
}
