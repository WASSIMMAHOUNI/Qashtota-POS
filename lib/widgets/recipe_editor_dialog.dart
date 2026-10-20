import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/product.dart';
import '../models/product_recipe.dart';
import '../models/supply.dart';
import '../state/app_state.dart';
import 'app_button.dart';

class RecipeEditorDialog extends StatefulWidget {
  final Product product;
  const RecipeEditorDialog({super.key, required this.product});

  @override
  State<RecipeEditorDialog> createState() => _RecipeEditorDialogState();
}

class _RecipeEditorDialogState extends State<RecipeEditorDialog> {
  final Map<int, TextEditingController> _amountControllers = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    final app = context.read<AppState>();
    final lines = await app.getRecipe(widget.product.id!);
    if (!mounted) return;
    for (final line in lines) {
      _amountControllers[line.supplyId] = TextEditingController(text: line.amount.toString());
    }
    setState(() => loading = false);
  }

  @override
  void dispose() {
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final supplies = app.supplies;
    return AlertDialog(
      title: Text('وصفة المنتج - ${widget.product.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 560,
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            : supplies.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('لا توجد مواد أولية. أضف المواد أولاً.'),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: supplies.map((supply) => _line(supply)).toList(),
                    ),
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        if (supplies.isNotEmpty)
          AppButton(
            label: 'حفظ الوصفة',
            icon: Icons.save_rounded,
            onPressed: () async {
              final items = <RecipeInputItem>[];
              for (final supply in supplies) {
                final text = _amountControllers[supply.id!]?.text.trim() ?? '';
                final amount = double.tryParse(text) ?? 0;
                if (amount > 0) {
                  items.add(RecipeInputItem(supplyId: supply.id!, amount: amount));
                }
              }
              await context.read<AppState>().saveRecipe(widget.product.id!, items);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
      ],
    );
  }

  Widget _line(Supply supply) {
    final controller = _amountControllers.putIfAbsent(supply.id!, () => TextEditingController());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supply.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  'المتوفر: ${_num(supply.quantity)} ${supply.unit}',
                  style: const TextStyle(color: AppColors.textLight),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'الكمية/${supply.unit}',
                filled: true,
                fillColor: AppColors.cream,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _num(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
