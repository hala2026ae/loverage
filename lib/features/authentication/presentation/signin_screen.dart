import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/auth_repository_interface.dart';
import 'auth_brand_widgets.dart';
import 'auth_form_helpers.dart';

class SigninScreen extends ConsumerStatefulWidget {
  final String initialEmail;
  const SigninScreen({super.key, this.initialEmail = ''});

  @override
  ConsumerState<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends ConsumerState<SigninScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;
  String? _errorMsg;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
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

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmailAndPassword(
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
                    'Assets/auth_signin_argentina_nigeria_couple_hero.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
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
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
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
                        'Log in',
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

                // ── Form card ────────────────────────────────────────────
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

                                // Email field
                                _FieldLabel(label: 'Email address'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(fontSize: 15.0),
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

                                // Password field
                                _FieldLabel(label: 'Password'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _signIn(),
                                  style: const TextStyle(fontSize: 15.0),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
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
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.length < 6)
                                      ? 'Minimum 6 characters'
                                      : null,
                                ),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      final email = normalizeEmail(
                                        _emailCtrl.text,
                                      );
                                      context.push(
                                        email.isEmpty
                                            ? '/forgot-password'
                                            : '/forgot-password?email=${Uri.encodeComponent(email)}',
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 34),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: AppColors.primaryBurgundy,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Error message
                                if (_errorMsg != null) ...[
                                  const SizedBox(height: 4),
                                  _ErrorBanner(message: _errorMsg!),
                                  const SizedBox(height: 12),
                                ],

                                const SizedBox(height: 4),

                                // Sign in button
                                _loading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryBurgundy,
                                        ),
                                      )
                                    : AuthPrimaryButton(
                                        label: 'Sign In',
                                        onPressed: _signIn,
                                        tone: AuthPrimaryButtonTone.signIn,
                                      ),

                                const SizedBox(height: 24),

                                // Social divider
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(color: Color(0x44D4956A)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'or sign in with',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(color: Color(0x44D4956A)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _isLoadingGoogle
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: AppColors.primaryBurgundy,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : SocialAuthButton(
                                        icon: const GoogleLogo(),
                                        label: 'Continue with Google',
                                        onPressed: () async {
                                          setState(() {
                                            _isLoadingGoogle = true;
                                            _errorMsg = null;
                                          });
                                          try {
                                            final repo = ref.read(
                                              authRepositoryProvider,
                                            );
                                            await repo.signInWithGoogle();
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
                                const SizedBox(height: 20),

                                // Register link
                                Center(
                                  child: GestureDetector(
                                    onTap: () => context.push('/signup'),
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Don't have an account?  ",
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                        children: const [
                                          TextSpan(
                                            text: 'Create one',
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

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.07),
      borderRadius: BorderRadius.circular(AppRadius.s),
      border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
            style: const TextStyle(color: AppColors.error, fontSize: 13.0),
          ),
        ),
      ],
    ),
  );
}
