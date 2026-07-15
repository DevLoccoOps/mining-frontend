import 'package:flutter/material.dart';

enum PageKey {
  dashboard,
  liveTracking,
  personnel,
  bleDevices,
  gateways,
  mineZones,
  alerts,
  reports,
  analytics,
  shifts,
  visitors,
  admin,
  auditLogs,
  settings,
  systemHealth,
}

class NavItem {
  final PageKey id;
  final String label;
  final IconData icon;
  const NavItem(this.id, this.label, this.icon);
}

class NavSection {
  final String section;
  final List<NavItem> items;
  const NavSection(this.section, this.items);
}

const navSections = <NavSection>[
  NavSection('Navigation', [
    NavItem(PageKey.dashboard, 'Dashboard', Icons.show_chart),
    NavItem(PageKey.liveTracking, 'Live Tracking', Icons.location_on),
    NavItem(PageKey.personnel, 'Personnel', Icons.group),
  ]),
  NavSection('Devices', [
    NavItem(PageKey.bleDevices, 'BLE Tags', Icons.tag),
    NavItem(PageKey.gateways, 'Gateway Management', Icons.wifi),
    NavItem(PageKey.mineZones, 'Mine Zones', Icons.map_outlined),
  ]),
  NavSection('Operations', [
    NavItem(PageKey.alerts, 'Alerts', Icons.warning_amber_rounded),
    NavItem(PageKey.reports, 'Reports', Icons.description_outlined),
    NavItem(PageKey.analytics, 'Analytics', Icons.bar_chart),
    NavItem(PageKey.shifts, 'Shift Management', Icons.calendar_month),
    NavItem(PageKey.visitors, 'Visitors', Icons.person_add_alt),
  ]),
  NavSection('Administration', [
    NavItem(PageKey.admin, 'Administration', Icons.shield),
    NavItem(PageKey.auditLogs, 'Audit Logs', Icons.history),
    NavItem(PageKey.settings, 'Settings', Icons.settings),
    NavItem(PageKey.systemHealth, 'System Health', Icons.dns),
  ]),
];

extension PageKeyX on PageKey {
  String get title {
    switch (this) {
      case PageKey.gateways:
        return 'Gateway Management';
      case PageKey.mineZones:
        return 'Mine Zones';
      case PageKey.analytics:
        return 'Analytics';
      case PageKey.shifts:
        return 'Shift Management';
      case PageKey.visitors:
        return 'Visitors';
      case PageKey.auditLogs:
        return 'Audit Logs';
      case PageKey.systemHealth:
        return 'System Health';
      default:
        return name;
    }
  }
}