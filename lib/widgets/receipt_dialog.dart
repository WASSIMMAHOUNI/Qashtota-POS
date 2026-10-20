import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/order.dart';
import '../services/receipt_print_service.dart';
import 'app_button.dart';
import 'product_visual.dart';

class ReceiptDialog extends StatelessWidget {
  final PosOrder order;
  const ReceiptDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('الفاتورة', style: TextStyle(fontWeight: FontWeight.w900)),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.62),
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(18)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('قشطوطة', style: TextStyle(fontSize: 28, color: AppColors.goldDark, fontWeight: FontWeight.w900)),
                const Text('فاتورة نقطة البيع'),
                const Divider(height: 28),
                _row('رقم الطلب', '#${order.id ?? '-'}'),
                _row('التاريخ', DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt)),
                _row('الدفع', order.isFree ? 'مجاني' : (order.payMethod == 'cash' ? 'نقداً' : 'بطاقة')),
                if (order.isFree)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .15), borderRadius: BorderRadius.circular(10)),
                    child: const Text('طلب مجاني', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w900)),
                  ),
                const Divider(height: 28),
                ...order.items.map(_itemRow),
                const Divider(height: 28),
                _row('المجموع الفرعي', '${order.subtotal} DZD'),
                _row('الضريبة', '${order.tax} DZD'),
                _row('الإجمالي', '${order.total} DZD', big: true),
                _row('المدفوع', '${order.paid} DZD'),
                _row('الباقي', '${order.change} DZD', color: AppColors.success),
                const SizedBox(height: 14),
                const Text('شكراً لزيارتكم!'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppButton(label: 'إغلاق', icon: Icons.close, background: AppColors.creamDark, foreground: AppColors.textMedium, onPressed: () => Navigator.pop(context)),
        AppButton(
          label: 'طباعة تجريبية',
          icon: Icons.print_rounded,
          background: AppColors.brown,
          onPressed: () => _print(context),
        ),
      ],
    );
  }

  Future<void> _print(BuildContext context) async {
    print('Print button clicked');
    try {
      final printed = await printReceipt(order);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(printed ? 'تم إرسال الفاتورة للطباعة' : 'تم إلغاء الطباعة')),
      );
    } catch (error, stackTrace) {
      print('Print exception: $error');
      print(stackTrace);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الطباعة: $error')));
    }
  }

  Widget _itemRow(OrderItem item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ProductVisual(emoji: item.emoji, imagePath: item.imagePath, size: 24, radius: 6, emojiSize: 14),
            const SizedBox(width: 8),
            Expanded(child: Text('${item.name} ×${item.qty}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark))),
            Text('${item.lineTotal} DZD', textDirection: ui.TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textDark)),
          ],
        ),
      );

  Widget _row(String a, String b, {bool big = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(a, style: TextStyle(fontWeight: big ? FontWeight.w900 : FontWeight.w700, fontSize: big ? 18 : 14, color: color ?? AppColors.textDark))),
            Text(b, textDirection: ui.TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: big ? 18 : 14, color: color ?? AppColors.textDark)),
          ],
        ),
      );
}
