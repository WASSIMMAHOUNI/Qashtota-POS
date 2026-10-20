import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order.dart';

const _arabicFontAsset = 'assets/fonts/NotoNaskhArabic-Regular.ttf';

Future<Uint8List> buildReceiptPdf(PosOrder receipt) async {
  final fontData = await rootBundle.load(_arabicFontAsset);
  final arabicFont = pw.Font.ttf(fontData);
  final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFont);
  final doc = pw.Document(theme: theme);
  final money = NumberFormat.decimalPattern('ar');

  String amount(int value) => '${money.format(value)} DZD';

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.roll80.copyWith(
        marginLeft: 5 * PdfPageFormat.mm,
        marginRight: 5 * PdfPageFormat.mm,
        marginTop: 4 * PdfPageFormat.mm,
        marginBottom: 5 * PdfPageFormat.mm,
      ),
      textDirection: pw.TextDirection.rtl,
      build: (context) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text('قشطوطة', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('فاتورة نقطة البيع', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
              _divider(),
              _row('رقم الطلب', '#${receipt.id ?? '-'}'),
              _row('التاريخ', DateFormat('yyyy/MM/dd HH:mm').format(receipt.createdAt)),
              _row('الدفع', _paymentLabel(receipt)),
              if (receipt.isFree) ...[
                pw.SizedBox(height: 4),
                pw.Text('طلب مجاني', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
              _divider(),
              ...receipt.items.map((item) => _itemRow(item, amount)),
              _divider(),
              _row('المجموع الفرعي', amount(receipt.subtotal)),
              _row('الضريبة', amount(receipt.tax)),
              _row('الإجمالي', amount(receipt.total), big: true),
              _row('المدفوع', amount(receipt.paid)),
              _row('الباقي', amount(receipt.change)),
              pw.SizedBox(height: 10),
              pw.Text('شكراً لزيارتكم!', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  print('PDF generated: ${bytes.length} bytes');
  return bytes;
}

Future<bool> printReceipt(PosOrder receipt) async {
  try {
    final bytes = await buildReceiptPdf(receipt);
    final printed = await Printing.layoutPdf(
      name: 'receipt-${receipt.id ?? DateTime.now().millisecondsSinceEpoch}.pdf',
      format: PdfPageFormat.roll80,
      onLayout: (_) async => bytes,
    );
    print('Print dialog/spooler called');
    return printed;
  } catch (error, stackTrace) {
    print('Receipt printing failed: $error');
    print(stackTrace);
    rethrow;
  }
}

String _paymentLabel(PosOrder receipt) {
  if (receipt.isFree) return 'مجاني';
  return receipt.payMethod == 'cash' ? 'نقداً' : 'بطاقة';
}

pw.Widget _divider() => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      child: pw.Divider(thickness: .6),
    );

pw.Widget _row(String label, String value, {bool big = false}) {
  final style = pw.TextStyle(fontSize: big ? 12 : 9, fontWeight: big ? pw.FontWeight.bold : pw.FontWeight.normal);
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.SizedBox(width: 6),
        pw.Text(value, textDirection: pw.TextDirection.ltr, style: style),
      ],
    ),
  );
}

pw.Widget _itemRow(OrderItem item, String Function(int value) amount) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Text(
            '${item.name} ×${item.qty}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(amount(item.lineTotal), textDirection: pw.TextDirection.ltr, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}
