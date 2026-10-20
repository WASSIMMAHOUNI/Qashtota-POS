import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/product_visual.dart';
import '../widgets/receipt_dialog.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    itemCount: app.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final c = app.categories[i];
                      final active = c == app.category;
                      final label = c == 'all' ? 'الكل' : c;
                      return ChoiceChip(
                        selected: active,
                        label: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textMedium, fontWeight: FontWeight.w800)),
                        selectedColor: AppColors.gold,
                        backgroundColor: Colors.white,
                        onSelected: (_) => app.setCategory(c),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  textAlign: TextAlign.right,
                  onChanged: app.setSearch,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'ابحث عن منتج...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final maxExtent = width < 560 ? 180.0 : 170.0;
                      return GridView.builder(
                        itemCount: app.visibleProducts.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: maxExtent,
                          mainAxisExtent: width < 560 ? 175 : 190,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemBuilder: (_, i) => _ProductCard(product: app.visibleProducts[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const _CartPanel(),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final out = product.stock <= 0;
    return InkWell(
      onTap: out
          ? null
          : () {
              final msg = context.read<AppState>().addToCart(product);
              if (msg != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: out ? .5 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: product.stock <= 3 ? AppColors.warning : Colors.transparent),
            boxShadow: const [BoxShadow(color: Color(0x140D1F3C), blurRadius: 10)],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: ProductVisual(
                        emoji: product.emoji,
                        imagePath: product.imagePath,
                        size: 84,
                        radius: 14,
                        emojiSize: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(product.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${product.price} DZD', textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: const TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.w900)),
                ],
              ),
              if (product.stock <= 3)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: out ? AppColors.textMedium : AppColors.danger, borderRadius: BorderRadius.circular(12)),
                    child: Text(out ? 'نفد' : 'قليل', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      width: 360,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Text('الطلب الحالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const Spacer(),
                CircleAvatar(radius: 14, backgroundColor: AppColors.gold, child: Text('${app.cartCount}', style: const TextStyle(color: Colors.white, fontSize: 12))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: app.cart.isEmpty
                ? const Center(child: Text('السلة فارغة', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w800)))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: app.cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = app.cart[i];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            ProductVisual(emoji: item.product.emoji, imagePath: item.product.imagePath, size: 36, radius: 10, emojiSize: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  Text('${item.lineTotal} DZD', textDirection: TextDirection.ltr, style: const TextStyle(color: AppColors.goldDark, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                            IconButton(onPressed: () => context.read<AppState>().changeQty(item.product, -1), icon: const Icon(Icons.remove_circle_outline)),
                            Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w900)),
                            IconButton(
                              onPressed: () {
                                final msg = context.read<AppState>().changeQty(item.product, 1);
                                if (msg != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                              },
                              icon: const Icon(Icons.add_circle, color: AppColors.gold),
                            ),
                            IconButton(onPressed: () => context.read<AppState>().removeFromCart(item.product), icon: const Icon(Icons.close, color: AppColors.danger)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.creamMedium))),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      Text('${app.total} DZD', textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppButton(label: 'الدفع', icon: Icons.payment_rounded, height: 56, onPressed: app.cart.isEmpty ? null : () => _showPayDialog(context)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: AppButton(label: 'إلغاء الأخير', background: AppColors.creamDark, foreground: AppColors.textMedium, onPressed: app.cancelLast)),
                    const SizedBox(width: 8),
                    Expanded(child: AppButton(label: 'مسح السلة', background: AppColors.danger.withValues(alpha: .12), foreground: AppColors.danger, onPressed: app.clearCart)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPayDialog(BuildContext context) async {
    final app = context.read<AppState>();
    final controller = TextEditingController(text: app.total.toString());
    String payMethod = 'cash';

    try {
      await showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setLocalState) {
            final isFree = payMethod == 'free';
            return AlertDialog(
            title: const Text('إتمام الدفع', style: TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFree ? 'طلب مجاني' : '${app.total} DZD',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 30, color: isFree ? AppColors.success : AppColors.goldDark, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: payMethod,
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('نقداً')),
                        DropdownMenuItem(value: 'card', child: Text('بطاقة')),
                        DropdownMenuItem(value: 'free', child: Text('مجاني')),
                      ],
                      onChanged: (value) => setLocalState(() => payMethod = value ?? payMethod),
                      decoration: InputDecoration(
                        labelText: 'طريقة الدفع',
                        filled: true,
                        fillColor: AppColors.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      enabled: !isFree,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: isFree ? 'المبلغ المدفوع (غير مطلوب للمجاني)' : 'المبلغ المدفوع',
                        filled: true,
                        fillColor: AppColors.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              AppButton(
                label: 'تأكيد',
                icon: Icons.check_circle,
                onPressed: () async {
                  final paid = int.tryParse(controller.text.trim()) ?? 0;
                  try {
                    final order = await context.read<AppState>().checkout(paid: paid, payMethod: payMethod);
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted) showDialog(context: context, builder: (_) => ReceiptDialog(order: order));
                  } catch (e) {
                    if (!context.mounted) return;
                    final message = e.toString().contains('Insufficient paid amount') ? 'المبلغ المدفوع غير كاف' : 'فشل إتمام الدفع';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  }
                },
              ),
            ],
            );
          },
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}
