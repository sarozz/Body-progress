import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthRepository {
  AuthRepository(this._svc);
  final SupabaseService _svc;

  bool get isConfigured => _svc.isConfigured;
  User? get currentUser => _svc.currentUser;

  Stream<AuthState> authStateChanges() => _svc.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _svc.auth.signUp(
      email: email,
      password: password,
      data: {if (displayName != null) 'display_name': displayName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _svc.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _svc.auth.signOut();

  Future<void> resetPassword(String email) =>
      _svc.auth.resetPasswordForEmail(email);

  /// Account deletion: requires a deployed Edge Function `delete-account`
  /// that removes the auth user (and cascades to data via FK).
  Future<void> deleteAccount() async {
    await _svc.client.functions.invoke('delete-account');
    await signOut();
  }
}
