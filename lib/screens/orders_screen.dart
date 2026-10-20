import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/receipt_dialog.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'الطلبات',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text('${app.orders.length} طلب مسجل', style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              AppButton(
                label: 'مسح الكل',
                icon: Icons.delete_sweep_rounded,
                background: AppColors.danger.withValues(alpha: .14),
                foreground: AppColors.danger,
                onPressed: app.orders.isEmpty ? null : () => _confirmClearAllOrders(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: app.orders.isEmpty
                  ? const Center(child: Text('لا توجد طلبات بعد'))
                  : Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 980),
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('رقم الطلب')),
                                DataColumn(label: Text('التاريخ')),
                                DataColumn(label: Text('المنتجات')),
                                DataColumn(label: Text('الإجمالي')),
                                DataColumn(label: Text('الدفع')),
                                DataColumn(label: Text('تفاصيل')),
                                DataColumn(label: Text('حذف')),
                              ],
                              rows: app.orders.map((o) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          Text('#${o.id}', style: const TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.w900)),
                                          if (o.isFree)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: .15), borderRadius: BorderRadius.circular(10)),
                                              child: const Text('مجاني', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 10)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(DateFormat('yyyy/MM/dd HH:mm').format(o.createdAt))),
                                    DataCell(
                                      SizedBox(
                                        width: 220,
                                        child: Text(
                                          o.items.map((i) => i.name).join('، '),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text('${o.total} DZD', textDirection: ui.TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900))),
                                    DataCell(Text(o.isFree ? 'مجاني' : (o.payMethod == 'cash' ? 'نقداً' : 'بطاقة'))),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.search, color: AppColors.goldDark),
                                        onPressed: () => showDialog(context: context, builder: (_) => ReceiptDialog(order: o)),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.danger),
                                        onPressed: () => _confirmDeleteOrder(context, o.id!),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteOrder(BuildContext context, int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الطلب'),
        content: Text('هل تريد حذف الطلب #$orderId؟ سيتم إرجاع كميات المنتجات والمواد الأولية.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          AppButton(label: 'حذف', icon: Icons.delete, background: AppColors.danger, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AppState>().deleteOrder(orderId);
  }

  Future<void> _confirmClearAllOrders(BuildContext context) async {
    final app = context.read<AppState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مسح جميع الطلبات'),
        content: Text('سيتم حذف ${app.orders.length} طلب وإرجاع الكميات حيث يمكن. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          AppButton(label: 'مسح الكل', icon: Icons.warning_rounded, background: AppColors.danger, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AppState>().clearAllOrders();
  }
}
