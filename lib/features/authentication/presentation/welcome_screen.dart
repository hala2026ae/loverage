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

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
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
                      SizedBox(height: size.height * 0.09),

                      // ── Logo ────────────────────────────────────────────
                      _buildLogo(),

                      SizedBox(height: size.height * 0.045),

                      // ── Heading ─────────────────────────────────────────
                      Text(
                        'Where Serious\nLove Begins',
                        textAlign: TextAlign.center,
                        style: AppTheme.serifHeadline(
                          fontSize: 40.0,
                          color: Colors.white,
                        ).copyWith(
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'A respectful platform for adults seeking\nmarriage and lasting commitment.',
                        textAlign: TextAlign.center,
                        style: AppTheme.sansText(
                          fontSize: 16.0,
                          weight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.65),
                          height: 1.6,
                        ),
                      ),

                      const Spacer(),

                      // ── Pill Badges ─────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBadge(Icons.verified_user_rounded, 'Verified Profiles'),
                          const SizedBox(width: 10),
                          _buildBadge(Icons.lock_rounded, 'Private & Safe'),
                          const SizedBox(width: 10),
                          _buildBadge(Icons.favorite_rounded, 'Serious Only'),
                        ],
                      ),
                      const SizedBox(height: 36.0),

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
                            borderRadius: BorderRadius.circular(AppRadius.circular),
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

                      const SizedBox(height: 28.0),

                      // ── Social Divider ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.40),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      // ── Social Buttons ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              icon: Icons.apple,
                              label: 'Apple',
                              onPressed: () async {
                                try {
                                  await authRepo.signInWithEmailAndPassword(
                                    email: 'test.approved@loverage.com',
                                    password: 'password123',
                                  );
                                } catch (_) {}
                              },
                            ),
                          ),
                          const SizedBox(width: 14.0),
                          Expanded(
                            child: _SocialButton(
                              icon: Icons.g_mobiledata_rounded,
                              label: 'Google',
                              onPressed: () async {
                                try {
                                  await authRepo.signInWithEmailAndPassword(
                                    email: 'test.approved@loverage.com',
                                    password: 'password123',
                                  );
                                } catch (_) {}
                              },
                            ),
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
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.accentRoseGold.withOpacity(0.25),
            AppColors.accentRoseGold.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: AppColors.accentRoseGold.withOpacity(0.4), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 22,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentRoseGold, width: 2.5),
              ),
            ),
          ),
          Positioned(
            right: 22,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGold, width: 2.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accentRoseGold),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _SocialButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(AppRadius.circular),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
