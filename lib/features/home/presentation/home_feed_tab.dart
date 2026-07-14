import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/app_theme.dart';
import '../../filters/presentation/filter_dialog.dart';
import '../../../core/data/loverage_repository.dart';

class HomeFeedTab extends ConsumerStatefulWidget {
  const HomeFeedTab({super.key});

  @override
  ConsumerState<HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends ConsumerState<HomeFeedTab>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  int _selectedFilter = 0;
  final List<String> _filterLabels = ['All', 'Nearby', 'New', 'Online'];
  List<FeedProfile> _profiles = [];

  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadFeed();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  LoverageRepository get _repository =>
      LoverageRepository(Supabase.instance.client);

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _repository.feedProfiles(
        filter: _filterLabels[_selectedFilter],
      );
      if (!mounted) return;
      setState(() {
        _profiles = rows.map(_profileFromRow).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profiles = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load profiles: $e')));
    }
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterDialog(),
    ).then((_) => _loadFeed());
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
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors
                  .transparent, // Transparent to show flexibleSpace gradient
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight:
                  56, // Standard height for better breathing room under notch
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors
                      .primaryGradient, // Premium brand gradient matching Knocks/Chats
                ),
              ),
              title: Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Image.asset(
                        'Assets/loverage text.png',
                        height: 26,
                        color: Colors
                            .white, // Tint white for high contrast on burgundy
                        fit: BoxFit.contain,
                      ),
                    ),
                    const TextSpan(
                      text: '  |  ',
                      style: TextStyle(
                        color: Colors.white60, // Light white vertical separator
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    TextSpan(
                      text: 'Where Serious Hearts Meet for Marriage',
                      style: AppTheme.sansText(
                        fontSize: 11.0,
                        weight: FontWeight.w600,
                        color: Colors.white.withOpacity(
                          0.9,
                        ), // Light white slogan
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                _AppBarIconButton(
                  iconPath: 'Assets/filters home.png', // Custom filters asset
                  onTap: _openFilters,
                  hasBadge: false,
                ),
                _AppBarIconButton(
                  iconPath:
                      'Assets/notifications home.png', // Custom notifications asset
                  onTap: () => context.push('/notifications'),
                  hasBadge: true,
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Filter Chips ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  10,
                ), // Added padding on the upper side
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filterLabels.length, (i) {
                      final selected = _selectedFilter == i;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedFilter = i);
                          _loadFeed();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6,
                          ), // Smaller padding
                          decoration: BoxDecoration(
                            gradient: selected
                                ? AppColors.primaryGradient
                                : null,
                            color: selected
                                ? null
                                : const Color(
                                    0xFFF5EFEB,
                                  ), // Soft warm cream background
                            borderRadius: BorderRadius.circular(
                              AppRadius.circular,
                            ),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : const Color(0xFFEADBCE).withOpacity(0.4),
                              width: 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryBurgundy
                                          .withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _filterLabels[i],
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12.0, // Smaller font size
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // ── Profile Grid ───────────────────────────────────────────────
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.61,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ShimmerCard(ctrl: _shimmerCtrl),
                    childCount: 4,
                  ),
                ),
              )
            else if (_profiles.isEmpty)
              const SliverFillRemaining(child: _EmptyFeedState())
            else ...[
              for (
                int chunkIndex = 0;
                chunkIndex * 8 < _profiles.length;
                chunkIndex++
              ) ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.61,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final profileIndex = chunkIndex * 8 + index;
                        final profile = _profiles[profileIndex];
                        return _ProfileGridCard(
                          profile: profile,
                          onTap: () => context.push('/profile/${profile.id}'),
                          onKnock: () => _sendKnock(profile),
                          onMessage: () => _openConversation(profile),
                        );
                      },
                      childCount: (chunkIndex * 8 + 8 <= _profiles.length)
                          ? 8
                          : _profiles.length - (chunkIndex * 8),
                    ),
                  ),
                ),
                if (chunkIndex * 8 + 8 <= _profiles.length)
                  const SliverToBoxAdapter(child: _AdMobBannerCard()),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendKnock(FeedProfile profile) async {
    try {
      await _repository.createKnock(profile.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Knock sent to ${profile.name}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send knock: $e')));
    }
  }

  Future<void> _openConversation(FeedProfile profile) async {
    try {
      final id = await _repository.getOrCreateConversation(profile.id);
      if (mounted) context.push('/chat/$id');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open chat: $e')));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Premium Grid Card
// ──────────────────────────────────────────────────────────────────────────────
class _ProfileGridCard extends StatefulWidget {
  final FeedProfile profile;
  final VoidCallback onTap;
  final VoidCallback onKnock;
  final VoidCallback onMessage;
  const _ProfileGridCard({
    required this.profile,
    required this.onTap,
    required this.onKnock,
    required this.onMessage,
  });

  @override
  State<_ProfileGridCard> createState() => _ProfileGridCardState();
}

class _ProfileGridCardState extends State<_ProfileGridCard> {
  bool _knocked = false;

  void _handleKnock() {
    if (_knocked) return;
    setState(() => _knocked = true);
    widget.onKnock();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.l),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 3,
              offset: const Offset(0, 1.5),
            ),
          ],
          border: Border.all(color: AppColors.borderLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.l),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo background occupying full bleed
              Image.network(
                p.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.cardCream,
                  child: const Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

              // Gradient vignette overlay for maximum readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 0.7, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ),

              // Country Flag on top left corner
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    _getCountryFlag(p.country),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),

              if (p.isNew)
                Positioned(
                  top: 40,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF), // Premium iOS blue tag
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Online / Last Seen Badge on top right
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: p.isOnline
                              ? const Color(0xFF22C55E)
                              : const Color(
                                  0xFF94A3B8,
                                ), // Green if online, slate grey if offline
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.isOnline ? 'Online' : p.lastActive,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Overlaid Information & Floating Action Buttons
              Positioned(
                bottom: 12,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Age Row
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: p.isPremium ? 5.0 : 0.0,
                                ),
                                child: Text(
                                  '${p.name}, ${p.age}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (p.isPremium)
                                Positioned(
                                  left: -5,
                                  top: -9,
                                  child: Transform.rotate(
                                    angle: -0.785, // -45 degrees
                                    child: Image.asset(
                                      'Assets/Gold mem.png',
                                      width: 15,
                                      height: 15,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (p.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF60A5FA),
                            size: 14,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Modern Translucent Capsules for Location & Distance
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFFF2C4A0),
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${p.city}, ${p.country}',
                                style: const TextStyle(
                                  color: Color(0xFFF7F7F7), // off-white
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_outlined,
                                color: Color(0xFF60A5FA),
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${p.distance} mi away',
                                style: const TextStyle(
                                  color: Color(0xFFF7F7F7),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Floating action buttons row
                    Row(
                      children: [
                        // Knock (floating pill action)
                        Expanded(
                          child: GestureDetector(
                            onTap: _handleKnock,
                            child: Container(
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: _knocked
                                    ? null
                                    : AppColors.premiumBurgundyGradient,
                                color: _knocked
                                    ? AppColors.success.withOpacity(0.9)
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.circular,
                                ),
                                border: _knocked
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFD4956A),
                                        width: 1.0,
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _knocked
                                        ? Colors.black.withOpacity(0.12)
                                        : const Color(
                                            0xFF380512,
                                          ).withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _knocked
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        )
                                      : SvgPicture.asset(
                                          'Assets/knock new .svg',
                                          width: 14,
                                          height: 14,
                                          colorFilter: const ColorFilter.mode(
                                            Color(0xFFF7D5C4),
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _knocked ? 'Sent' : 'Knock',
                                    style: TextStyle(
                                      color: _knocked
                                          ? Colors.white
                                          : const Color(0xFFF7D5C4),
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Chat (translucent floating pill action)
                        Expanded(
                          child: GestureDetector(
                            onTap: widget.onMessage,
                            child: Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.circular,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'Assets/Messages.png',
                                    width: 13,
                                    height: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Chat',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  String _getCountryFlag(String country) {
    switch (country.toLowerCase().trim()) {
      case 'uk':
      case 'united kingdom':
      case 'england':
        return '🇬🇧';
      case 'usa':
      case 'united states':
      case 'america':
        return '🇺🇸';
      case 'canada':
        return '🇨🇦';
      case 'france':
        return '🇫🇷';
      case 'uae':
      case 'dubai':
      case 'united arab emirates':
        return '🇦🇪';
      case 'egypt':
      case 'cairo':
        return '🇪🇬';
      case 'turkey':
      case 'istanbul':
        return '🇹🇷';
      default:
        return '🏳️';
    }
  }
}

class _AppBarIconButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onTap;
  final bool hasBadge;
  const _AppBarIconButton({
    required this.iconPath,
    required this.onTap,
    required this.hasBadge,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF7D5C4).withOpacity(0.25),
            const Color(0xFFC57A68).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF7D5C4).withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF380512).withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 20, // Increased size to let details shine
            height: 20,
            fit: BoxFit.contain, // Preserved raw asset gradient and details
          ),
          if (hasBadge)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5252), // Vibrant red badge dot
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ShimmerCard extends StatelessWidget {
  final AnimationController ctrl;
  const _ShimmerCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final gradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [ctrl.value - 0.3, ctrl.value, ctrl.value + 0.3],
          colors: const [
            Color(0xFFEDE6E2),
            Color(0xFFF7F3EF),
            Color(0xFFEDE6E2),
          ],
        );
        return Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppRadius.l),
          ),
        );
      },
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryBurgundy.withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: AppColors.primaryBurgundy,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No profiles match your filters',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Try widening your search preferences',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    ),
  );
}

FeedProfile _profileFromRow(Map<String, dynamic> row) {
  final repo = LoverageRepository(Supabase.instance.client);
  final seen = DateTime.tryParse((row['last_seen_at'] ?? '').toString());
  final created = DateTime.tryParse((row['created_at'] ?? '').toString());
  final isOnline =
      seen != null && DateTime.now().difference(seen).inMinutes < 15;
  final isNew =
      created != null && DateTime.now().difference(created).inDays < 14;
  return FeedProfile(
    id: row['id'].toString(),
    name: (row['public_name'] as String?)?.trim().isNotEmpty == true
        ? row['public_name'] as String
        : 'Loverage member',
    age: (row['age'] as num?)?.toInt() ?? 0,
    city: (row['public_city'] as String?) ?? 'Nearby',
    country: (row['public_country_code'] as String?) ?? '',
    profession: (row['profession'] as String?) ?? 'Member',
    imageUrl: repo.photoUrl(row),
    isVerified: row['verification_status'] == 'approved',
    isOnline: isOnline,
    isNew: isNew,
    distance: 0,
    lastActive: isOnline ? 'Online' : _timeAgo(seen),
    bioPreview: (row['bio'] as String?) ?? '',
    traits: List<String>.from((row['traits'] as List?) ?? const []),
    isPremium: row['is_premium'] == true,
  );
}

String _timeAgo(DateTime? value) {
  if (value == null) return 'Recently';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class FeedProfile {
  final String id,
      name,
      city,
      country,
      profession,
      imageUrl,
      bioPreview,
      lastActive;
  final int age, distance;
  final bool isVerified, isOnline, isNew, isPremium;
  final List<String> traits;

  const FeedProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.country,
    required this.profession,
    required this.imageUrl,
    required this.isVerified,
    required this.isOnline,
    required this.bioPreview,
    required this.traits,
    required this.distance,
    required this.lastActive,
    this.isNew = false,
    this.isPremium = false,
  });
}

class _AdMobBannerCard extends StatelessWidget {
  const _AdMobBannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8B86D).withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ad Icon Placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFE8B86D),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Ad Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBurgundy,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Loverage Premium Plus',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Unlock unlimited swipes, direct matches, and double the chats!',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              gradient: AppColors.roseGoldGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentRoseGold.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(
                color: AppColors.primaryDarkBurgundy,
                fontSize: 11.0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
