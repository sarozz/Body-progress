import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../local/app_database.dart';
import '../models/body_checkin.dart';
import '../remote/supabase_service.dart';

/// Pushes pending local changes and pulls remote rows for the current user.
class SyncService {
  SyncService(this._db, this._svc);
  final AppDatabase _db;
  final SupabaseService _svc;

  StreamSubscription<List<ConnectivityResult>>? _conn;
  bool _running = false;

  void start() {
    _conn ??= Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        unawaited(syncNow());
      }
    });
  }

  void stop() {
    _conn?.cancel();
    _conn = null;
  }

  Future<void> syncNow() async {
    if (_running) return;
    if (!_svc.isConfigured) return;
    final user = _svc.currentUser;
    if (user == null) return;
    _running = true;
    try {
      await _pushPending(user.id);
      await _pullRemote(user.id);
    } catch (_) {
      // Swallow: next trigger will retry. Real app would log this.
    } finally {
      _running = false;
    }
  }

  Future<void> _pushPending(String userId) async {
    // Profile
    final profile = await _db.getProfileLocal(userId);
    if (profile != null && profile['sync_state'] == 'pending') {
      final payload = Map<String, dynamic>.from(profile)
        ..remove('sync_state')
        ..remove('updated_at');
      await _svc.client.from('profiles').upsert(payload);
      await _db.markProfileSynced(userId);
    }

    // Check-ins (deletes first, then upserts)
    final deletedIds = await _db.deletedCheckinIds();
    if (deletedIds.isNotEmpty) {
      await _svc.client
          .from('body_checkins')
          .delete()
          .inFilter('id', deletedIds);
      for (final id in deletedIds) {
        await _db.hardDeleteCheckin(id);
      }
    }

    final pending = await _db.pendingCheckins();
    if (pending.isNotEmpty) {
      await _svc.client
          .from('body_checkins')
          .upsert(pending.map((c) => c.toUpsertMap()).toList());
      for (final c in pending) {
        await _db.markCheckinSynced(c.id);
      }
    }
  }

  Future<void> _pullRemote(String userId) async {
    final rows = await _svc.client
        .from('body_checkins')
        .select()
        .eq('user_id', userId);
    for (final row in rows as List<dynamic>) {
      final c = BodyCheckin.fromMap(row as Map<String, dynamic>);
      await _db.upsertCheckinLocal(c, syncState: 'synced');
    }

    final profileRow = await _svc.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (profileRow != null) {
      await _db.upsertProfileLocal(profileRow, syncState: 'synced');
    }
  }
}
