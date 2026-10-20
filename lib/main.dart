import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/supplies_screen.dart';
import 'state/app_state.dart';
import 'widgets/sidebar.dart';
import 'widgets/topbar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QashtotaApp());
}

class QashtotaApp extends StatelessWidget {
  const QashtotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'إمبراطور القشطوطة',
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Shell(),
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  AppScreen selected = AppScreen.pos;

  String get title => switch (selected) {
        AppScreen.pos => 'خزينة',
        AppScreen.dashboard => 'لوحة التحكم',
        AppScreen.stock => 'إدارة المنتجات',
        AppScreen.supplies => 'مواد',
        AppScreen.orders => 'الطلبات',
        AppScreen.settings => 'إعدادات',
      };

  Widget get body => switch (selected) {
        AppScreen.pos => const PosScreen(),
        AppScreen.dashboard => const DashboardScreen(),
        AppScreen.stock => const StockScreen(),
        AppScreen.supplies => const SuppliesScreen(),
        AppScreen.orders => const OrdersScreen(),
        AppScreen.settings => const SettingsScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: app.loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Sidebar(
                  selected: selected,
                  hasLowStock: app.hasLowStock,
                  hasLowSupplies: app.hasLowSupplies,
                  onSelected: (s) => setState(() => selected = s),
                ),
                Expanded(
                  child: Column(
                    children: [
                      TopBar(title: title),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

