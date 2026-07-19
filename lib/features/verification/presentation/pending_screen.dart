import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';

class VerificationPendingScreen extends ConsumerWidget {
  const VerificationPendingScreen({super.key});

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
              // Pending/Hourglass icon representation
              Container(
                width: 110.0,
                height: 110.0,
                decoration: BoxDecoration(
                  color: AppColors.cardCream,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 52.0,
                  color: AppColors.accentRoseGold,
                ),
              ),
              const SizedBox(height: 32.0),

              Text(
                'Your profile is being reviewed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.primaryBurgundy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),

              const Text(
                'Our team is reviewing your details and face verification video. Your profile will remain private until approved. We will notify you via email/push when the review is complete.',
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
                  // Simulate support contact
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Support ticket raised. We reply in 2-4 hours.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('Contact Support'),
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
