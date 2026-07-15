import 'package:flutter/material.dart' hide Badge;

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/badge.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final sections = [
      (Icons.group, 'User Management', 'Manage system users, roles and permissions', ['Users', 'Roles', 'Permissions']),
      (Icons.map_outlined, 'Mine Configuration', 'Zones, gateways, and layout settings', ['Mine Layout', 'Zone Config', 'Gateway Config']),
      (Icons.notifications_none_rounded, 'Notification Rules', 'Configure Email, SMS and WhatsApp alerts', ['Email Rules', 'SMS Rules', 'WhatsApp']),
      (Icons.storage, 'Data Management', 'Retention policies and backup schedules', ['Data Retention', 'Backups', 'Archive']),
      (Icons.vpn_key, 'API & Integrations', 'API keys and third-party integrations', ['API Keys', 'Webhooks', 'OAuth Apps']),
      (Icons.public, 'Departments', 'Manage company departments and shifts', ['Departments', 'Shift Schedules', 'Contractors']),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Administration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
          Text('System configuration and management', style: TextStyle(fontSize: 13, color: t.muted)),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1280 ? 3 : c.maxWidth > 760 ? 2 : 1;
              const spacing = 16.0;
              final cards = sections.map((s) => _sectionCard(s, t)).toList();
              final List<Widget> rows = [];
              for (var i = 0; i < cards.length; i += cols) {
                final rowChildren = <Widget>[];
                for (var j = i; j < cards.length && j < i + cols; j++) {
                  if (rowChildren.isNotEmpty) rowChildren.add(const SizedBox(width: spacing));
                  rowChildren.add(Expanded(child: cards[j]));
                }
                final remainder = cards.length - i;
                if (remainder < cols) {
                  for (var k = 0; k < cols - remainder; k++) {
                    rowChildren.add(const SizedBox(width: spacing));
                    rowChildren.add(const Expanded(child: SizedBox()));
                  }
                }
                if (rows.isNotEmpty) rows.add(const SizedBox(height: spacing));
                rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren));
              }
              return Column(mainAxisSize: MainAxisSize.min, children: rows);
            },
          ),
          const SizedBox(height: 20),
          // Audit logs
          Container(
            decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text('Recent Audit Logs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                      const Spacer(),
                      TextButton(onPressed: () {}, child: const Text('View All')),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...auditLogs.map((log) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text(log.time, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: t.muted)),
                          ),
                          Badge(
                              label: log.type,
                              color: log.type == 'Alert'
                                  ? BadgeColor.red
                                  : log.type == 'Create'
                                      ? BadgeColor.green
                                      : log.type == 'System'
                                          ? BadgeColor.purple
                                          : BadgeColor.blue),
                          const SizedBox(width: 12),
                          Expanded(child: Text(log.action, style: TextStyle(fontSize: 12, color: t.fg))),
                          Text(log.user, style: TextStyle(fontSize: 11, color: t.muted)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard((IconData, String, String, List<String>) s, SurfaceTokens t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: Icon(s.$1, size: 18, color: AppColors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                    const SizedBox(height: 2),
                    Text(s.$3, style: TextStyle(fontSize: 11, color: t.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...s.$4.map((item) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(item, style: TextStyle(fontSize: 13, color: t.fg)),
                trailing: const Icon(Icons.chevron_right, size: 13),
                onTap: () {},
              )),
        ],
      ),
    );
  }
}