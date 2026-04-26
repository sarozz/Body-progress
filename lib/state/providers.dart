import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local/app_database.dart';
import '../data/models/body_checkin.dart';
import '../data/models/profile.dart';
import '../data/remote/auth_repository.dart';
import '../data/remote/supabase_service.dart';
import '../data/repositories/checkin_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/sync/sync_service.dart';

// ----- Singletons -----

final supabaseServiceProvider = Provider<SupabaseService>((_) {
  return SupabaseService.instance;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseServiceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseServiceProvider),
  );
});

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  return CheckinRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseServiceProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final svc = SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseServiceProvider),
  );
  svc.start();
  ref.onDispose(svc.stop);
  return svc;
});

// ----- Auth -----

final authStateProvider = StreamProvider<AuthState?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  if (!repo.isConfigured) return const Stream.empty();
  return repo.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

// ----- Profile -----

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    final repo = ref.watch(profileRepositoryProvider);
    return repo.load(user.id);
  }

  Future<void> save(Profile profile) async {
    state = const AsyncValue.loading();
    final repo = ref.read(profileRepositoryProvider);
    await repo.save(profile);
    state = AsyncValue.data(profile);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);

// ----- Check-ins -----

class CheckinsNotifier extends AsyncNotifier<List<BodyCheckin>> {
  @override
  Future<List<BodyCheckin>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    // Trigger background sync but don't block.
    final sync = ref.read(syncServiceProvider);
    // ignore: unawaited_futures
    sync.syncNow();
    final repo = ref.watch(checkinRepositoryProvider);
    return repo.all(user.id);
  }

  Future<void> save(BodyCheckin c) async {
    await ref.read(checkinRepositoryProvider).save(c);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(checkinRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}

final checkinsProvider =
    AsyncNotifierProvider<CheckinsNotifier, List<BodyCheckin>>(
  CheckinsNotifier.new,
);
