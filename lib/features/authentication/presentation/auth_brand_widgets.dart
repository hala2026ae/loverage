import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AuthPhotoHeader extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final Widget? leading;

  const AuthPhotoHeader({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(imagePath, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x661E0106),
                  Color(0x331E0106),
                  Color(0xF61E0106),
                ],
                stops: [0.0, 0.48, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 24, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 44, child: leading),
                  const Spacer(),
                  Image.asset(
                    'Assets/loverage text.png',
                    height: 26,
                    fit: BoxFit.contain,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: AppTheme.serifHeadline(
                      fontSize: 34,
                      color: Colors.white,
                    ).copyWith(height: 1.05),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: AppTheme.sansText(
                      fontSize: 14.5,
                      weight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.78),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SocialAuthButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final bool dark;

  const SocialAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? const Color(0xFF141114) : Colors.white,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.10)
                  : AppColors.borderMedium.withOpacity(0.75),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.12 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: dark ? Colors.white : AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AuthPrimaryButtonTone { onboarding, signIn }

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final AuthPrimaryButtonTone tone;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = AuthPrimaryButtonTone.onboarding,
  });

  @override
  Widget build(BuildContext context) {
    final isSignIn = tone == AuthPrimaryButtonTone.signIn;
    final gradient = isSignIn
        ? const LinearGradient(
            colors: [Color(0xFF9A2946), Color(0xFF5A0A1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFF3B89F), Color(0xFFC07357)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
    final foreground = isSignIn ? Colors.white : const Color(0xFF3D0717);
    final shadowColor = isSignIn
        ? const Color(0xFF5A0A1E)
        : const Color(0xFFC07357);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: isSignIn ? 54 : 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(isSignIn ? 27.0 : 26.0),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSignIn ? 27.0 : 26.0),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSignIn)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: foreground,
                        size: 17,
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: foreground,
                      size: 18,
                    ),
                ],
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
    return CustomPaint(size: const Size(19, 19), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: w / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.square;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.35, 1.55, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3.9, 1.55, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.55, false, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.8, 1.6, false, paint);

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
