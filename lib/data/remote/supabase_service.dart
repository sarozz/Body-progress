import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/env.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (!Env.isConfigured) {
      // App still runs in offline-only mode without Supabase configured.
      _initialized = true;
      return;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    _initialized = true;
  }

  bool get isConfigured => Env.isConfigured;

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  User? get currentUser => isConfigured ? auth.currentUser : null;
}
