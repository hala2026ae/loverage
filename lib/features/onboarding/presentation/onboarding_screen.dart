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
      imagePath: 'Assets/onboard_serious.png',
      title: 'Serious Only',
      description: 'Loverage is built for people genuinely looking for marriage and a life partner. If you’re only looking for fun, casual dating, or short-term connections, Loverage is not the right place for you.',
      badgeIcons: [
        Icons.favorite_border_rounded,
        Icons.diamond_outlined,
        Icons.diversity_3_rounded,
        Icons.home_outlined,
      ],
      centerBadgeIcon: Icons.favorite_rounded,
    ),
    _PageData(
      imagePath: 'Assets/onboard_verified.png',
      title: 'Real People.\nSafer Connections.',
      highlightText: 'Every member completes face verification before joining.',
      description: 'We work hard to keep Loverage safe, trusted, and focused on genuine people from different places around the world. Profiles that do not follow our community rules may be removed.',
      badgeIcons: [
        Icons.verified_user_outlined,
        Icons.lock_outlined,
        Icons.groups_3_outlined,
        Icons.public_rounded,
      ],
      centerBadgeIcon: Icons.check_rounded,
    ),
    _PageData(
      imagePath: 'Assets/onboard_connect.png',
      title: 'Knock. Connect.\nStart a Conversation.',
      highlightText: 'Send a Knock to show someone you’re interested.',
      description: 'When they accept, the Knock turns into a private chat so you can start getting to know each other.',
      badgeIcons: [
        Icons.forum_outlined,
        Icons.touch_app_outlined,
        Icons.volunteer_activism_outlined,
        Icons.chat_outlined,
      ],
      centerBadgeIcon: Icons.question_answer_rounded,
    ),
    _PageData(
      imagePath: 'Assets/onboard_respectful.png',
      title: 'Keep It Respectful',
      highlightText: 'Share only respectful, appropriate, and genuine photos.',
      description: 'Nudity, sexual or revealing content, violence, misleading images, and offensive or not respectful content are not allowed on Loverage.',
      badgeIcons: [
        Icons.gpp_good_outlined,
        Icons.sentiment_satisfied_rounded,
        Icons.visibility_outlined,
        Icons.shield_outlined,
      ],
      centerBadgeIcon: Icons.shield_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF450916), Color(0xFF1E0106)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextButton(
                    onPressed: _complete,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

              // Page Content Carousel
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
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. Center illustration with circle, badges, and verified badge
                            _buildCenterIllustration(i),
                            const SizedBox(height: 36),

                            // 2. Title
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: AppTheme.serifHeadline(fontSize: 32, color: Colors.white),
                            ),
                            const SizedBox(height: 16),

                            // 3. Optional Highlight Text
                            if (page.highlightText != null) ...[
                              Text(
                                page.highlightText!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Color(0xFFF3B89F),
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 4. Description
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                page.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14.5,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Area (Dots & Continue Button)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                child: Column(
                  children: [
                    // Page indicator dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFD4956A) : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Continue button
                    GestureDetector(
                      onTap: _next,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF3B89F), Color(0xFFC07357)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(26.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC07357).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentIndex == _pages.length - 1 ? 'Start Journey' : 'Continue',
                              style: const TextStyle(
                                color: Color(0xFF3D0717),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF3D0717),
                              size: 18,
                            ),
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
      ),
    );
  }

  Widget _buildCenterIllustration(int index) {
    final page = _pages[index];

    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Dotted Ring
          CustomPaint(
            size: const Size(280, 280),
            painter: DottedRingPainter(
              color: const Color(0xFFE5A68A).withOpacity(0.25),
              strokeWidth: 1.0,
              gap: 5.0,
            ),
          ),

          // 2. Central Circle couple photo (Enlarged)
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE5A68A).withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 3. Badges on the ring (Placed precisely via calculated angles)
          Positioned(
            left: 33,
            top: 50,
            child: _buildBadgeIcon(page.badgeIcons[0]),
          ),
          Positioned(
            right: 33,
            top: 50,
            child: _buildBadgeIcon(page.badgeIcons[1]),
          ),
          Positioned(
            left: 33,
            bottom: 50,
            child: _buildBadgeIcon(page.badgeIcons[2]),
          ),
          Positioned(
            right: 33,
            bottom: 50,
            child: _buildBadgeIcon(page.badgeIcons[3]),
          ),

          // 4. Overlapping verified badge at 6 o'clock
          Positioned(
            bottom: 32,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3B89F), Color(0xFFC07357)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(
                  color: const Color(0xFF1E0106), // matches dark background of the card to look cut out
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                page.centerBadgeIcon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E0106).withOpacity(0.85),
        border: Border.all(
          color: const Color(0xFFE5A68A).withOpacity(0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: const Color(0xFFE5A68A),
        size: 18,
      ),
    );
  }
}

class DottedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DottedRingPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final double circumference = 2 * 3.14159 * radius;
    final double dashAngle = (3.0 / circumference) * 2 * 3.14159;
    final double gapAngle = (gap / circumference) * 2 * 3.14159;

    double currentAngle = 0.0;
    while (currentAngle < 2 * 3.14159) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        currentAngle,
        dashAngle,
        false,
        paint,
      );
      currentAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageData {
  final String imagePath;
  final String title;
  final String? highlightText;
  final String description;
  final List<IconData> badgeIcons;
  final IconData centerBadgeIcon;

  const _PageData({
    required this.imagePath,
    required this.title,
    this.highlightText,
    required this.description,
    required this.badgeIcons,
    required this.centerBadgeIcon,
  });
}
