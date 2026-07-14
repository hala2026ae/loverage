import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';

class SuspendedScreen extends ConsumerWidget {
  const SuspendedScreen({super.key});

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
                  color: Color(0xFFFEF3C7), // warning orange/yellow
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  size: 52.0,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 32.0),
              
              Text(
                'Account Suspended',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primaryBurgundy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16.0),
              
              const Text(
                'Your Loverage account has been suspended due to violations of our community respect rules. If you believe this is an error, you may contact our moderation support team to file an appeal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.0,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48.0),

              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appeal submitted. Support will email you shortly.')),
                  );
                },
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('Appeal Suspension'),
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
