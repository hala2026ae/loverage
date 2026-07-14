import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'features/authentication/data/auth_repository_impl.dart';
import 'features/authentication/domain/auth_repository_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gmgjvtrswcmlrlgkrdji.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdtZ2p2dHJzd2NtbHJsZ2tyZGppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4Njc5NzgsImV4cCI6MjA5OTQ0Mzk3OH0.IP_-hQIbxKa_VBxftL-OvXNCAeL78rQ8orV5naAPkrc',
  );

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  final client = Supabase.instance.client;

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthRepositoryImpl(client)),
      ],
      child: const LoverageApp(),
    ),
  );
}
