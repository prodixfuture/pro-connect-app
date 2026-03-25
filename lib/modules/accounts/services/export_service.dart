import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  // ================= COMMON CSV =================

  static Future<void> exportCSV({
    required BuildContext context,
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
  }) async {
    try {
      _showLoading(context, 'Generating CSV...');

      final allRows = [headers, ...rows];
      final csvData = const ListToCsvConverter().convert(allRows);

      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(csvData.codeUnits),
            name: '$fileName.csv',
            mimeType: 'text/csv',
          ),
        ],
        text: title,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showError(context, e.toString());
      }
    }
  }

  // ================= COMMON PDF =================

  static Future<void> exportPDF({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
    List<_SummaryItem>? summaryItems,
  }) async {
    try {
      _showLoading(context, 'Generating PDF...');

      final pdf = pw.Document();
      final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('1976D2'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title,
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(subtitle,
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColor(1, 1, 1, 0.7))),
                  pw.SizedBox(height: 4),
                  pw.Text('Generated: $now',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColor(1, 1, 1, 0.6))),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            if (summaryItems != null && summaryItems.isNotEmpty) ...[
              pw.Row(
                children: summaryItems.map((s) {
                  final baseColor = PdfColor.fromHex(s.hexColor);
                  return pw.Expanded(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(right: 8),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor(
                          baseColor.red + (1 - baseColor.red) * 0.85,
                          baseColor.green + (1 - baseColor.green) * 0.85,
                          baseColor.blue + (1 - baseColor.blue) * 0.85,
                        ),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(s.label,
                              style:
                                  pw.TextStyle(fontSize: 9, color: baseColor)),
                          pw.SizedBox(height: 4),
                          pw.Text(s.value,
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: baseColor)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 16),
            ],
            if (rows.isEmpty)
              pw.Text('No data available.')
            else
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: rows
                    .map((r) => r.map((c) => c.toString()).toList())
                    .toList(),
              ),
          ],
        ),
      );

      final bytes = await pdf.save();

      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: '$fileName.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        text: title,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showError(context, e.toString());
      }
    }
  }

  // ================= FORMAT HELPERS =================

  static String _fmtDate(dynamic ts) {
    if (ts == null) return '';
    final date = ts is Timestamp ? ts.toDate() : ts as DateTime;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String _fmtAmt(dynamic v) => '₹${(v ?? 0).toStringAsFixed(2)}';

  // ================= INCOME =================

  static Future<void> exportIncomeCSV(BuildContext context,
      List<Map<String, dynamic>> data, String period) async {
    await exportCSV(
      context: context,
      title: 'Income Report — $period',
      headers: ['Date', 'Category', 'Payment Mode', 'Amount'],
      rows: data
          .map((i) => [
                _fmtDate(i['date']),
                i['category'] ?? '',
                i['paymentMode'] ?? '',
                _fmtAmt(i['amount'])
              ])
          .toList(),
      fileName: 'income_$period',
    );
  }

  static Future<void> exportIncomePDF(
      BuildContext context, List<Map<String, dynamic>> data, String period,
      {double total = 0}) async {
    await exportPDF(
      context: context,
      title: 'Income Report',
      subtitle: 'Period: $period',
      headers: ['Date', 'Category', 'Payment Mode', 'Amount'],
      rows: data
          .map((i) => [
                _fmtDate(i['date']),
                i['category'] ?? '',
                i['paymentMode'] ?? '',
                _fmtAmt(i['amount'])
              ])
          .toList(),
      fileName: 'income_$period',
      summaryItems: [
        _SummaryItem(
            label: 'Total Income', value: _fmtAmt(total), hexColor: '43A047'),
      ],
    );
  }

  // ================= ERROR / LOADING =================

  static void _showLoading(BuildContext context, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  static void _showError(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export Failed'),
        content: Text(error),
      ),
    );
  }

  static Future<void> exportExpensePDF(BuildContext context,
      List<Map<String, dynamic>> expenseData, String filterLabel,
      {required double total}) async {}

  static Future<void> exportExpenseCSV(BuildContext context,
      List<Map<String, dynamic>> expenseData, String replaceAll) async {}

  static Future<void> exportSalaryPDF(BuildContext context,
      List<Map<String, dynamic>> salaryData, String filterLabel,
      {required double total}) async {}

  static Future<void> exportSalaryCSV(BuildContext context,
      List<Map<String, dynamic>> salaryData, String replaceAll) async {}

  static Future<void> exportOverviewPDF(
      {required BuildContext context,
      required String period,
      required double totalIncome,
      required double totalExpense,
      required double totalSalary,
      required double netProfit,
      required List<Map<String, dynamic>> incomeData,
      required List<Map<String, dynamic>> expenseData}) async {}
}

class _SummaryItem {
  final String label;
  final String value;
  final String hexColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.hexColor,
  });
}
