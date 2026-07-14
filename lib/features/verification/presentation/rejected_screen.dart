import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';

class VerificationRejectedScreen extends ConsumerWidget {
  const VerificationRejectedScreen({super.key});

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
                  color: Color(0xFFFEE2E2), // light red
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gpp_bad_outlined,
                  size: 52.0,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 32.0),
              
              Text(
                'Verification needs attention',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primaryBurgundy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16.0),
              
              const Text(
                'Reason for rejection: The face verification video did not match your uploaded profile photos, or lighting was insufficient. Please retake the verification process.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48.0),

              // Actions
              FilledButton(
                onPressed: () {
                  // Navigate back to verification screen
                  context.go('/face-verification');
                },
                child: const Text('Retake Verification'),
              ),
              const SizedBox(height: 16.0),

              OutlinedButton(
                onPressed: () {
                  context.go('/register'); // Edit details/images
                },
                child: const Text('Edit Profile & Images'),
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
