import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/app_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إعدادات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 1200
                    ? 2
                    : width >= 760
                        ? 2
                        : 1;
                final ratio = crossAxisCount == 1 ? 1.8 : 2.15;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: ratio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    const _SettingsCard(
                      title: 'معلومات المحل',
                      rows: ['اسم المحل: قشطوطة', 'العنوان: الجزائر العاصمة', 'الهاتف: 0550 123 456'],
                    ),
                    const _SettingsCard(
                      title: 'الإعدادات المالية',
                      rows: ['العملة: DZD', 'الضريبة: 0%', 'خصم الموظفين: 10%'],
                    ),
                    const _SettingsCard(
                      title: 'إعدادات الطابعة',
                      rows: ['الطابعة: Epson TM-T20', 'طباعة تلقائية: مفعلة', 'نسخ الفاتورة: 1'],
                    ),
                    const _SettingsCard(
                      title: 'المظهر',
                      rows: ['الوضع: فاتح', 'حجم الخط: متوسط', 'اللغة: العربية'],
                    ),
                    _DatabaseCard(
                      busy: busy,
                      onExport: _exportDatabase,
                      onImport: _restoreDatabase,
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

  Future<void> _exportDatabase() async {
    final now = DateTime.now();
    final name = 'qashtota_backup_${DateFormat('yyyyMMdd_HHmmss').format(now)}.db';
    final targetPath = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ نسخة احتياطية',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: const ['db'],
    );
    if (targetPath == null || !mounted) return;

    setState(() => busy = true);
    try {
      await context.read<AppState>().exportDatabase(targetPath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تصدير قاعدة البيانات بنجاح')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تصدير قاعدة البيانات')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _restoreDatabase() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'استيراد نسخة احتياطية',
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['db', 'sqlite', 'sqlite3'],
    );
    final sourcePath = picked?.files.single.path;
    if (sourcePath == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('استعادة قاعدة البيانات'),
        content: const Text('سيتم استبدال البيانات الحالية بالكامل. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          AppButton(label: 'استعادة', icon: Icons.restore_rounded, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => busy = true);
    try {
      await context.read<AppState>().restoreDatabase(sourcePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت استعادة قاعدة البيانات بنجاح')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل استعادة قاعدة البيانات')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final List<String> rows;
  const _SettingsCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(r, style: const TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatabaseCard extends StatelessWidget {
  final bool busy;
  final Future<void> Function() onExport;
  final Future<void> Function() onImport;

  const _DatabaseCard({
    required this.busy,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('النسخ الاحتياطي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('تصدير أو استيراد ملف قاعدة البيانات.', style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w700)),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'تصدير',
                  icon: Icons.download_rounded,
                  onPressed: busy ? null : onExport,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'استيراد',
                  icon: Icons.upload_file_rounded,
                  background: AppColors.creamDark,
                  foreground: AppColors.textMedium,
                  onPressed: busy ? null : onImport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
