import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/test_result.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'local_db_service.dart';

class SyncService {
  final LocalDbService localDb;

  SyncService(this.localDb);

  Future<void> syncPendingResults(User user) async {
  // connectivity_plus >= 6 returns a List<ConnectivityResult>
  final results = await Connectivity().checkConnectivity();
  if (results.isEmpty || results.contains(ConnectivityResult.none)) return;

    final pending = await localDb.getPendingResults();
    if (pending.isEmpty) return;

    final api = ApiService(token: user.token);

    for (final result in pending) {
      try {
        await api.client.post(
          '/tests/upload',
          data: {
            'id': result.id,
            'testTypeId': result.testTypeId,
            'athleteId': result.athleteId,
            'createdAt': result.createdAt.toIso8601String(),
            'metrics': jsonEncode(result.metrics),
            'isValid': result.isValid,
          },
        );

        final updated = TestResult(
          id: result.id,
          testTypeId: result.testTypeId,
          athleteId: result.athleteId,
          createdAt: result.createdAt,
          videoPath: result.videoPath,
          metrics: result.metrics,
          isValid: result.isValid,
          syncStatus: TestSyncStatus.uploaded,
        );

        await localDb.updateResult(updated);
      } catch (_) {
        // keep as pending/failed
      }
    }
  }
}