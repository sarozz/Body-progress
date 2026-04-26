import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web persistence uses Drift's WASM build with IndexedDB-backed storage.
///
/// Two assets must be served at the same origin as the app:
///   - /sqlite3.wasm
///   - /drift_worker.js
///
/// The CI workflow downloads both into `web/` before `flutter build web`.
QueryExecutor openExecutor() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'body_progress',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
