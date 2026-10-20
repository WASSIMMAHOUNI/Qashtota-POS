import 'package:flutter/material.dart';

import '../core/app_theme.dart';

enum AppScreen { pos, dashboard, stock, supplies, orders, settings }

class Sidebar extends StatelessWidget {
  final AppScreen selected;
  final ValueChanged<AppScreen> onSelected;
  final bool hasLowStock;
  final bool hasLowSupplies;

  const Sidebar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.hasLowStock,
    required this.hasLowSupplies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      color: AppColors.sidebarBg,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Text('ق', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 18),
          _item(AppScreen.pos, Icons.point_of_sale, 'بيع'),
          _item(AppScreen.dashboard, Icons.dashboard_rounded, 'لوحة'),
          _item(AppScreen.stock, Icons.inventory_2_rounded, 'منتجات', dot: hasLowStock),
          _item(AppScreen.supplies, Icons.science_rounded, 'مواد', dot: hasLowSupplies),
          _item(AppScreen.orders, Icons.receipt_long_rounded, 'الطلبات'),
          const Spacer(),
          _item(AppScreen.settings, Icons.settings_rounded, 'إعدادات'),
        ],
      ),
    );
  }

  Widget _item(AppScreen screen, IconData icon, String label, {bool dot = false}) {
    final active = selected == screen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        onTap: () => onSelected(screen),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 60,
          decoration: BoxDecoration(color: active ? AppColors.gold : Colors.transparent, borderRadius: BorderRadius.circular(14)),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: active ? Colors.white : Colors.white54, size: 22),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (dot) const Positioned(top: 8, right: 8, child: CircleAvatar(radius: 4, backgroundColor: AppColors.danger)),
            ],
          ),
        ),
      ),
    );
  }
}
