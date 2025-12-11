import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _dbFactoryInitialized = false;

Future<void> ensureDatabaseFactoryInitialized() async {
  if (_dbFactoryInitialized) return;

  // Android/iOS already provide a database factory via the sqflite plugin.
  if (Platform.isAndroid || Platform.isIOS) {
    _dbFactoryInitialized = true;
    return;
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  _dbFactoryInitialized = true;
}
