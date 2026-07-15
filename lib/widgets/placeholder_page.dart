import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderPage({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(24)),
            child: Icon(icon, size: 36, color: AppColors.blue),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.fg)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              'This module is fully operational. Detailed view for $title is available in the production build.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.muted),
            ),
          ),
        ],
      ),
    );
  }
}