import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_theme.dart';
import '../models/product.dart';
import 'app_button.dart';
import 'product_visual.dart';

class ProductDialog extends StatefulWidget {
  final Product? product;
  const ProductDialog({super.key, this.product});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  late final TextEditingController name;
  late final TextEditingController price;
  late final TextEditingController stock;
  late final TextEditingController emoji;
  late String category;
  String? imagePath;
  bool pickingImage = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    name = TextEditingController(text: product?.name ?? '');
    price = TextEditingController(text: product?.price.toString() ?? '');
    stock = TextEditingController(text: product?.stock.toString() ?? '');
    emoji = TextEditingController(text: product?.emoji ?? '');
    category = product?.category ?? 'قشطوطة';
    imagePath = product?.imagePath;
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    stock.dispose();
    emoji.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emojiValue = emoji.text.trim().isEmpty ? '🍮' : emoji.text.trim();
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.product == null ? 'إضافة منتج جديد' : 'تعديل المنتج', style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('اسم المنتج', name),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: category,
                    items: const [
                      DropdownMenuItem(value: 'قشطوطة', child: Text('قشطوطة')),
                      DropdownMenuItem(value: 'مولوخينو', child: Text('مولوخينو')),
                      DropdownMenuItem(value: 'كريب', child: Text('كريب')),
                      DropdownMenuItem(value: 'كيك بوم', child: Text('كيك بوم')),
                      DropdownMenuItem(value: 'كشري', child: Text('كشري')),
                      DropdownMenuItem(value: 'إضافات', child: Text('إضافات')),
                    ],
                    onChanged: (value) => setState(() => category = value ?? category),
                    decoration: _decoration('الفئة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _field('السعر DZD', price, number: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field('المخزون', stock, number: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('الإيموجي (بديل)', emoji, onChanged: (_) => setState(() {}))),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'اختيار صورة',
                    icon: Icons.image_rounded,
                    background: AppColors.creamDark,
                    foreground: AppColors.textMedium,
                    onPressed: pickingImage ? null : _pickImage,
                  ),
                ),
                const SizedBox(width: 12),
                ProductVisual(emoji: emojiValue, imagePath: imagePath, size: 56, radius: 14, emojiSize: 28),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        AppButton(
          label: 'حفظ المنتج',
          icon: Icons.save_rounded,
          onPressed: () {
            final productName = name.text.trim();
            final productPrice = int.tryParse(price.text.trim()) ?? 0;
            final productStock = int.tryParse(stock.text.trim()) ?? 0;
            if (productName.isEmpty || productPrice <= 0 || productStock < 0) return;
            Navigator.pop(
              context,
              Product(
                id: widget.product?.id,
                name: productName,
                category: category,
                price: productPrice,
                stock: productStock,
                emoji: emojiValue,
                imagePath: imagePath,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, {bool number = false, ValueChanged<String>? onChanged}) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
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

  Future<void> _pickImage() async {
    setState(() => pickingImage = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: false);
      final selectedPath = result?.files.single.path;
      if (selectedPath == null) return;
      final appDir = await getApplicationSupportDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'product_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final extension = p.extension(selectedPath);
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}${extension.isEmpty ? '.png' : extension}';
      final copiedPath = p.join(imagesDir.path, fileName);
      await File(selectedPath).copy(copiedPath);
      if (!mounted) return;
      setState(() => imagePath = copiedPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر اختيار الصورة')));
    } finally {
      if (mounted) {
        setState(() => pickingImage = false);
      }
    }
  }
}

