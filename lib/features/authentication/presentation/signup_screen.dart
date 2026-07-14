import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/auth_repository_interface.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  bool _loading = false;
  String? _errorMsg;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 100), _animCtrl.forward);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      setState(() => _errorMsg = 'You must agree to the Terms of Service and Privacy Policy.');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ref.read(authRepositoryProvider).signUpWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } catch (e) {
      setState(() => _errorMsg = 'Registration failed. This email may already be in use.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Burgundy header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.3,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create your\naccount',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join a community built on intention',
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Form card
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email
                                _Label('Email address'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: const InputDecoration(
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.textMuted),
                                  ),
                                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                                ),
                                const SizedBox(height: 20),

                                // Password
                                _Label('Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePass,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: '8+ characters',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 8) return 'Minimum 8 characters';
                                    if (!v.contains(RegExp(r'[A-Z]'))) return 'Must contain an uppercase letter';
                                    if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain a number';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Confirm Password
                                _Label('Confirm password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Re-enter password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                      icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textMuted),
                                    ),
                                  ),
                                  validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                                ),
                                const SizedBox(height: 20),

                                // Terms
                                GestureDetector(
                                  onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        width: 22, height: 22,
                                        margin: const EdgeInsets.only(top: 1),
                                        decoration: BoxDecoration(
                                          color: _termsAccepted ? AppColors.primaryBurgundy : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _termsAccepted ? AppColors.primaryBurgundy : AppColors.borderMedium,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _termsAccepted
                                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5),
                                            children: [
                                              const TextSpan(text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms of Service',
                                                style: const TextStyle(color: AppColors.primaryBurgundy, fontWeight: FontWeight.w700),
                                              ),
                                              const TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: const TextStyle(color: AppColors.primaryBurgundy, fontWeight: FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Error
                                if (_errorMsg != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(AppRadius.s),
                                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 28),

                                // Submit
                                _loading
                                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBurgundy))
                                    : GestureDetector(
                                        onTap: _submit,
                                        child: Container(
                                          height: 56,
                                            decoration: BoxDecoration(
                                              gradient: AppColors.roseGoldGradient,
                                              borderRadius: BorderRadius.circular(AppRadius.circular),
                                              boxShadow: [
                                                BoxShadow(color: AppColors.accentRoseGold.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: const Text('Create Account', style: TextStyle(color: AppColors.primaryDarkBurgundy, fontSize: 16, fontWeight: FontWeight.w800)),
                                          ),
                                      ),

                                const SizedBox(height: 24),

                                Center(
                                  child: GestureDetector(
                                    onTap: () => context.pushReplacement('/signin'),
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Already have an account?  ',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                        children: const [
                                          TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.primaryBurgundy, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;
  const _Label(this.label);
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.1),
      );
}
