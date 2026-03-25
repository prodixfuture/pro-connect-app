import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  static const String officeQR = 'PRODIX_QR_ATTENDANCE';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Attendance QR')),
      body: MobileScanner(
        onDetect: (barcode) {
          final code = barcode.barcodes.first.rawValue;

          if (code == officeQR) {
            Navigator.pop(context, true); // valid QR
          }
        },
      ),
    );
  }
}
