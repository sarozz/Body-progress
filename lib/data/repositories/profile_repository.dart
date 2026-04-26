import '../local/app_database.dart';
import '../models/profile.dart';
import '../remote/supabase_service.dart';

class ProfileRepository {
  ProfileRepository(this._db, this._svc);
  final AppDatabase _db;
  final SupabaseService _svc;

  Future<Profile?> load(String userId) async {
    final local = await _db.getProfileLocal(userId);
    if (local != null) return Profile.fromMap(local);
    if (!_svc.isConfigured) return null;
    final row = await _svc.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    await _db.upsertProfileLocal(row, syncState: 'synced');
    return Profile.fromMap(row);
  }

  Future<void> save(Profile profile) async {
    final map = profile.toUpsertMap();
    await _db.upsertProfileLocal(map, syncState: 'pending');
    if (_svc.isConfigured && _svc.currentUser != null) {
      try {
        await _svc.client.from('profiles').upsert(map);
        await _db.markProfileSynced(profile.id);
      } catch (_) {
        // stays pending; sync service will retry
      }
    }
  }
}
