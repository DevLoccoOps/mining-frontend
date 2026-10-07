import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/page_type.dart';
import '../data/mock_data.dart';
import '../models/alert_item.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final collapsed = app.collapsed;
    final page = app.currentPage;
    final width = collapsed ? 64.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1F3A),
        border: Border(right: BorderSide(color: Color(0x11FFFFFF))),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x11FFFFFF)))),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('MineTrack', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.1)),
                        Text('Personnel Tracking', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 9, fontWeight: FontWeight.w500, height: 1.2)),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left, color: const Color(0x66FFFFFF), size: 16),
                  onPressed: app.toggleCollapsed,
                  tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                ),
              ],
            ),
          ),
          // Nav
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: navSections.expand((sec) => _section(context, sec, collapsed, page)).toList(),
            ),
          ),
          // Footer
          Container(
            padding: EdgeInsets.all(collapsed ? 8 : 16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x11FFFFFF)))),
            child: collapsed
                ? const Center(child: _PulseDot())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          _PulseDot(),
                          SizedBox(width: 8),
                          Text('Server Online', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Version 1.0 · InnovAI Technologies',
                          style: TextStyle(color: Color(0x99BFDBFE), fontSize: 10)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _section(BuildContext context, NavSection sec, bool collapsed, PageKey active) {
    final app = context.read<AppState>();
    final items = <Widget>[];
    if (!collapsed) {
      items.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          sec.section.toUpperCase(),
          style: const TextStyle(color: Color(0x9960A5FA), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5),
        ),
      ));
    }
    for (final item in sec.items) {
      final isActive = active == item.id;
      final alertCount = item.id == PageKey.alerts
          ? alerts.where((a) => a.status != AlertStatus.closed).length
          : null;
      items.add(_navItem(item, isActive, collapsed, app, alertCount));
    }
    if (!collapsed) items.add(const SizedBox(height: 8));
    return items;
  }

  Widget _navItem(NavItem item, bool active, bool collapsed, AppState app, int? alertCount) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => app.setPage(item.id),
        hoverColor: const Color(0x0AFFFFFF),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0x332563EB) : null,
            border: active
                ? const Border(left: BorderSide(color: Color(0xFF60A5FA), width: 2))
                : const Border(left: BorderSide(color: Colors.transparent, width: 2)),
          ),
          child: Row(
            children: [
              Icon(item.icon,
                  size: 16, color: active ? const Color(0xFF60A5FA) : const Color(0x99BFDBFE)),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0x99BFDBFE),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (alertCount != null && alertCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(999)),
                    child: Text('$alertCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honor the platform "reduce motion" setting: render a steady dot instead of pulsing.
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce && _animating) {
      _c.stop();
      _animating = false;
    } else if (!reduce && !_animating) {
      _c.repeat(reverse: true);
      _animating = true;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.4 + 0.6 * _c.value,
        child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
      ),
    );
  }
}