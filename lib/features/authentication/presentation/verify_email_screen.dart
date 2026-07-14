import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/auth_repository_interface.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isLoading = false;
  int _cooldownSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0) return;
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authRepositoryProvider).resendVerificationEmail();
      _startCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification link resent successfully.')),
        );
      }
    } catch (_) {}
    
    setState(() => _isLoading = false);
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    // Simulates calling repository to sync session
    await ref.read(authRepositoryProvider).verifyEmail();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authRepositoryProvider).currentUserEmail ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stylized Mail Icon
              Container(
                width: 100.0,
                height: 100.0,
                decoration: BoxDecoration(
                  color: AppColors.cardCream,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 48.0,
                  color: AppColors.primaryBurgundy,
                ),
              ),
              const SizedBox(height: 32.0),
              
              Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primaryBurgundy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16.0),
              
              Text(
                'We sent a verification link to:\n$email\n\nOpen the link to secure your Loverage account and continue creating your profile.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15.0,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 48.0),

              // Button actions
              FilledButton(
                onPressed: _isLoading ? null : _checkVerification,
                child: const Text('I Have Verified My Email'),
              ),
              const SizedBox(height: 16.0),

              OutlinedButton(
                onPressed: _cooldownSeconds > 0 ? null : _resendEmail,
                child: Text(
                  _cooldownSeconds > 0 ? 'Resend Email in ${_cooldownSeconds}s' : 'Resend Email',
                ),
              ),
              const SizedBox(height: 24.0),

              // Sign Out Link
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
