import 'dart:math';
import 'dart:ui'; // Required for ImageFilter backdrop blur
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import 'home_feed_tab.dart';
import '../../knocks/presentation/knocks_tab.dart';
import '../../conversations/presentation/chats_tab.dart';
import '../../account/presentation/account_settings_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomeFeedTab(),
    KnocksTab(),
    ChatsTab(),
    AccountSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Extend body to the bottom of the screen under the navigation bar
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _LoverageNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Redesigned Custom Bottom Nav Bar (Glassmorphic Minimalist Olive Green 4-Tab)
// ──────────────────────────────────────────────────────────────────────────────
class _LoverageNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LoverageNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, max(8.0, bottomPadding * 0.45)),
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4E5340).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none, // Allow active badge to float outside the bar
        children: [
          // Glassy capsule background layer (clipped to bounds)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF8C1A3A).withOpacity(0.92), // Translucent brand burgundy
                        const Color(0xFF3D0717).withOpacity(0.95), // Translucent brand dark burgundy
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFF8C1A3A).withOpacity(0.3), // Soft red-burgundy border
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Interactive tab items layer (unclipped to allow badge overflow)
          Positioned.fill(
            child: Row(
              children: List.generate(4, (i) {
                final isActive = currentIndex == i;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: double.infinity,
                      decoration: BoxDecoration(
                        // Translucent white active highlight on dark burgundy
                        color: isActive ? Colors.white.withOpacity(0.14) : Colors.transparent,
                        borderRadius: i == 0
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(30.0),
                                bottomLeft: Radius.circular(30.0),
                              )
                            : i == 3
                                ? const BorderRadius.only(
                                    topRight: Radius.circular(30.0),
                                    bottomRight: Radius.circular(30.0),
                                  )
                                : BorderRadius.zero,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none, // Allow badge to float outside the tab Stack
                        alignment: Alignment.center,
                        children: [
                          // Active Top Couple Rings Badge with Red Branding Gradient Circle
                          if (isActive)
                            Positioned(
                              top: -10, // Float halfway outside the top border
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBurgundy.withOpacity(0.35),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1.0),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Image.asset(
                                  'Assets/couple rigns.png',
                                  width: 12,
                                  height: 12,
                                  fit: BoxFit.contain,
                                  color: Colors.white, // High contrast white tint
                                ),
                              ),
                            ),
                          // The Image Asset Icon
                          // Render SVG or PNG icon centered vertically & horizontally
                          _getIconPath(i).endsWith('.svg')
                              ? SvgPicture.asset(
                                  _getIconPath(i),
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    isActive ? Colors.white : Colors.white.withOpacity(0.45),
                                    BlendMode.srcIn,
                                  ),
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  _getIconPath(i),
                                  width: 24,
                                  height: 24,
                                  color: isActive ? Colors.white : Colors.white.withOpacity(0.45),
                                  fit: BoxFit.contain,
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getIconPath(int index) {
    switch (index) {
      case 0:
        return 'Assets/Lovest Discover .png';
      case 1:
        return 'Assets/knock new .svg';
      case 2:
        return 'Assets/Messages.png';
      case 3:
      default:
        return 'Assets/Profile.png';
    }
  }
}
