import 'package:drift/drift.dart';

QueryExecutor openExecutor() {
  throw UnsupportedError(
    'No database executor configured for this platform.',
  );
}
