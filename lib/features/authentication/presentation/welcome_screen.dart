import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/auth_repository_interface.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _isLoadingGoogle = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeCtrl.forward();
      _slideCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authRepo = ref.read(authRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryDarkBurgundy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Gradient ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundRadial,
            ),
          ),

          // ── Decorative rings ────────────────────────────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentRoseGold.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentRoseGold.withOpacity(0.18),
                  width: 1.0,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1.0,
                ),
              ),
            ),
          ),

          // ── Main Content ─────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.07),

                      // ── Logo ────────────────────────────────────────────
                      _buildLogo(),

                      SizedBox(height: size.height * 0.035),

                      // ── Heading ─────────────────────────────────────────
                      Text(
                        'Where Serious\nLove Begins',
                        textAlign: TextAlign.center,
                        style: AppTheme.serifHeadline(
                          fontSize: 38.0,
                          color: Colors.white,
                        ).copyWith(letterSpacing: -0.5, height: 1.15),
                      ),
                      const SizedBox(height: 14.0),
                      Text(
                        'A respectful platform for adults seeking\nmarriage and lasting commitment.',
                        textAlign: TextAlign.center,
                        style: AppTheme.sansText(
                          fontSize: 15.5,
                          weight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.65),
                          height: 1.6,
                        ),
                      ),

                      const Spacer(),

                      // ── CTA: Create Account ──────────────────────────────
                      _PrimaryGradientButton(
                        label: 'Create Account',
                        onPressed: () => context.push('/signup'),
                      ),
                      const SizedBox(height: 14.0),

                      // ── Sign In ──────────────────────────────────────────
                      GestureDetector(
                        onTap: () => context.push('/signin'),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppRadius.circular,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1.5,
                            ),
                            color: Colors.white.withOpacity(0.07),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24.0),

                      // ── Social Divider ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.40),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // ── Branded Social Buttons ──────────────────────────
                      Column(
                        children: [
                          _isLoadingGoogle
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: AppColors.accentRoseGold,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              : _GoogleSignInButton(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    setState(() => _isLoadingGoogle = true);
                                    try {
                                      await authRepo.signInWithGoogle();
                                    } catch (e) {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Google Sign-In failed: ${e.toString().replaceAll('Exception:', '')}',
                                            ),
                                            backgroundColor: AppColors.error,
                                          ),
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
                        ],
                      ),

                      const SizedBox(height: 24.0),

                      // ── Legal ───────────────────────────────────────────
                      Text(
                        'By continuing you agree to our Terms & Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withOpacity(0.30),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('Assets/couple rigns.png', height: 80, fit: BoxFit.contain),
        const SizedBox(height: 14),
        Image.asset(
          'Assets/loverage text.png',
          height: 30,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryGradientButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.roseGoldGradient,
          borderRadius: BorderRadius.circular(AppRadius.circular),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentRoseGold.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryDarkBurgundy,
            fontSize: 16.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.circular),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GoogleLogo(),
            const SizedBox(width: 10),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                color: Color(0xFF1F1F1F),
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(18, 18), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.square;

    // Red segment (Top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.35, 1.55, false, paint);

    // Yellow segment (Left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3.9, 1.55, false, paint);

    // Green segment (Bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.55, false, paint);

    // Blue segment (Right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.8, 1.6, false, paint);

    // Horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.05, cy - w * 0.11, w * 0.55, w * 0.22),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
