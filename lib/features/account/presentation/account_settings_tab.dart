import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';

class AccountSettingsTab extends ConsumerStatefulWidget {
  const AccountSettingsTab({super.key});

  @override
  ConsumerState<AccountSettingsTab> createState() => _AccountSettingsTabState();
}

class _AccountSettingsTabState extends ConsumerState<AccountSettingsTab> {
  bool _isSigningOut = false;
  final _scrollCtrl = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 240;
      if (show != _showTitle) {
        setState(() => _showTitle = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('Assets/home background .png'),
            fit: BoxFit.cover,
          ),
        ),
        child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ── Profile Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 440,
            pinned: true,
            backgroundColor: const Color(0xFF5A0E22),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(),
            ),
             title: AnimatedOpacity(
              opacity: _showTitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    'Zara A.',
                    style: AppTheme.sansText(
                      fontSize: 16.0,
                      weight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.9),
                    ).copyWith(
                      letterSpacing: 0.5,
                    ),
                  ),
                  Positioned(
                    left: -12,
                    top: -10,
                    child: Transform.rotate(
                      angle: -0.785, // -45 degrees
                      child: Image.asset(
                        'Assets/Gold mem.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: true,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _StatsDashboard(),
                const SizedBox(height: 20),
                // Premium Banner
                _PremiumBanner(onTap: () => context.push('/paywall')),
                const SizedBox(height: 24),

                // Account section
                _SectionHeader(title: 'Account'),
                _SettingsGroup(items: [
                  _SettingsItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () {}),
                  _SettingsItem(icon: Icons.photo_library_outlined, label: 'Manage Photos', onTap: () {}),
                  _SettingsItem(icon: Icons.verified_user_outlined, label: 'Verification', onTap: () {}, trailing: _VerifiedBadge()),
                ]),
                const SizedBox(height: 20),

                // Preferences section
                _SectionHeader(title: 'Preferences'),
                _SettingsGroup(items: [
                  _SettingsItem(icon: Icons.tune_rounded, label: 'Match Preferences', onTap: () => context.push('/filters')),
                  _SettingsItem(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () {}),
                  _SettingsItem(icon: Icons.language_rounded, label: 'Language', onTap: () {}, trailing: const Text('English', style: TextStyle(color: AppColors.textMuted, fontSize: 13.5))),
                ]),
                const SizedBox(height: 20),

                // Privacy section
                _SectionHeader(title: 'Privacy & Safety'),
                _SettingsGroup(items: [
                  _SettingsItem(icon: Icons.visibility_off_outlined, label: 'Hide Profile', onTap: () {}, trailing: _Toggle()),
                  _SettingsItem(icon: Icons.block_rounded, label: 'Blocked Users', onTap: () {}),
                  _SettingsItem(icon: Icons.report_outlined, label: 'Report an Issue', onTap: () {}),
                ]),
                const SizedBox(height: 20),

                // Support section
                _SectionHeader(title: 'Support'),
                _SettingsGroup(items: [
                  _SettingsItem(icon: Icons.help_outline_rounded, label: 'Help Center', onTap: () {}),
                  _SettingsItem(icon: Icons.article_outlined, label: 'Terms of Service', onTap: () {}),
                  _SettingsItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
                ]),
                const SizedBox(height: 28),

                // Sign Out
                _isSigningOut
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBurgundy))
                    : GestureDetector(
                        onTap: _signOut,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            border: Border.all(color: AppColors.error.withOpacity(0.25)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 12),

                // Delete account
                Center(
                  child: TextButton(
                    onPressed: () => _showDeleteConfirm(context),
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    await ref.read(authRepositoryProvider).signOut();
  }

  void _showDeleteConfirm(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({super.key});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  final List<String> _profileImages = [
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400', // Center Main
    'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400', // Left
    'https://images.unsplash.com/photo-1524504388940-b1c1722553e1?w=400', // Right
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
  ];
  int _mainImageIndex = 0;
  int _selectedImageIndex = 0;
  final ScrollController _galleryScrollCtrl = ScrollController();
  String? _animatingImageUrl;

  @override
  void dispose() {
    _galleryScrollCtrl.dispose();
    super.dispose();
  }

  void _setAsMain(int index) async {
    if (index == _mainImageIndex) return;

    final selectedUrl = _profileImages[index];

    setState(() {
      _animatingImageUrl = selectedUrl;
    });

    // Smoothly fade out the selected photo from its current slot
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    setState(() {
      _profileImages.removeAt(index);
      _profileImages.insert(0, selectedUrl); // Re-insert at start
      _mainImageIndex = 0;
      _selectedImageIndex = 0;
      _animatingImageUrl = null;
    });

    // Auto-scroll back to centering the newly designated main photo
    _galleryScrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Center title
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  'Zara A.',
                  style: AppTheme.sansText(
                    fontSize: 16.0,
                    weight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.9),
                  ).copyWith(
                    letterSpacing: 0.5,
                  ),
                ),
                Positioned(
                  left: -12,
                  top: -10,
                  child: Transform.rotate(
                    angle: -0.785, // -45 degrees
                    child: Image.asset(
                      'Assets/Gold mem.png',
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 1,
                  color: const Color(0xFFD4956A).withOpacity(0.4),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.favorite_rounded, color: Color(0xFFD4956A), size: 10),
                ),
                Container(
                  width: 24,
                  height: 1,
                  color: const Color(0xFFD4956A).withOpacity(0.4),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Horizontal scrollable gallery row
            SizedBox(
              height: 108,
              child: SingleChildScrollView(
                controller: _galleryScrollCtrl,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(_profileImages.length, (index) {
                    final isSelected = _selectedImageIndex == index;
                    final isMain = _mainImageIndex == index;
                    final imageUrl = _profileImages[index];
                    final isAnimatingThis = _animatingImageUrl == imageUrl;

                    return GestureDetector(
                      onTap: _animatingImageUrl != null ? null : () {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isAnimatingThis ? 0.0 : 1.0,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 200),
                          scale: isAnimatingThis ? 0.35 : 1.0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              width: isSelected ? 104 : 64,
                              height: isSelected ? 104 : 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(isSelected ? 24 : 14),
                                border: Border.all(
                                  color: isMain 
                                      ? const Color(0xFFE8B86D) // Gold border for main image
                                      : isSelected 
                                          ? const Color(0xFFD4956A) // Rose gold for selected
                                          : const Color(0xFFD4956A).withOpacity(0.3), // Muted for unselected
                                  width: isMain ? 2.2 : isSelected ? 1.8 : 1.2,
                                ),
                              ),
                              padding: EdgeInsets.all(isMain ? 3 : 1.5),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(isSelected ? 18 : 11),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                    if (!isSelected)
                                      Container(
                                        color: Colors.black.withOpacity(0.35),
                                      ),
                                    if (isMain)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8B86D),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'MAIN',
                                            style: TextStyle(
                                              color: Color(0xFF1E1015),
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w900,
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
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Icon + text under the main middle one to "Set As Main"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _animatingImageUrl != null
                      ? null
                      : () => _setAsMain(_selectedImageIndex),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    backgroundColor: Colors.white.withOpacity(0.06),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: const Color(0xFFE8B86D).withOpacity(0.3), width: 0.8),
                    ),
                  ),
                  icon: Icon(
                    _mainImageIndex == _selectedImageIndex
                        ? Icons.check_circle_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFE8B86D),
                    size: 12,
                  ),
                  label: Text(
                    _mainImageIndex == _selectedImageIndex
                        ? 'Main Profile Photo'
                        : 'Set As Main',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFFE8B86D),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Text(
                  'Zara A.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Positioned(
                  left: -20,
                  top: -18,
                  child: Transform.rotate(
                    angle: -0.785, // -45 degrees
                    child: Image.asset(
                      'Assets/Gold mem.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.location_on_outlined, color: Color(0xFFD4956A), size: 16),
                SizedBox(width: 4),
                Text(
                  'Toronto, Canada',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3D0717),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFD4956A), width: 1.0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFFD48E7C), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3D0717), Color(0xFF6B0F2A), Color(0xFF3D0717)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8B86D), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8B86D).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              'Assets/Gold mem.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Unlock unlimited matches & advanced filters',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8B86D), width: 1.5),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE8B86D), size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
      );
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: e.value.onTap,
                borderRadius: BorderRadius.circular(AppRadius.l),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBurgundy.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(e.value.icon, size: 18, color: AppColors.primaryBurgundy),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(e.value.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                      if (e.value.trailing != null) ...[e.value.trailing!, const SizedBox(width: 8)],
                      const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(indent: 66, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _SettingsItem({required this.icon, required this.label, required this.onTap, this.trailing});
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 13),
            SizedBox(width: 4),
            Text('Active', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 11.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _Toggle extends StatefulWidget {
  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _val = false;
  @override
  Widget build(BuildContext context) => Switch(
        value: _val,
        onChanged: (v) => setState(() => _val = v),
        activeColor: AppColors.primaryBurgundy,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}

class _StatsDashboard extends StatefulWidget {
  const _StatsDashboard();

  @override
  State<_StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<_StatsDashboard> {
  Timer? _limitResetTimer;
  Duration _timeUntilReset = Duration.zero;

  void _calculateTimeUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _timeUntilReset = tomorrow.difference(now);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilReset();
    _limitResetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeUntilReset();
        });
      }
    });
  }

  @override
  void dispose() {
    _limitResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE6E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'Assets/rest new.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Text(
                'Daily Limits & Usage',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1219),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 12, color: Color(0xFFD4956A)),
                  const SizedBox(width: 3),
                  Text(
                    'resets in ${_formatDuration(_timeUntilReset)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFD4956A),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8B86D).withOpacity(0.25), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A0E22).withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A0E22).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'Assets/knock new .svg',
                              width: 14,
                              height: 14,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF5A0E22),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Knocks Left',
                              style: TextStyle(
                                color: Color(0xFF1E1015),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '12 / 20',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A0E22),
                          fontFamily: 'Inter',
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EAE6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * (12 / 20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF5A0E22),
                                      Color(0xFFD4956A),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '60% remaining',
                        style: TextStyle(
                          color: Color(0xFFD4956A),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8B86D).withOpacity(0.25), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5A0E22).withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8B86D).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'Assets/Messages.png',
                              width: 14,
                              height: 14,
                              color: const Color(0xFFC59F4E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Chats Left',
                              style: TextStyle(
                                color: Color(0xFF1E1015),
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '3 / 5',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC59F4E),
                          fontFamily: 'Inter',
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EAE6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * (3 / 5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFC59F4E),
                                      Color(0xFFF7D070),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '60% remaining',
                        style: TextStyle(
                          color: Color(0xFFD4956A),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
