import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/page_type.dart';
import 'pages/admin_page.dart';
import 'pages/alerts_page.dart';
import 'pages/analytics_page.dart';
import 'pages/ble_devices_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/gateways_page.dart';
import 'pages/live_tracking_page.dart';
import 'pages/login_page.dart';
import 'pages/mine_zones_page.dart';
import 'pages/personnel_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'pages/shifts_page.dart';
import 'pages/system_health_page.dart';
import 'pages/visitors_page.dart';
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

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Responsive sidebar: auto-collapse on phone widths. Only ever collapses —
    // a manual expand on a small screen is left alone until the width changes.
    final width = MediaQuery.of(context).size.width;
    if (width < 700) context.read<AppState>().setCollapsed(true);
  }

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
        return const GatewaysPage();
      case PageKey.mineZones:
        return const MineZonesPage();
      case PageKey.analytics:
        return const AnalyticsPage();
      case PageKey.shifts:
        return const ShiftsPage();
      case PageKey.visitors:
        return const VisitorsPage();
      case PageKey.auditLogs:
        // Requires an authentication backend the system does not have yet.
        return const PlaceholderPage(
          title: 'Audit Logs',
          icon: Icons.history,
          message: 'Audit logging requires user accounts and sign-in, which the '
              'backend does not implement yet. Every system event is still '
              'recorded on the Alerts page.',
        );
      case PageKey.systemHealth:
        return const SystemHealthPage();
    }
  }
}