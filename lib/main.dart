import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_state.dart';

void main() {
  initializeDateFormatting();
  Intl.defaultLocale = 'en_ZA';
  runApp(const MineTrackAppRoot());
}

class MineTrackAppRoot extends StatelessWidget {
  const MineTrackAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
      child: const MineTrackApp(),
    );
  }
}