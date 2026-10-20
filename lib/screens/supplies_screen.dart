import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/supply.dart';
import '../state/app_state.dart';
import '../widgets/app_button.dart';

class SuppliesScreen extends StatelessWidget {
  const SuppliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const Text('مواد', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const Spacer(),
              AppButton(label: 'إضافة مادة', icon: Icons.add, onPressed: () => _openEditor(context)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: app.supplies.isEmpty
                  ? const Center(child: Text('لا توجد مواد أولية بعد'))
                  : Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 980),
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('الاسم')),
                                DataColumn(label: Text('الوحدة')),
                                DataColumn(label: Text('الكمية')),
                                DataColumn(label: Text('الحد الأدنى')),
                                DataColumn(label: Text('تكلفة الوحدة')),
                                DataColumn(label: Text('الحالة')),
                                DataColumn(label: Text('إجراءات')),
                              ],
                              rows: app.supplies.map((supply) {
                                final low = supply.quantity <= supply.minQuantity;
                                return DataRow(
                                  cells: [
                                    DataCell(Text(supply.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                                    DataCell(Text(supply.unit)),
                                    DataCell(Text('${_num(supply.quantity)} ${supply.unit}', textDirection: TextDirection.ltr)),
                                    DataCell(Text(_num(supply.minQuantity), textDirection: TextDirection.ltr)),
                                    DataCell(Text(_num(supply.cost), textDirection: TextDirection.ltr)),
                                    DataCell(
                                      Text(
                                        low ? 'منخفض' : 'جيد',
                                        style: TextStyle(color: low ? AppColors.danger : AppColors.success, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(onPressed: () => _openEditor(context, supply), icon: const Icon(Icons.edit, color: AppColors.goldDark)),
                                          IconButton(onPressed: () => context.read<AppState>().deleteSupply(supply.id!), icon: const Icon(Icons.delete, color: AppColors.danger)),
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

  static String _num(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  Future<void> _openEditor(BuildContext context, [Supply? supply]) async {
    final result = await showDialog<Supply>(
      context: context,
      builder: (_) => _SupplyEditorDialog(supply: supply),
    );
    if (result != null && context.mounted) {
      await context.read<AppState>().saveSupply(result);
    }
  }
}

class _SupplyEditorDialog extends StatefulWidget {
  final Supply? supply;
  const _SupplyEditorDialog({this.supply});

  @override
  State<_SupplyEditorDialog> createState() => _SupplyEditorDialogState();
}

class _SupplyEditorDialogState extends State<_SupplyEditorDialog> {
  late final TextEditingController name;
  late final TextEditingController quantity;
  late final TextEditingController minQuantity;
  late final TextEditingController cost;
  String unit = 'g';

  @override
  void initState() {
    super.initState();
    final supply = widget.supply;
    name = TextEditingController(text: supply?.name ?? '');
    quantity = TextEditingController(text: supply == null ? '' : supply.quantity.toString());
    minQuantity = TextEditingController(text: supply == null ? '' : supply.minQuantity.toString());
    cost = TextEditingController(text: supply == null ? '' : supply.cost.toString());
    unit = supply?.unit ?? 'g';
  }

  @override
  void dispose() {
    name.dispose();
    quantity.dispose();
    minQuantity.dispose();
    cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.supply == null ? 'إضافة مادة أولية' : 'تعديل مادة أولية', style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('الاسم', name),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: unit,
              items: const [
                DropdownMenuItem(value: 'g', child: Text('g')),
                DropdownMenuItem(value: 'ml', child: Text('ml')),
                DropdownMenuItem(value: 'piece', child: Text('قطعة')),
              ],
              onChanged: (value) => setState(() => unit = value ?? unit),
              decoration: _decoration('الوحدة'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field('الكمية', quantity, number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field('الحد الأدنى', minQuantity, number: true)),
              ],
            ),
            const SizedBox(height: 10),
            _field('تكلفة الوحدة (اختياري)', cost, number: true),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        AppButton(
          label: 'حفظ',
          icon: Icons.save_rounded,
          onPressed: () {
            final supplyName = name.text.trim();
            final q = double.tryParse(quantity.text.trim()) ?? -1;
            final minQ = double.tryParse(minQuantity.text.trim()) ?? 0;
            final c = double.tryParse(cost.text.trim()) ?? 0;
            if (supplyName.isEmpty || q < 0 || minQ < 0 || c < 0) return;
            Navigator.pop(
              context,
              Supply(
                id: widget.supply?.id,
                name: supplyName,
                unit: unit,
                quantity: q,
                minQuantity: minQ,
                cost: c,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {bool number = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: _decoration(label),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.cream,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }
}
