import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:antardrishti/main.dart';
import 'package:antardrishti/core/services/auth_service.dart';
import 'package:antardrishti/core/services/local_db_service.dart';
import 'package:antardrishti/core/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App builds and shows initial route', (tester) async {
    // Ensure clean SharedPreferences for test
    SharedPreferences.setMockInitialValues({});

    final auth = AuthService();
    final localDb = LocalDbService();
    final sync = SyncService(localDb);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppState(auth, sync)..init(),
          ),
          Provider.value(value: localDb),
          Provider.value(value: sync),
        ],
        child: const SAIApp(),
      ),
    );

  // Allow async init() and any initial animations to complete
  await tester.pumpAndSettle();
    // After init, either login or home should be present depending on user state
    expect(
      find.byType(MaterialApp),
      findsOneWidget,
    );
  });
}
