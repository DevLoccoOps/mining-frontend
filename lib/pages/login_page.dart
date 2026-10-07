import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _showPass = false;
  bool _remember = false;
  bool _loading = false;
  late final AnimationController _particles;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _particles = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honor the platform "reduce motion" setting: skip the drifting particles.
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce && _animating) {
      _particles.stop();
      _animating = false;
    } else if (!reduce && !_animating) {
      _particles.repeat();
      _animating = true;
    }
  }

  @override
  void dispose() {
    _particles.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _loading = false);
      context.read<AppState>().login();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05101E),
      body: LayoutBuilder(
        builder: (context, c) {
          return Stack(
            children: [
              // Tunnel background
              Positioned.fill(
                child: Opacity(
                  opacity: 0.30,
                  child: CustomPaint(size: c.biggest, painter: _TunnelPainter()),
                ),
              ),
              // Blue radial overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.1),
                      radius: 0.9,
                      colors: [const Color(0xFF1565C0).withOpacity(0.18), Colors.transparent],
                      stops: const [0, 0.7],
                    ),
                  ),
                ),
              ),
              // Particles
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particles,
                  builder: (_, __) => CustomPaint(
                    size: c.biggest,
                    painter: _ParticlePainter(_particles.value, c.biggest),
                  ),
                ),
              ),
              // Card
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: _loginCard(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _loginCard(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      initialData: DateTime.now(),
      builder: (context, snap) {
        final stamp = DateFormat('d MMM y, HH:mm:ss', 'en_ZA').format(snap.data!);
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x4D2563EB), blurRadius: 20, spreadRadius: 2)],
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('MineTrack', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Underground Personnel Tracking System',
                  style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(stamp, style: const TextStyle(color: Color(0x9960A5FA), fontSize: 12, fontFamily: 'monospace')),
              const SizedBox(height: 32),
              // Username
              _fieldLabel('Username'),
              const SizedBox(height: 6),
              TextField(
                controller: _user,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _inputDeco(
                  hint: 'Enter your username',
                  icon: Icons.person_outline,
                  color: const Color(0xFF60A5FA).withOpacity(0.6),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 16),
              // Password
              _fieldLabel('Password'),
              const SizedBox(height: 6),
              TextField(
                controller: _pass,
                obscureText: !_showPass,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _inputDeco(
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  color: const Color(0xFF60A5FA).withOpacity(0.6),
                  suffix: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 14, color: const Color(0x9960A5FA)),
                    onPressed: () => setState(() => _showPass = !_showPass),
                    tooltip: _showPass ? 'Hide password' : 'Show password',
                  ),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 16),
              // Remember + forgot
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _remember = !_remember),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _remember ? const Color(0xFF2563EB) : Colors.transparent,
                              border: Border.all(color: _remember ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: _remember
                                ? const Icon(Icons.check, color: Colors.white, size: 10)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('Remember me', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: const Color(0x4D2563EB),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(color: Color(0x11FFFFFF), height: 1),
              const SizedBox(height: 16),
              const Text('Version 1.0.0 · Production', style: TextStyle(color: Color(0x9960A5FA), fontSize: 12)),
              const SizedBox(height: 4),
              const Text('Powered by InnovAI Technologies', style: TextStyle(color: Color(0x6660A5FA), fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _fieldLabel(String t) =>
      Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 12, fontWeight: FontWeight.w600)));

  InputDecoration _inputDeco({required String hint, required IconData icon, required Color color, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: const Color(0xFF60A5FA).withOpacity(0.4)),
        prefixIcon: Icon(icon, size: 14, color: color),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.4), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      );
}

class _TunnelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    // Tunnel perspective rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF1565C0);
    final scales = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
    for (var i = 0; i < scales.length; i++) {
      final s = scales[i];
      ringPaint
        ..strokeWidth = (1.5 - i * 0.1).clamp(0.2, 1.5)
        ..color = const Color(0xFF1565C0).withOpacity((0.15 + i * 0.05).clamp(0, 1));
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 240 * s, height: 160 * s), ringPaint);
    }
    // Tunnel walls
    final wallPaint = Paint()
      ..color = const Color(0xFF1B3A5C).withOpacity(0.5)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, 0), Offset(cx - 120, cy - 80), wallPaint);
    canvas.drawLine(Offset(w, 0), Offset(cx + 120, cy - 80), wallPaint);
    canvas.drawLine(Offset(0, h), Offset(cx - 120, cy + 80), wallPaint);
    canvas.drawLine(Offset(w, h), Offset(cx + 120, cy + 80), wallPaint);
    // Track lines
    final trackPaint = Paint()
      ..color = const Color(0xFF2563EB).withOpacity(0.3)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(cx - 100, h), Offset(cx - 40, cy + 100), trackPaint);
    canvas.drawLine(Offset(cx + 100, h), Offset(cx + 40, cy + 100), trackPaint);
    // Radial glow
    final grad = Paint()..shader = RadialGradient(
      colors: [const Color(0xFF1565C0).withOpacity(0.3), Colors.transparent],
      stops: const [0, 1],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: math.max(w, h) / 2));
    canvas.drawRect(Offset.zero & size, grad);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final Size size;
  _ParticlePainter(this.t, this.size);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 20; i++) {
      final r = 2 + (i % 4);
      final left = (5 + (i * 23) % 90) / 100 * size.width;
      final top = (10 + (i * 17) % 80) / 100 * size.height;
      final phase = (t + i * 0.3) % 1;
      final op = (1 - phase).abs() * 0.4;
      canvas.drawCircle(Offset(left, top), r.toDouble(), Paint()..color = const Color(0xFF60A5FA).withOpacity(op));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}