import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/product_dialog.dart';
import '../widgets/product_visual.dart';
import '../widgets/recipe_editor_dialog.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Text('إدارة المنتجات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const Spacer(),
              AppButton(label: 'إضافة منتج', icon: Icons.add, onPressed: () => _edit(context)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 980),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('المنتج')),
                          DataColumn(label: Text('الفئة')),
                          DataColumn(label: Text('السعر')),
                          DataColumn(label: Text('المخزون')),
                          DataColumn(label: Text('الحالة')),
                          DataColumn(label: Text('إجراءات')),
                        ],
                        rows: app.products.map((p) {
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 240,
                                  child: Row(
                                    children: [
                                      ProductVisual(emoji: p.emoji, imagePath: p.imagePath, size: 30, radius: 8, emojiSize: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          p.name,
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(Text(p.category)),
                              DataCell(Text('${p.price} DZD', textDirection: TextDirection.ltr)),
                              DataCell(
                                Text(
                                  '${p.stock}',
                                  style: TextStyle(color: p.stock <= 3 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w900),
                                ),
                              ),
                              DataCell(Text(p.stock == 0 ? 'نفد' : p.stock <= 5 ? 'منخفض' : 'متوفر')),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'تعديل الوصفة',
                                      onPressed: () => _editRecipe(context, p),
                                      icon: const Icon(Icons.receipt_long_rounded, color: AppColors.info),
                                    ),
                                    IconButton(
                                      onPressed: () => _edit(context, p),
                                      icon: const Icon(Icons.edit, color: AppColors.goldDark),
                                    ),
                                    IconButton(
                                      onPressed: () => context.read<AppState>().deleteProduct(p.id!),
                                      icon: const Icon(Icons.delete, color: AppColors.danger),
                                    ),
                                  ],
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

  Future<void> _edit(BuildContext context, [Product? product]) async {
    final result = await showDialog<Product>(context: context, builder: (_) => ProductDialog(product: product));
    if (result != null && context.mounted) await context.read<AppState>().saveProduct(result);
  }

  Future<void> _editRecipe(BuildContext context, Product product) async {
    if (product.id == null) return;
    await showDialog(context: context, builder: (_) => RecipeEditorDialog(product: product));
  }
}
