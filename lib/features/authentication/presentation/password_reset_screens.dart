import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/auth_repository_interface.dart';
import 'auth_brand_widgets.dart';
import 'auth_form_helpers.dart';

class ForgotPasswordEmailScreen extends ConsumerStatefulWidget {
  final String initialEmail;
  const ForgotPasswordEmailScreen({super.key, this.initialEmail = ''});

  @override
  ConsumerState<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState
    extends ConsumerState<ForgotPasswordEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final email = normalizeEmail(_emailCtrl.text);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      context.go('/forgot-password/otp?email=${Uri.encodeComponent(email)}');
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PasswordResetShell(
      title: 'Forgot password',
      subtitle: 'Enter your email and we will send a 4-digit reset code.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ResetFieldLabel('Email address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _sendOtp(),
              validator: validateEmailAddress,
              decoration: _resetInputDecoration(
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _ResetErrorBanner(message: _error!),
            ],
            const SizedBox(height: 24),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBurgundy,
                    ),
                  )
                : AuthPrimaryButton(
                    label: 'Send Code',
                    onPressed: _sendOtp,
                    tone: AuthPrimaryButtonTone.signIn,
                  ),
          ],
        ),
      ),
    );
  }
}

class PasswordResetOtpScreen extends ConsumerStatefulWidget {
  final String email;
  const PasswordResetOtpScreen({super.key, required this.email});

  @override
  ConsumerState<PasswordResetOtpScreen> createState() =>
      _PasswordResetOtpScreenState();
}

class _PasswordResetOtpScreenState
    extends ConsumerState<PasswordResetOtpScreen> {
  final _otpCtrl = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/forgot-password');
      });
      return;
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remainingSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _remainingSeconds = 0);
        return;
      }
      if (mounted) setState(() => _remainingSeconds--);
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length != 4) {
      setState(() => _error = 'Enter the 4-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyPasswordResetOtp(email: widget.email, otp: _otpCtrl.text);
      if (!mounted) return;
      context.go('/reset-password?email=${Uri.encodeComponent(widget.email)}');
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_remainingSeconds > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(widget.email);
      if (!mounted) return;
      _otpCtrl.clear();
      _startTimer();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.email.isEmpty) {
      return const SizedBox.shrink();
    }
    return _PasswordResetShell(
      title: 'Enter code',
      subtitle: 'We sent a 4-digit code to ${widget.email}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ResetFieldLabel('Reset code'),
          const SizedBox(height: 10),
          _OtpInput(controller: _otpCtrl, onComplete: _verifyOtp),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _remainingSeconds == 0 ? _resendOtp : null,
              child: Text(
                _remainingSeconds == 0
                    ? (_resending ? 'Sending...' : 'Resend code')
                    : 'Resend code in ${_remainingSeconds}s',
                style: TextStyle(
                  color: _remainingSeconds == 0
                      ? AppColors.primaryBurgundy
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            _ResetErrorBanner(message: _error!),
          ],
          const SizedBox(height: 18),
          _verifying
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBurgundy,
                  ),
                )
              : AuthPrimaryButton(
                  label: 'Verify Code',
                  onPressed: _verifyOtp,
                  tone: AuthPrimaryButtonTone.signIn,
                ),
        ],
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmPasswordReset(token: '', newPassword: _passwordCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please log in.')),
      );
      context.go('/signin?email=${Uri.encodeComponent(widget.email)}');
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/forgot-password');
      });
      return const SizedBox.shrink();
    }
    return _PasswordResetShell(
      title: 'New password',
      subtitle: 'Create a new password for ${widget.email}.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ResetFieldLabel('New password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if ((value ?? '').length < 6) {
                  return 'Minimum 6 characters';
                }
                return null;
              },
              decoration: _resetInputDecoration(
                hint: 'Minimum 6 characters',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _ResetFieldLabel('Confirm password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _savePassword(),
              validator: (value) {
                if (value != _passwordCtrl.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              decoration: _resetInputDecoration(
                hint: 'Re-enter password',
                icon: Icons.lock_reset_rounded,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _ResetErrorBanner(message: _error!),
            ],
            const SizedBox(height: 24),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBurgundy,
                    ),
                  )
                : AuthPrimaryButton(
                    label: 'Set Password',
                    onPressed: _savePassword,
                    tone: AuthPrimaryButtonTone.signIn,
                  ),
          ],
        ),
      ),
    );
  }
}

class _PasswordResetShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PasswordResetShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5A0A1E), Color(0xFF9A2946)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/signin');
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Image.asset(
                'Assets/loverage text.png',
                height: 32,
                fit: BoxFit.contain,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTheme.serifHeadline(
                        fontSize: 34,
                        color: Colors.white,
                      ).copyWith(height: 1.05),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFCFA), Color(0xFFFAF1EE)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                    child: child,
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

class _OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onComplete;

  const _OtpInput({required this.controller, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 4,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        if (value.length == 4) onComplete();
      },
      style: const TextStyle(
        color: AppColors.primaryBurgundy,
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 18,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '0000',
        hintStyle: TextStyle(
          color: AppColors.textMuted.withOpacity(0.35),
          fontWeight: FontWeight.w900,
          letterSpacing: 18,
        ),
        filled: true,
        fillColor: const Color(0xFFFFFBFA),
        contentPadding: const EdgeInsets.fromLTRB(28, 18, 10, 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFEADDD8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: AppColors.primaryBurgundy,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ResetFieldLabel extends StatelessWidget {
  final String label;
  const _ResetFieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );
}

class _ResetErrorBanner extends StatelessWidget {
  final String message;
  const _ResetErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.07),
      borderRadius: BorderRadius.circular(AppRadius.s),
      border: Border.all(color: AppColors.error.withOpacity(0.28)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppColors.error,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

InputDecoration _resetInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFFFFBFA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: Color(0xFFEADDD8)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: AppColors.primaryBurgundy, width: 1.4),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: AppColors.error, width: 1.2),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: AppColors.error, width: 1.4),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 48),
    suffixIconConstraints: const BoxConstraints(minWidth: 48),
    prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
    suffixIcon: suffix,
  );
}
