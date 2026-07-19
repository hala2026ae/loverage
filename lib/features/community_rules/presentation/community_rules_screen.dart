import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';
import '../../verification/presentation/face_verification_screen.dart';

class CommunityRulesScreen extends ConsumerStatefulWidget {
  const CommunityRulesScreen({super.key});

  @override
  ConsumerState<CommunityRulesScreen> createState() => _CommunityRulesScreenState();
}

class _CommunityRulesScreenState extends ConsumerState<CommunityRulesScreen> {
  bool _hasAccepted = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_hasAccepted) return;

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      final videoPath = ref.read(verificationVideoPathProvider);
      if (videoPath != null) {
        await authRepo.submitFaceVerification(videoPath);
      }
      
      // Save rules acceptance server-side
      await authRepo.acceptCommunityRules(
        rulesVersion: 'v1.0.0',
        locale: 'en',
        appVersion: '1.0.0',
      );

      // Navigate to main home feed
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      body: Stack(
        children: [
          // Background texture image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('Assets/home background .png'),
                  fit: BoxFit.cover,
                  opacity: 0.08,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBurgundy))
                : Column(
                    children: [
                      // Header Navigation
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/face-verification');
                                }
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFD4956A).withOpacity(0.4), width: 1.0),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Color(0xFF5A0E22),
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Scrollable content area
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'Assets/couple rigns.png',
                                width: 90.0,
                                height: 90.0,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loverage Community\nStandards',
                                textAlign: TextAlign.center,
                                style: AppTheme.serifHeadline(fontSize: 32, color: const Color(0xFF5A0E22)),
                              ),
                              const SizedBox(height: 12),
                              const DecorativeDivider(),
                              const SizedBox(height: 14),
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF7C6E7A),
                                    fontSize: 15.0,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(text: 'Please follow these rules to keep\n'),
                                    TextSpan(
                                      text: 'Loverage',
                                      style: TextStyle(
                                        color: Color(0xFF5A0E22),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ' respectful, safe, and marriage-focused.'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Rules List
                              _buildRuleItem(
                                number: 1,
                                title: 'Serious marriage only',
                                description: 'No hookups or casual dating.',
                                icon: Icons.favorite_outline_rounded,
                              ),
                              _buildRuleItem(
                                number: 2,
                                title: 'Be honest',
                                description: 'Be truthful about who you are and your intentions.',
                                icon: Icons.person_outline_rounded,
                              ),
                              _buildRuleItem(
                                number: 3,
                                title: 'Show respect',
                                description: 'Treat everyone with kindness and respect.',
                                icon: Icons.handshake_outlined,
                              ),
                              _buildRuleItem(
                                number: 4,
                                title: 'Keep it appropriate',
                                description: 'No nudity, sexual content, hate, harassment, threats, scams, or requests for money.',
                                icon: Icons.shield_outlined,
                              ),
                              _buildRuleItem(
                                number: 5,
                                title: 'Respect boundaries',
                                description: 'Respect privacy, consent, boundaries, and rejection.',
                                icon: Icons.lock_outline_rounded,
                              ),
                              _buildRuleItem(
                                number: 6,
                                title: 'Report harmful accounts',
                                description: 'Report fake, underage, abusive, or suspicious accounts.',
                                icon: Icons.flag_outlined,
                              ),
                              
                              const SizedBox(height: 16),
                              const WarningBanner(),
                              const SizedBox(height: 20),
                              
                              // Checkbox Agreement
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _hasAccepted = !_hasAccepted;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _hasAccepted ? const Color(0xFF5A0E22) : const Color(0xFFD4956A),
                                          width: 1.5,
                                        ),
                                        color: _hasAccepted ? const Color(0xFF5A0E22) : Colors.transparent,
                                      ),
                                      child: _hasAccepted
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Color(0xFF1A1219),
                                            fontSize: 14.5,
                                            height: 1.3,
                                          ),
                                          children: [
                                            TextSpan(text: 'I understand and agree to follow the '),
                                            TextSpan(
                                              text: 'Community Standards',
                                              style: TextStyle(
                                                color: Color(0xFF5A0E22),
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(text: '.'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              
                              // Agree & Continue Button
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Opacity(
                                  opacity: _hasAccepted ? 1.0 : 0.6,
                                  child: Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFF8C1A3A), Color(0xFF3D0717)],
                                      ),
                                      borderRadius: BorderRadius.circular(28.0),
                                      boxShadow: _hasAccepted ? AppShadows.button : null,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _hasAccepted ? _submit : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28.0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildButtonFlourishLeft(),
                                          const SizedBox(width: 14),
                                          const Text(
                                            'Agree & Continue',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          _buildButtonFlourishRight(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
    );
  }

  Widget _buildRuleItem({
    required int number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE6E2), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B0F2A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Flanked Icon
          SizedBox(
            width: 64,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: IconFlourishPainter(),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF5A0E22),
                    border: Border.all(color: const Color(0xFFE8B86D), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFE8B86D),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF3D0717),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF7C6E7A),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Checkmark on Right
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4956A).withOpacity(0.4), width: 1.0),
              color: const Color(0xFFFFFDF9),
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFFD4956A), size: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonFlourishLeft() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.keyboard_arrow_left_rounded, size: 10, color: Color(0xFFE8B86D)),
        const SizedBox(width: 2),
        Container(width: 12, height: 0.8, color: const Color(0xFFE8B86D)),
        const SizedBox(width: 2),
        const Icon(Icons.lens_blur_rounded, size: 8, color: Color(0xFFE8B86D)),
      ],
    );
  }

  Widget _buildButtonFlourishRight() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lens_blur_rounded, size: 8, color: Color(0xFFE8B86D)),
        const SizedBox(width: 2),
        Container(width: 12, height: 0.8, color: const Color(0xFFE8B86D)),
        const SizedBox(width: 2),
        const Icon(Icons.keyboard_arrow_right_rounded, size: 10, color: Color(0xFFE8B86D)),
      ],
    );
  }
}

class InterlockingRings extends StatelessWidget {
  const InterlockingRings({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Flourish line under rings
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(120, 20),
              painter: RingsFramePainter(),
            ),
          ),
          // Left Ring
          Positioned(
            left: 36,
            bottom: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8B86D), width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Right Ring
          Positioned(
            right: 36,
            bottom: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4956A), width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Top Heart
          Positioned(
            top: 2,
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFF6B0F2A),
              size: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class RingsFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFD4956A).withOpacity(0.6);

    // Soft scroll curves
    final path = Path()
      ..moveTo(10, size.height / 2)
      ..cubicTo(size.width * 0.25, size.height * 0.8, size.width * 0.75, size.height * 0.8, size.width - 10, size.height / 2)
      ..moveTo(20, size.height / 2 + 3)
      ..cubicTo(size.width * 0.35, size.height * 0.95, size.width * 0.65, size.height * 0.95, size.width - 20, size.height / 2 + 3);
    canvas.drawPath(path, paint);

    // Tiny dots at ends
    canvas.drawCircle(Offset(10, size.height / 2), 1.5, paint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(size.width - 10, size.height / 2), 1.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DecorativeDivider extends StatelessWidget {
  const DecorativeDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 60, height: 0.8, color: const Color(0xFFD4956A).withOpacity(0.5)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_left_rounded, size: 12, color: Color(0xFFD4956A)),
              Icon(Icons.diamond_rounded, size: 8, color: Color(0xFFD4956A)),
              Icon(Icons.keyboard_arrow_right_rounded, size: 12, color: Color(0xFFD4956A)),
            ],
          ),
        ),
        Container(width: 60, height: 0.8, color: const Color(0xFFD4956A).withOpacity(0.5)),
      ],
    );
  }
}

class IconFlourishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFD4956A).withOpacity(0.5);

    // Left flourish
    final pathLeft = Path()
      ..moveTo(2, size.height / 2)
      ..cubicTo(size.width * 0.15, size.height / 2 - 4, size.width * 0.2, size.height / 2 - 8, size.width * 0.28, size.height / 2)
      ..cubicTo(size.width * 0.2, size.height / 2 + 8, size.width * 0.15, size.height / 2 + 4, 2, size.height / 2);
    canvas.drawPath(pathLeft, paint);

    // Right flourish
    final pathRight = Path()
      ..moveTo(size.width - 2, size.height / 2)
      ..cubicTo(size.width * 0.85, size.height / 2 - 4, size.width * 0.8, size.height / 2 - 8, size.width * 0.72, size.height / 2)
      ..cubicTo(size.width * 0.8, size.height / 2 + 8, size.width * 0.85, size.height / 2 + 4, size.width - 2, size.height / 2);
    canvas.drawPath(pathRight, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAAFA1), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_arrow_left_rounded, size: 10, color: Color(0xFFD4956A)),
              Container(width: 14, height: 0.5, color: const Color(0xFFD4956A)),
              const Icon(Icons.keyboard_arrow_right_rounded, size: 10, color: Color(0xFFD4956A)),
            ],
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.shield_rounded,
            color: Color(0xFFB82020),
            size: 22,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Violations may lead to suspension or a permanent ban.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF3D0717),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_arrow_left_rounded, size: 10, color: Color(0xFFD4956A)),
              Container(width: 14, height: 0.5, color: const Color(0xFFD4956A)),
              const Icon(Icons.keyboard_arrow_right_rounded, size: 10, color: Color(0xFFD4956A)),
            ],
          ),
        ],
      ),
    );
  }
}
