import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentIndex = 0;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  static const _pages = [
    _PageData(
      icon: Icons.favorite_border_rounded,
      title: 'Built for Serious\nIntentions',
      description: 'Loverage connects adults who are genuinely seeking marriage, commitment, and a respectful long-term relationship — not casual dating.',
      gradient: [Color(0xFF8C1A3A), Color(0xFF3D0717)],
    ),
    _PageData(
      icon: Icons.verified_user_outlined,
      title: 'Real People,\nSafer Connections',
      description: 'Every profile goes through a face verification process before appearing in the community. No fake profiles, no bots.',
      gradient: [Color(0xFF6B0F2A), Color(0xFF2A0510)],
    ),
    _PageData(
      icon: Icons.handshake_outlined,
      title: 'Connect with\nRespect',
      description: 'Send a Knock to express genuine interest. Start a conversation only after both sides feel comfortable. No pressure.',
      gradient: [Color(0xFF4D0A1E), Color(0xFF1E0309)],
    ),
    _PageData(
      icon: Icons.security_outlined,
      title: 'You Stay\nin Control',
      description: 'Choose who you respond to, set strict privacy controls, and report concerns at any time. Your comfort is our priority.',
      gradient: [Color(0xFF7A1530), Color(0xFF330812)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) context.go('/welcome');
  }

  void _next() {
    if (_currentIndex < _pages.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _pages[_currentIndex].gradient,
              ),
            ),
          ),

          // Decorative circle
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.07), width: 1.5),
              ),
            ),
          ),
          Positioned(
            bottom: -90, left: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.0),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: TextButton(
                      onPressed: _complete,
                      child: Text(
                        'Skip',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) {
                      _animCtrl.forward(from: 0);
                      setState(() => _currentIndex = i);
                    },
                    itemBuilder: (_, i) {
                      final page = _pages[i];
                      return FadeTransition(
                        opacity: _fadeAnim,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon container
                              Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                                ),
                                child: Icon(page.icon, size: 56, color: Colors.white),
                              ),
                              const SizedBox(height: 44),

                              Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                page.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active ? AppColors.accentRoseGold : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(AppRadius.circular),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // CTA
                      GestureDetector(
                        onTap: _next,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.roseGoldGradient,
                            borderRadius: BorderRadius.circular(AppRadius.circular),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentRoseGold.withOpacity(0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex == _pages.length - 1 ? 'Begin Your Journey' : 'Continue',
                                style: const TextStyle(
                                  color: AppColors.primaryDarkBurgundy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryDarkBurgundy, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _PageData {
  final IconData icon;
  final String title, description;
  final List<Color> gradient;
  const _PageData({required this.icon, required this.title, required this.description, required this.gradient});
}
