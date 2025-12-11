import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/test_result.dart';
import 'database_factory_initializer.dart';

class LocalDbService {
  static Database? _db;
  static SharedPreferences? _webPrefs;
  static const _webStoreKey = 'test_results_cache';

  Future<Database> get db async {
    if (kIsWeb) {
      throw UnsupportedError('Local database is not available on web.');
    }

    await ensureDatabaseFactoryInitialized();

    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'sai_sports.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE test_results(
            id TEXT PRIMARY KEY,
            testTypeId TEXT,
            athleteId TEXT,
            createdAt TEXT,
            videoPath TEXT,
            metrics TEXT,
            isValid INTEGER,
            syncStatus INTEGER
          );
        ''');
      },
    );
    return _db!;
  }

  Future<void> insertTestResult(TestResult result) async {
    if (kIsWeb) {
      final results = await _loadWebResults();
      results.removeWhere((r) => r.id == result.id);
      results.add(result);
      await _persistWebResults(results);
      return;
    }

    final database = await db;
    await database.insert(
      'test_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TestResult>> getPendingResults() async {
    if (kIsWeb) {
      final results = await _loadWebResults();
      return results
          .where((r) => r.syncStatus == TestSyncStatus.pending)
          .toList();
    }

    final database = await db;
    final maps = await database.query(
      'test_results',
      where: 'syncStatus = ?',
      whereArgs: [TestSyncStatus.pending.index],
    );
    return maps.map((m) => TestResult.fromMap(m)).toList();
  }

  Future<void> updateResult(TestResult result) async {
    if (kIsWeb) {
      final results = await _loadWebResults();
      final index = results.indexWhere((r) => r.id == result.id);
      if (index == -1) {
        results.add(result);
      } else {
        results[index] = result;
      }
      await _persistWebResults(results);
      return;
    }

    final database = await db;
    await database.update(
      'test_results',
      result.toMap(),
      where: 'id = ?',
      whereArgs: [result.id],
    );
  }

  Future<List<TestResult>> _loadWebResults() async {
    final prefs = await _ensureWebPrefs();
    final stored = prefs.getString(_webStoreKey);
    if (stored == null || stored.isEmpty) return [];

    final decoded = jsonDecode(stored);
    if (decoded is! List) return [];

    return decoded
        .map<TestResult>((entry) => TestResult.fromMap(
            Map<String, dynamic>.from(entry as Map<dynamic, dynamic>)))
        .toList();
  }

  Future<void> _persistWebResults(List<TestResult> results) async {
    final prefs = await _ensureWebPrefs();
    final serialized =
        jsonEncode(results.map((test) => test.toMap()).toList());
    await prefs.setString(_webStoreKey, serialized);
  }

  Future<SharedPreferences> _ensureWebPrefs() async {
    _webPrefs ??= await SharedPreferences.getInstance();
    return _webPrefs!;
  }
}
