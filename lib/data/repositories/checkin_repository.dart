import '../local/app_database.dart';
import '../models/body_checkin.dart';
import '../remote/supabase_service.dart';

class CheckinRepository {
  CheckinRepository(this._db, this._svc);
  final AppDatabase _db;
  final SupabaseService _svc;

  Future<List<BodyCheckin>> all(String userId) => _db.allCheckins(userId);

  Future<BodyCheckin?> latest(String userId) => _db.latestCheckin(userId);

  Future<void> save(BodyCheckin checkin) async {
    await _db.upsertCheckinLocal(checkin, syncState: 'pending');
    if (_svc.isConfigured && _svc.currentUser != null) {
      try {
        await _svc.client.from('body_checkins').upsert(checkin.toUpsertMap());
        await _db.markCheckinSynced(checkin.id);
      } catch (_) {/* sync later */}
    }
  }

  Future<void> delete(String id) async {
    await _db.markCheckinDeleted(id);
    if (_svc.isConfigured && _svc.currentUser != null) {
      try {
        await _svc.client.from('body_checkins').delete().eq('id', id);
        await _db.hardDeleteCheckin(id);
      } catch (_) {/* sync later */}
    }
  }
}
