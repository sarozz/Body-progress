import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_screen.dart';
import 'features/shell/app_shell.dart';
import 'state/providers.dart';

class BodyProgressApp extends ConsumerWidget {
  const BodyProgressApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authConfigured = ref.watch(authRepositoryProvider).isConfigured;

    return MaterialApp(
      title: 'Body Progress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: (!authConfigured || user != null)
          ? const AppShell()
          : const AuthScreen(),
    );
  }
}
