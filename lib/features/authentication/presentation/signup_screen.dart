import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/auth_repository_interface.dart';
import 'auth_brand_widgets.dart';
import 'auth_form_helpers.dart';

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
  bool _obscurePass = true;
  bool _termsAccepted = false;
  bool _loading = false;
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;
  String? _errorMsg;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 100), _animCtrl.forward);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      setState(
        () => _errorMsg =
            'You must agree to the Terms of Service and Privacy Policy.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithEmailAndPassword(
            email: normalizeEmail(_emailCtrl.text),
            password: _passCtrl.text,
          );
    } catch (e) {
      setState(() => _errorMsg = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoadingApple = true;
      _errorMsg = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
    } catch (e) {
      if (mounted) setState(() => _errorMsg = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoadingApple = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'Assets/auth_signup_german_filipina_couple_hero.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x442B020B),
                          Color(0x223C0715),
                          Color(0xFF1E0106),
                        ],
                        stops: [0.0, 0.52, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'Assets/loverage text.png',
                        height: 30,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create New Account',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: (MediaQuery.of(context).size.height * 0.305)
                      .clamp(250.0, 315.0)
                      .toDouble(),
                ),

                // Form card
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
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
                          border: Border.fromBorderSide(
                            BorderSide(color: Color(0xFFFFE1D4)),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 22,
                              offset: Offset(0, -6),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    width: 46,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.roseGoldGradient,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),

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
                                    filled: true,
                                    fillColor: Color(0xFFFFFBFA),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(18),
                                      ),
                                      borderSide: BorderSide(
                                        color: Color(0xFFEADDD8),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(18),
                                      ),
                                      borderSide: BorderSide(
                                        color: AppColors.primaryBurgundy,
                                        width: 1.4,
                                      ),
                                    ),
                                    prefixIconConstraints: BoxConstraints(
                                      minWidth: 48,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  validator: validateEmailAddress,
                                ),
                                const SizedBox(height: 14),

                                // Password
                                _Label('Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscurePass,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: '8+ characters',
                                    filled: true,
                                    fillColor: const Color(0xFFFFFBFA),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(18),
                                      ),
                                      borderSide: BorderSide(
                                        color: Color(0xFFEADDD8),
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(18),
                                      ),
                                      borderSide: BorderSide(
                                        color: AppColors.primaryBurgundy,
                                        width: 1.4,
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 48,
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minWidth: 48,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                      color: AppColors.textMuted,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass,
                                      ),
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 8) {
                                      return 'Minimum 8 characters';
                                    }
                                    if (!v.contains(RegExp(r'[A-Z]'))) {
                                      return 'Must contain an uppercase letter';
                                    }
                                    if (!v.contains(RegExp(r'[0-9]'))) {
                                      return 'Must contain a number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Terms
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _termsAccepted = !_termsAccepted,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        width: 22,
                                        height: 22,
                                        margin: const EdgeInsets.only(top: 1),
                                        decoration: BoxDecoration(
                                          color: _termsAccepted
                                              ? AppColors.primaryBurgundy
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: _termsAccepted
                                                ? AppColors.primaryBurgundy
                                                : AppColors.borderMedium,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _termsAccepted
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'I agree to the ',
                                              ),
                                              TextSpan(
                                                text: 'Terms of Service',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.primaryBurgundy,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.primaryBurgundy,
                                                  fontWeight: FontWeight.w700,
                                                ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.s,
                                      ),
                                      border: Border.all(
                                        color: AppColors.error.withOpacity(0.3),
                                      ),
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
                                            _errorMsg!,
                                            style: const TextStyle(
                                              color: AppColors.error,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 18),

                                // Submit
                                _loading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryBurgundy,
                                        ),
                                      )
                                    : AuthPrimaryButton(
                                        label: 'Create Account',
                                        onPressed: _submit,
                                      ),

                                const SizedBox(height: 16),

                                Row(
                                  children: const [
                                    Expanded(
                                      child: Divider(color: Color(0x44D4956A)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'OR SIGN UP WITH',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: Color(0x44D4956A)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _isLoadingGoogle
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryBurgundy,
                                        ),
                                      )
                                    : SocialAuthButton(
                                        icon: const GoogleLogo(),
                                        label: 'Sign in with Google',
                                        onPressed: () async {
                                          setState(() {
                                            _isLoadingGoogle = true;
                                            _errorMsg = null;
                                          });
                                          try {
                                            await ref
                                                .read(authRepositoryProvider)
                                                .signInWithGoogle();
                                          } catch (e) {
                                            if (mounted) {
                                              setState(
                                                () => _errorMsg =
                                                    authErrorMessage(e),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                () => _isLoadingGoogle = false,
                                              );
                                            }
                                          }
                                        },
                                      ),
                                const SizedBox(height: 18),

                                Center(
                                  child: GestureDetector(
                                    onTap: () =>
                                        context.pushReplacement('/signin'),
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Already have an account?  ',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: 'Sign In',
                                            style: TextStyle(
                                              color: AppColors.primaryBurgundy,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
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
    style: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.1,
    ),
  );
}
