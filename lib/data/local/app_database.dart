import 'package:drift/drift.dart';

import '../models/body_checkin.dart';
import 'db_opener_stub.dart'
    if (dart.library.io) 'db_opener_io.dart'
    if (dart.library.html) 'db_opener_web.dart';

part 'app_database.g.dart';

/// Local mirror of profile + body_checkins, plus a sync-state flag.
///
/// `syncState` values:
///   - 'synced'  : matches remote
///   - 'pending' : local changes not yet pushed
///   - 'deleted' : marked for delete, awaiting remote deletion
class CheckinsTable extends Table {
  @override
  String get tableName => 'checkins';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get checkinDate => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get bodyFatPct => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get hipsCm => real().nullable()();
  RealColumn get neckCm => real().nullable()();
  RealColumn get shouldersCm => real().nullable()();
  RealColumn get bicepLeftCm => real().nullable()();
  RealColumn get bicepRightCm => real().nullable()();
  RealColumn get tricepLeftCm => real().nullable()();
  RealColumn get tricepRightCm => real().nullable()();
  RealColumn get forearmLeftCm => real().nullable()();
  RealColumn get forearmRightCm => real().nullable()();
  RealColumn get thighLeftCm => real().nullable()();
  RealColumn get thighRightCm => real().nullable()();
  RealColumn get calfLeftCm => real().nullable()();
  RealColumn get calfRightCm => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ProfilesTable extends Table {
  @override
  String get tableName => 'profile';

  TextColumn get id => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get sex => text().nullable()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  RealColumn get heightCm => real().nullable()();
  TextColumn get unitSystem =>
      text().withDefault(const Constant('metric'))();
  TextColumn get goalType => text().nullable()();
  RealColumn get goalTargetWeightKg => real().nullable()();
  RealColumn get goalTargetWaistCm => real().nullable()();
  RealColumn get goalTargetBodyFat => real().nullable()();
  DateTimeColumn get goalDeadline => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncState => text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [CheckinsTable, ProfilesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openExecutor());
  AppDatabase.test(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  // -------------------------- Check-ins --------------------------

  Future<List<BodyCheckin>> allCheckins(String userId) async {
    final query = select(checkinsTable)
      ..where((t) => t.userId.equals(userId) & t.syncState.isNotValue('deleted'))
      ..orderBy([(t) => OrderingTerm.desc(t.checkinDate)]);
    final rows = await query.get();
    return rows.map(_rowToCheckin).toList();
  }

  Future<BodyCheckin?> latestCheckin(String userId) async {
    final query = select(checkinsTable)
      ..where((t) => t.userId.equals(userId) & t.syncState.isNotValue('deleted'))
      ..orderBy([(t) => OrderingTerm.desc(t.checkinDate)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _rowToCheckin(row);
  }

  Future<void> upsertCheckinLocal(BodyCheckin c, {String? syncState}) async {
    await into(checkinsTable).insertOnConflictUpdate(
      CheckinsTableCompanion.insert(
        id: c.id,
        userId: c.userId,
        checkinDate: c.checkinDate,
        weightKg: Value(c.weightKg),
        bodyFatPct: Value(c.bodyFatPct),
        chestCm: Value(c.chestCm),
        waistCm: Value(c.waistCm),
        hipsCm: Value(c.hipsCm),
        neckCm: Value(c.neckCm),
        shouldersCm: Value(c.shouldersCm),
        bicepLeftCm: Value(c.bicepLeftCm),
        bicepRightCm: Value(c.bicepRightCm),
        tricepLeftCm: Value(c.tricepLeftCm),
        tricepRightCm: Value(c.tricepRightCm),
        forearmLeftCm: Value(c.forearmLeftCm),
        forearmRightCm: Value(c.forearmRightCm),
        thighLeftCm: Value(c.thighLeftCm),
        thighRightCm: Value(c.thighRightCm),
        calfLeftCm: Value(c.calfLeftCm),
        calfRightCm: Value(c.calfRightCm),
        notes: Value(c.notes),
        photoPath: Value(c.photoPath),
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
        syncState: Value(syncState ?? 'pending'),
      ),
    );
  }

  Future<void> markCheckinDeleted(String id) async {
    await (update(checkinsTable)..where((t) => t.id.equals(id))).write(
      CheckinsTableCompanion(
        syncState: const Value('deleted'),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> hardDeleteCheckin(String id) async {
    await (delete(checkinsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<BodyCheckin>> pendingCheckins() async {
    final query = select(checkinsTable)
      ..where((t) => t.syncState.equals('pending'));
    final rows = await query.get();
    return rows.map(_rowToCheckin).toList();
  }

  Future<List<String>> deletedCheckinIds() async {
    final query = selectOnly(checkinsTable)
      ..addColumns([checkinsTable.id])
      ..where(checkinsTable.syncState.equals('deleted'));
    final rows = await query.get();
    return rows.map((r) => r.read(checkinsTable.id)!).toList();
  }

  Future<void> markCheckinSynced(String id) async {
    await (update(checkinsTable)..where((t) => t.id.equals(id)))
        .write(const CheckinsTableCompanion(syncState: Value('synced')));
  }

  // -------------------------- Profile --------------------------

  Future<void> upsertProfileLocal(
    Map<String, dynamic> values, {
    String? syncState,
  }) async {
    await into(profilesTable).insertOnConflictUpdate(
      ProfilesTableCompanion.insert(
        id: values['id'] as String,
        displayName: Value(values['display_name'] as String?),
        sex: Value(values['sex'] as String?),
        birthDate: Value(_dt(values['birth_date'])),
        heightCm: Value(_d(values['height_cm'])),
        unitSystem:
            Value((values['unit_system'] as String?) ?? 'metric'),
        goalType: Value(values['goal_type'] as String?),
        goalTargetWeightKg: Value(_d(values['goal_target_weight_kg'])),
        goalTargetWaistCm: Value(_d(values['goal_target_waist_cm'])),
        goalTargetBodyFat: Value(_d(values['goal_target_body_fat'])),
        goalDeadline: Value(_dt(values['goal_deadline'])),
        updatedAt: DateTime.now().toUtc(),
        syncState: Value(syncState ?? 'pending'),
      ),
    );
  }

  Future<Map<String, dynamic>?> getProfileLocal(String id) async {
    final row = await (select(profilesTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return {
      'id': row.id,
      'display_name': row.displayName,
      'sex': row.sex,
      'birth_date': row.birthDate?.toIso8601String().split('T').first,
      'height_cm': row.heightCm,
      'unit_system': row.unitSystem,
      'goal_type': row.goalType,
      'goal_target_weight_kg': row.goalTargetWeightKg,
      'goal_target_waist_cm': row.goalTargetWaistCm,
      'goal_target_body_fat': row.goalTargetBodyFat,
      'goal_deadline': row.goalDeadline?.toIso8601String().split('T').first,
      'updated_at': row.updatedAt.toIso8601String(),
      'sync_state': row.syncState,
    };
  }

  Future<void> markProfileSynced(String id) async {
    await (update(profilesTable)..where((t) => t.id.equals(id)))
        .write(const ProfilesTableCompanion(syncState: Value('synced')));
  }

  Future<void> wipeAll() async {
    await batch((b) {
      b.deleteWhere(checkinsTable, (t) => const Constant(true));
      b.deleteWhere(profilesTable, (t) => const Constant(true));
    });
  }

  // -------------------------- helpers --------------------------

  BodyCheckin _rowToCheckin(CheckinsTableData r) => BodyCheckin(
        id: r.id,
        userId: r.userId,
        checkinDate: r.checkinDate,
        weightKg: r.weightKg,
        bodyFatPct: r.bodyFatPct,
        chestCm: r.chestCm,
        waistCm: r.waistCm,
        hipsCm: r.hipsCm,
        neckCm: r.neckCm,
        shouldersCm: r.shouldersCm,
        bicepLeftCm: r.bicepLeftCm,
        bicepRightCm: r.bicepRightCm,
        tricepLeftCm: r.tricepLeftCm,
        tricepRightCm: r.tricepRightCm,
        forearmLeftCm: r.forearmLeftCm,
        forearmRightCm: r.forearmRightCm,
        thighLeftCm: r.thighLeftCm,
        thighRightCm: r.thighRightCm,
        calfLeftCm: r.calfLeftCm,
        calfRightCm: r.calfRightCm,
        notes: r.notes,
        photoPath: r.photoPath,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  static double? _d(Object? v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
  static DateTime? _dt(Object? v) =>
      v == null ? null : DateTime.tryParse('$v');
}

