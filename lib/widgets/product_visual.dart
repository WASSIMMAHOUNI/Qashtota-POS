import 'dart:io';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class ProductVisual extends StatelessWidget {
  final String emoji;
  final String? imagePath;
  final double size;
  final double radius;
  final double emojiSize;

  const ProductVisual({
    super.key,
    required this.emoji,
    this.imagePath,
    required this.size,
    this.radius = 12,
    this.emojiSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(radius)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? Image.file(
              File(imagePath!),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(emoji, style: TextStyle(fontSize: emojiSize)),
            )
          : Text(emoji, style: TextStyle(fontSize: emojiSize)),
    );
  }
}
