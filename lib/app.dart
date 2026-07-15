import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/page_type.dart';
import 'pages/admin_page.dart';
import 'pages/alerts_page.dart';
import 'pages/ble_devices_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/live_tracking_page.dart';
import 'pages/login_page.dart';
import 'pages/personnel_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'theme/app_theme.dart';
import 'widgets/placeholder_page.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';

class MineTrackApp extends StatelessWidget {
  const MineTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return MaterialApp(
      title: 'MineTrack — Personnel Tracking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: app.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: app.isLoggedIn ? const _Shell() : const LoginPage(),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: _page(app.currentPage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _page(PageKey key) {
    switch (key) {
      case PageKey.dashboard:
        return const DashboardPage();
      case PageKey.liveTracking:
        return const LiveTrackingPage();
      case PageKey.personnel:
        return const PersonnelPage();
      case PageKey.bleDevices:
        return const BLEDevicesPage();
      case PageKey.alerts:
        return const AlertsPage();
      case PageKey.reports:
        return const ReportsPage();
      case PageKey.admin:
        return const AdminPage();
      case PageKey.settings:
        return const SettingsPage();
      case PageKey.gateways:
        return PlaceholderPage(title: key.title, icon: Icons.wifi);
      case PageKey.mineZones:
        return PlaceholderPage(title: key.title, icon: Icons.map_outlined);
      case PageKey.analytics:
        return PlaceholderPage(title: key.title, icon: Icons.bar_chart);
      case PageKey.shifts:
        return PlaceholderPage(title: key.title, icon: Icons.calendar_month);
      case PageKey.visitors:
        return PlaceholderPage(title: key.title, icon: Icons.person_add_alt);
      case PageKey.auditLogs:
        return PlaceholderPage(title: key.title, icon: Icons.history);
      case PageKey.systemHealth:
        return PlaceholderPage(title: key.title, icon: Icons.dns);
    }
  }
}