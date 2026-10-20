import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/order.dart';
import '../state/app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    final todayOrders = app.orders.where((o) => !o.createdAt.isBefore(startOfToday) && !o.createdAt.isAfter(now)).toList();
    final weekOrders = app.orders.where((o) => !o.createdAt.isBefore(startOfWeek) && !o.createdAt.isAfter(now)).toList();

    final sales = todayOrders.fold(0, (s, o) => s + o.total);
    final weeklySales = weekOrders.fold(0, (s, o) => s + o.total);
    final lowProducts = app.products.where((p) => p.stock <= 3).length;
    final lowSupplies = app.supplies.where((s) => s.quantity <= s.minQuantity).length;
    final topSelling = _topSellingLines(todayOrders);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('لوحة التحكم', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1400
                  ? 5
                  : width >= 1100
                      ? 4
                      : width >= 850
                          ? 3
                          : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: width >= 1100 ? 1.5 : 1.25,
                children: [
                  _stat('مبيعات اليوم', '$sales DZD', Icons.payments_rounded, AppColors.gold),
                  _stat('عدد طلبات اليوم', '${todayOrders.length}', Icons.shopping_bag_rounded, AppColors.success),
                  _stat('مبيعات الأسبوع', '$weeklySales DZD', Icons.analytics_rounded, AppColors.info),
                  _stat('منتجات منخفضة', '$lowProducts', Icons.warning_rounded, AppColors.danger),
                  _stat('قيمة الطلبات المجانية', '${app.freeOrdersValue} DZD', Icons.card_giftcard_rounded, AppColors.textMedium),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (lowSupplies > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
              child: Text(
                'تنبيه: يوجد $lowSupplies مواد أولية عند الحد الأدنى أو أقل.',
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800),
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1200;
                if (compact) {
                  return ListView(
                    children: [
                      _card('الأكثر مبيعاً', topSelling),
                      const SizedBox(height: 12),
                      _card('تنبيهات المخزون المنخفض', app.products.where((p) => p.stock <= 3).map((p) => '${p.emoji} ${p.name} - ${p.stock}').toList()),
                      const SizedBox(height: 12),
                      _card(
                        'تنبيهات المواد الأولية',
                        app.supplies.where((s) => s.quantity <= s.minQuantity).map((s) => '${s.name}: ${_num(s.quantity)} ${s.unit}').toList(),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: _card('الأكثر مبيعاً', topSelling)),
                    const SizedBox(width: 16),
                    Expanded(child: _card('تنبيهات المخزون المنخفض', app.products.where((p) => p.stock <= 3).map((p) => '${p.emoji} ${p.name} - ${p.stock}').toList())),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _card(
                        'تنبيهات المواد الأولية',
                        app.supplies.where((s) => s.quantity <= s.minQuantity).map((s) => '${s.name}: ${_num(s.quantity)} ${s.unit}').toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x120D1F3C), blurRadius: 12)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: .15), child: Icon(icon, color: color)),
            const SizedBox(height: 8),
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(label, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w700)),
              ),
            ),
            Text(value, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      );

  List<String> _topSellingLines(List<PosOrder> todayOrders) {
    final byProduct = <int, ({String name, String emoji, int qty})>{};
    for (final item in todayOrders.expand((o) => o.items)) {
      final current = byProduct[item.productId];
      if (current == null) {
        byProduct[item.productId] = (name: item.name, emoji: item.emoji, qty: item.qty);
      } else {
        byProduct[item.productId] = (name: current.name, emoji: current.emoji, qty: current.qty + item.qty);
      }
    }
    final sorted = byProduct.values.toList()..sort((a, b) => b.qty.compareTo(a.qty));
    return sorted.take(5).map((p) => '${p.emoji} ${p.name} ×${p.qty}').toList();
  }

  Widget _card(String title, List<String> lines) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Expanded(
              child: lines.isEmpty
                  ? const Center(child: Text('لا توجد بيانات', style: TextStyle(color: AppColors.textLight)))
                  : ListView.builder(
                      itemCount: lines.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Text(lines[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
            ),
          ],
        ),
      );

  static String _num(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
