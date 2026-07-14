import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';

class DeactivatedScreen extends ConsumerWidget {
  const DeactivatedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100.0,
                height: 100.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6), // neutral grey
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  size: 52.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32.0),
              
              Text(
                'Account Deactivated',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primaryBurgundy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16.0),
              
              const Text(
                'Your account has been deactivated or scheduled for deletion. You can reactivate your account at any time within 30 days of deactivation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48.0),

              FilledButton(
                onPressed: () {
                  // Simulate reactivation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reactivating account... Please wait.')),
                  );
                },
                child: const Text('Reactivate Account'),
              ),
              const SizedBox(height: 16.0),

              TextButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
