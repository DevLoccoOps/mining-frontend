import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/worker.dart';

/// Interactive mine map. viewBox 820 x 520 (matches the original SVG).
class MineMap extends StatefulWidget {
  final Worker? hoveredWorker;
  final ValueChanged<Worker?> onHover;
  final Worker? selectedWorker;
  final ValueChanged<Worker>? onTap;
  final String? layer; // null | "heatmap" | "gas"

  const MineMap({
    super.key,
    this.hoveredWorker,
    required this.onHover,
    this.selectedWorker,
    this.onTap,
    this.layer,
  });

  @override
  State<MineMap> createState() => _MineMapState();
}

class _MineMapState extends State<MineMap> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _emergency;
  bool _animating = false;
  static const viewW = 820.0, viewH = 520.0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _emergency = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honor the platform "reduce motion" setting: static map instead of pulsing rings.
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce && _animating) {
      _pulse.stop();
      _emergency.stop();
      _animating = false;
    } else if (!reduce && !_animating) {
      _pulse.repeat();
      _emergency.repeat(reverse: true);
      _animating = true;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _emergency.dispose();
    super.dispose();
  }

  Worker? _hitTest(Offset local, BoxConstraints c) {
    final sx = c.maxWidth / viewW;
    final sy = c.maxHeight / viewH;
    for (final w in workers) {
      final dx = (local.dx - w.x * sx);
      final dy = (local.dy - w.y * sy);
      if (dx * dx + dy * dy <= (14 * ((sx + sy) / 2)) * (14 * ((sx + sy) / 2))) {
        return w;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return MouseRegion(
          onExit: (_) => widget.onHover(null),
          onHover: (e) {
            final w = _hitTest(e.localPosition, c);
            widget.onHover(w);
          },
          child: GestureDetector(
            onTapUp: (d) {
              final w = _hitTest(d.localPosition, c);
              if (w != null && widget.onTap != null) widget.onTap!(w);
            },
            onPanUpdate: (d) {
              final w = _hitTest(d.localPosition, c);
              widget.onHover(w);
            },
            child: ClipRect(
              child: CustomPaint(
                size: Size(c.maxWidth, c.maxHeight),
                painter: _MinePainter(
                  pulse: _pulse,
                  emergency: _emergency,
                  hoveredId: widget.hoveredWorker?.id,
                  selectedId: widget.selectedWorker?.id,
                  layer: widget.layer,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MinePainter extends CustomPainter {
  final Animation<double> pulse;
  final Animation<double> emergency;
  final int? hoveredId;
  final int? selectedId;
  final String? layer;

  _MinePainter({
    required this.pulse,
    required this.emergency,
    this.hoveredId,
    this.selectedId,
    this.layer,
  }) : super(repaint: Listenable.merge([pulse, emergency]));

  static const tunnelBg = Color(0xFF0E2035);
  static const tunnelWall = Color(0xFF1B3A5C);
  static const tunnelFloor = Color(0xFF234872);
  static const labelColor = Color(0xFF7FB3D3);
  static const grid = Color(0xFF112033);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / viewW;
    final sy = size.height / viewH;
    canvas.scale(sx, sy);

    // Background
    final bgPaint = Paint()..color = tunnelBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, viewW, viewH), bgPaint);

    // Grid
    final gridPaint = Paint()..color = grid..strokeWidth = 1;
    for (final x in [80.0, 200.0, 320.0, 440.0, 560.0, 680.0, 760.0]) {
      canvas.drawLine(Offset(x, 10), Offset(x, 510), gridPaint);
    }
    for (final y in [60.0, 140.0, 220.0, 300.0, 380.0, 460.0]) {
      canvas.drawLine(Offset(10, y), Offset(810, y), gridPaint);
    }

    // Layer overlays (gas / heatmap)
    if (layer == 'gas') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(104, 340, 56, 112), Radius.circular(8)),
        Paint()..color = const Color(0xFFEA0000).withOpacity(0.18),
      );
    } else if (layer == 'heatmap') {
      _radial(canvas, const Offset(410, 312), 200, 120, const Color(0xFFEF4444).withOpacity(0.20));
      _radial(canvas, const Offset(287, 156), 140, 100, const Color(0xFF3B82F6).withOpacity(0.20));
      _radial(canvas, const Offset(600, 156), 120, 100, const Color(0xFF3B82F6).withOpacity(0.15));
    }

    // Main Shaft
    _roundedRect(canvas, const Rect.fromLTWH(398, 28, 24, 466), tunnelWall, 4);
    _roundedRect(canvas, const Rect.fromLTWH(403, 28, 14, 466), tunnelFloor, 3);
    // Headframe
    _roundedRect(canvas, const Rect.fromLTWH(388, 18, 44, 18), const Color(0xFF2563EB), 4, opacity: 0.85);
    _text(canvas, 'SHAFT', const Offset(410, 31), Colors.white, 9, bold: true, center: true);

    // Levels
    _level(canvas, 55, 143, 710, 24, 'LEVEL 1 — 250m depth', 139);
    _level(canvas, 55, 283, 710, 24, 'LEVEL 2 — 400m depth', 279);
    _level(canvas, 55, 428, 630, 24, 'LEVEL 3 — 550m depth', 423);

    // Tunnels
    _tunnel(canvas, 182, 143, 20, 164, 'TUNNEL A', const Offset(178, 230), alignEnd: true);
    _tunnel(canvas, 122, 283, 20, 169, 'TUNNEL B', const Offset(118, 368), alignEnd: true);
    _tunnel(canvas, 604, 283, 20, 169, 'TUNNEL C', const Offset(638, 368), alignEnd: false);

    // Ventilation Shaft
    _roundedRect(canvas, const Rect.fromLTWH(662, 28, 20, 440), const Color(0xFF1A3355), 3);
    _roundedRect(canvas, const Rect.fromLTWH(666, 28, 12, 440), const Color(0xFF22405F), 2);

    // Pump Station
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(55, 428, 68, 64), const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFF1A3355)
        ..style = PaintingStyle.fill
        ..strokeWidth = 1,
    );
    _text(canvas, 'PUMP', const Offset(89, 465), const Color(0xFF93C5FD), 8, bold: true, center: true);
    _text(canvas, 'STATION', const Offset(89, 476), const Color(0xFF93C5FD), 8, center: true);

    // Main Junction marker
    canvas.drawCircle(
      const Offset(410, 295),
      14,
      Paint()
        ..color = const Color(0xFF1E3A5F)
        ..style = PaintingStyle.fill
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      const Offset(410, 295),
      14,
      Paint()
        ..color = const Color(0xFF3B82F6).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _text(canvas, 'MAIN JUNCTION', const Offset(410, 333), const Color(0xFF93C5FD), 8, bold: true, center: true);

    // Escape route
    final escapePaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // dashed line
    _dashedLine(canvas, const Offset(450, 440), const Offset(684, 440), escapePaint, dash: 6, gap: 4);
    _text(canvas, '▶ ESCAPE ROUTE', const Offset(565, 456), const Color(0xFF22C55E), 8, bold: true, center: true);

    // Restricted zone
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(104, 340, 56, 112), const Radius.circular(4)),
      Paint()..color = const Color(0xFFEF4444).withOpacity(0.18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(104, 340, 56, 112), const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFEF4444).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _text(canvas, '⚠ GAS', const Offset(132, 394), const Color(0xFFFCA5A5), 8, bold: true, center: true);
    _text(canvas, 'RESTRICTED', const Offset(132, 405), const Color(0xFFFCA5A5), 7, center: true);

    // Assembly points
    for (final p in [const Offset(740, 155), const Offset(740, 440)]) {
      canvas.drawCircle(p, 14, Paint()..color = const Color(0xFF22C55E).withOpacity(0.2));
      canvas.drawCircle(p, 9, Paint()..color = const Color(0xFF22C55E).withOpacity(0.85));
    }
    _text(canvas, 'ASSEMBLY', const Offset(740, 175), const Color(0xFF86EFAC), 7, bold: true, center: true);
    _text(canvas, 'ASSEMBLY', const Offset(740, 460), const Color(0xFF86EFAC), 7, bold: true, center: true);

    // Gateways
    const gwPositions = [
      Offset(410, 155), Offset(630, 155), Offset(250, 155),
      Offset(192, 295), Offset(410, 295), Offset(600, 295), Offset(672, 295),
      Offset(300, 440), Offset(560, 440),
    ];
    for (final p in gwPositions) {
      _drawGateway(canvas, p);
    }

    // Workers
    for (final w in workers) {
      final isEmergency = w.status == WorkerStatus.emergency;
      final col = isEmergency
          ? const Color(0xFFEF4444)
          : w.battery < 20
              ? const Color(0xFFF59E0B)
              : const Color(0xFF3B82F6);
      final isHovered = hoveredId == w.id;
      final isSelected = selectedId == w.id;
      canvas.save();
      canvas.translate(w.x, w.y);

      // Pulse ring
      final pulseScale = 1 + (pulse.value * 1.8);
      final pulseOpacity = (1 - pulse.value) * 0.7;
      canvas.drawCircle(
        Offset.zero,
        11 * pulseScale,
        Paint()
          ..color = col.withOpacity(pulseOpacity.clamp(0, 1) * 0.18)
          ..style = PaintingStyle.fill,
      );

      // Emergency flash
      var dotColor = col;
      if (isEmergency) {
        dotColor = col.withOpacity((0.3 + 0.7 * emergency.value).clamp(0, 1));
      }

      // Hover glow
      if (isHovered || isSelected) {
        canvas.drawCircle(
          Offset.zero,
          12,
          Paint()
            ..color = col.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      canvas.drawCircle(Offset.zero, 6, Paint()..color = dotColor);
      canvas.drawCircle(
        Offset.zero,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      if (w.status == WorkerStatus.moving) {
        canvas.drawCircle(Offset.zero, 2.5, Paint()..color = Colors.white.withOpacity(0.9));
      }
      canvas.restore();
    }

    // Legend
    canvas.save();
    canvas.translate(640, 485);
    canvas.drawCircle(Offset.zero, 4, Paint()..color = const Color(0xFF3B82F6));
    _text(canvas, 'Personnel', const Offset(7, 4), labelColor, 8, center: false);
    canvas.drawCircle(const Offset(68, 0), 4, Paint()..color = const Color(0xFFEF4444));
    _text(canvas, 'Emergency', const Offset(75, 4), labelColor, 8, center: false);
    canvas.drawCircle(const Offset(138, 0), 6, Paint()..color = const Color(0xFF22C55E).withOpacity(0.8));
    _text(canvas, 'Assembly', const Offset(146, 4), labelColor, 8, center: false);
    canvas.restore();
  }

  void _level(Canvas c, double x, double y, double w, double h, String label, double labelY) {
    _roundedRect(c, Rect.fromLTWH(x, y, w, h), tunnelWall, 3);
    _roundedRect(c, Rect.fromLTWH(x, y + 4, w, h - 8), tunnelFloor, 2);
    _text(c, label, Offset(x + 13, labelY), labelColor, 10, bold: true, center: false);
  }

  void _tunnel(Canvas c, double x, double y, double w, double h, String label, Offset labelPos, {required bool alignEnd}) {
    _roundedRect(c, Rect.fromLTWH(x, y, w, h), tunnelWall, 2);
    _roundedRect(c, Rect.fromLTWH(x + 4, y, w - 8, h), tunnelFloor, 2);
    _text(c, label, labelPos, labelColor, 9, bold: true, center: false, alignEnd: alignEnd);
  }

  void _roundedRect(Canvas c, Rect r, Color color, double radius, {double opacity = 1}) {
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()..color = color.withOpacity(opacity),
    );
  }

  void _drawGateway(Canvas c, Offset p) {
    c.drawCircle(p, 6, Paint()..color = tunnelBg);
    c.drawCircle(p, 3, Paint()..color = const Color(0xFF60A5FA));
    final arcPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final path1 = Path()
      ..moveTo(p.dx - 6, p.dy - 4)
      ..quadraticBezierTo(p.dx, p.dy - 11, p.dx + 6, p.dy - 4);
    c.drawPath(path1, arcPaint);
    final path2 = Path()
      ..moveTo(p.dx - 10, p.dy - 8)
      ..quadraticBezierTo(p.dx, p.dy - 18, p.dx + 10, p.dy - 8);
    c.drawPath(path2, arcPaint..color = const Color(0xFF60A5FA).withOpacity(0.55));
  }

  void _radial(Canvas c, Offset center, double rx, double ry, Color color) {
    // Approximate a radial gradient ellipse with concentric translucent rings.
    for (var i = 0; i < 8; i++) {
      final f = 1 - i / 8;
      c.drawOval(
        Rect.fromCenter(center: center, width: rx * (1 - i / 8) * 2, height: ry * (1 - i / 8) * 2),
        Paint()..color = color.withOpacity((f * 0.25).clamp(0, 0.25)),
      );
    }
  }

  void _dashedLine(Canvas c, Offset a, Offset b, Paint p, {double dash = 6, double gap = 4}) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var dist = 0.0;
    while (dist < total) {
      final start = a + dir * dist;
      final endDist = math.min(dist + dash, total);
      final end = a + dir * endDist;
      c.drawLine(start, end, p);
      dist += dash + gap;
    }
  }

  static final _labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);

  void _text(Canvas c, String s, Offset p, Color color, double size,
      {bool bold = false, bool center = false, bool alignEnd = false}) {
    if (s.isEmpty) return;
    _labelPainter.text = TextSpan(
      text: s,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        fontFamily: 'Inter',
      ),
    );
    _labelPainter.layout();
    var dx = p.dx;
    if (center) {
      dx = p.dx - _labelPainter.width / 2;
    } else if (alignEnd) {
      dx = p.dx - _labelPainter.width;
    }
    _labelPainter.paint(c, Offset(dx, p.dy - _labelPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const viewW = 820.0;
const viewH = 520.0;