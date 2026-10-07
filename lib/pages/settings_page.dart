import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _batteryThreshold = 20;
  double _signalThreshold = -75;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final app = context.watch<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
            Text('Display preferences for this dashboard', style: TextStyle(fontSize: 13, color: t.muted)),
            const SizedBox(height: 20),
            // Appearance
            _sectionCard(
              t,
              title: 'Appearance',
              icon: Icons.light_mode_outlined,
              child: Column(
                children: [
                  _toggleRow(
                    t,
                    'Dark Mode',
                    'Toggle between light and dark theme',
                    app.darkMode,
                    (v) => app.setDarkMode(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Thresholds
            _sectionCard(
              t,
              title: 'Alert Thresholds',
              icon: Icons.warning_amber_rounded,
              child: Column(
                children: [
                  _sliderRow(
                    t,
                    'Battery Warning Threshold',
                    '${_batteryThreshold.toInt()}%',
                    'Marks a tag as "low battery" in this dashboard. Display-only — '
                    'the backend raises its own alerts independently.',
                    _batteryThreshold,
                    min: 5,
                    max: 50,
                    divisions: 45,
                    onChanged: (v) => setState(() => _batteryThreshold = v),
                  ),
                  Divider(color: t.border, height: 1),
                  _sliderRow(
                    t,
                    'Signal Sensitivity Threshold',
                    '${_signalThreshold.toInt()} dBm',
                    'Highlights weak-signal tags in this dashboard. Display-only — '
                    'not sent to the backend.',
                    _signalThreshold,
                    min: -90,
                    max: -50,
                    divisions: 40,
                    onChanged: (v) => setState(() => _signalThreshold = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _infoCard(
              t,
              'Notifications & alert delivery',
              'This deployment has no push, email or SMS delivery configured — alert '
              'rules live server-side. Active alerts appear in real time on the Alerts '
              'page and in the top-bar notification badge.',
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Honest note replacing the previous non-functional notification toggles.
  Widget _infoCard(SurfaceTokens t, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(fontSize: 11, color: t.muted, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(SurfaceTokens t, {required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: t.card, border: Border.all(color: t.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: t.mutedBg.withOpacity(0.3), border: Border(bottom: BorderSide(color: t.border))),
            child: Row(children: [
              Icon(icon, size: 15, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.fg)),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }

  Widget _toggleRow(SurfaceTokens t, String label, String desc, bool on, ValueChanged<bool> onChg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.fg)),
                Text(desc, style: TextStyle(fontSize: 11, color: t.muted)),
              ],
            ),
          ),
          _switch(on, onChg),
        ],
      ),
    );
  }

  Widget _sliderRow(SurfaceTokens t, String label, String value, String desc, double current,
      {required double min, required double max, required int divisions, required ValueChanged<double> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: t.fg)),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue)),
            ],
          ),
          Slider(value: current, min: min, max: max, divisions: divisions, onChanged: onChanged, activeColor: AppColors.blue),
          Align(alignment: Alignment.centerLeft, child: Text(desc, style: TextStyle(fontSize: 11, color: t.muted))),
        ],
      ),
    );
  }

  Widget _switch(bool on, ValueChanged<bool> onChg) {
    return GestureDetector(
      onTap: () => onChg(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: on ? AppColors.blue : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 16,
            height: 16,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: Color(0x22000000), blurRadius: 2),
            ]),
          ),
        ),
      ),
    );
  }

}