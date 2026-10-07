import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:minetrack/core/app_state.dart';
import 'package:minetrack/app.dart';

void main() {
  setUpAll(() {
    // main.dart does this at app startup; tests pump widgets directly so it
    // must be done here too or DateFormat('...', 'en_ZA') throws.
    initializeDateFormatting();
    Intl.defaultLocale = 'en_ZA';
  });

  testWidgets('Login screen shows brand and sign-in button', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MineTrackApp(),
      ),
    );
    await tester.pump();

    expect(find.text('MineTrack'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });
}