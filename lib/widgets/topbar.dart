import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';

class TopBar extends StatelessWidget {
  final String title;
  const TopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.creamMedium))),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(20)),
            child: const Text('إمبراطور القشطوطة ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
            child: Text(DateFormat('HH:mm').format(DateTime.now()), style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(backgroundColor: AppColors.brown, child: Text('ص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

