import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/app_theme.dart';
import '../../filters/presentation/filter_dialog.dart';
import '../../../core/data/loverage_repository.dart';
import '../../authentication/domain/account_status.dart';
import '../../verification/presentation/verification_pending_banner.dart';
import '../../../app/router/app_router.dart';

class HomeFeedTab extends ConsumerStatefulWidget {
  const HomeFeedTab({super.key});

  @override
  ConsumerState<HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends ConsumerState<HomeFeedTab>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  int _feedRequest = 0;
  static const _pageSize = 12;
  int _selectedFilter = 0;
  final List<String> _filterLabels = ['All', 'Nearby', 'New', 'Online'];
  List<FeedProfile> _profiles = [];
  List<String> _knockedProfileIds = [];
  List<String> _messagedProfileIds = [];
  final _scrollController = ScrollController();

  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _scrollController.addListener(_handleScroll);
    _loadFeed(reset: true);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  LoverageRepository get _repository =>
      LoverageRepository(Supabase.instance.client);

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 700) {
      _loadFeed();
    }
  }

  Future<void> _loadFeed({bool reset = false}) async {
    if (reset) {
      _feedRequest += 1;
      _page = 0;
      _hasMore = true;
      setState(() {
        _profiles = [];
        _isLoading = true;
        _isLoadingMore = false;
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }
    final request = _feedRequest;
    try {
      final rows = await _repository.feedProfiles(
        filter: _filterLabels[_selectedFilter],
        page: _page,
        pageSize: _pageSize,
      );
      final interactions = await _repository.feedInteractionStatuses();
      if (!mounted || request != _feedRequest) return;
      final loaded = rows.map(_profileFromRow).toList();
      setState(() {
        final ids = _profiles.map((profile) => profile.id).toSet();
        _profiles.addAll(loaded.where((profile) => ids.add(profile.id)));
        _knockedProfileIds = interactions['knocked'] ?? [];
        _messagedProfileIds = interactions['chat_requested'] ?? [];
        _page += 1;
        _hasMore = rows.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
      for (final profile in loaded.take(6)) {
        precacheImage(CachedNetworkImageProvider(profile.imageUrl), context);
      }
      Future.wait(
        loaded.take(4).map((profile) => _repository.profile(profile.id)),
      ).ignore();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
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
    ).then((_) => _loadFeed(reset: true));
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authStatusProvider).valueOrNull;
    final isPendingReview = authStatus == AccountStatus.verificationPending;
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
          controller: _scrollController,
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

            if (isPendingReview)
              const SliverToBoxAdapter(child: VerificationPendingBanner()),

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
                          _loadFeed(reset: true);
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
                        final isKnocked = _knockedProfileIds.contains(
                          profile.id,
                        );
                        final isMessaged = _messagedProfileIds.contains(
                          profile.id,
                        );
                        return _ProfileGridCard(
                          key: ValueKey(
                            '${profile.id}_${isKnocked}_${isMessaged}',
                          ),
                          profile: profile,
                          initialKnocked: isKnocked,
                          initialMessaged: isMessaged,
                          onTap: () => context.push(
                            '/profile/${profile.id}?knocked=$isKnocked&messaged=$isMessaged',
                          ),
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
              if (_isLoadingMore)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.61,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => _ShimmerCard(ctrl: _shimmerCtrl),
                      childCount: 2,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _sendKnock(FeedProfile profile) async {
    final authStatus = ref.read(authStatusProvider).valueOrNull;
    if (authStatus?.isApproved != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your Account is under review will be active soon.'),
          backgroundColor: Color(0xFFD4AF37),
        ),
      );
      return false;
    }
    try {
      await _repository.createKnock(profile.id);
      if (!mounted) return false;
      setState(() {
        _knockedProfileIds.add(profile.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: _BrandedKnockSentToast(name: profile.name),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: const Duration(seconds: 3),
        ),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      if (e is DailyActionLimitException) {
        _showDailyLimitSheet(e);
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send knock: $e')));
      return false;
    }
  }

  Future<bool> _openConversation(FeedProfile profile) async {
    final authStatus = ref.read(authStatusProvider).valueOrNull;
    if (authStatus?.isApproved != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your Account is under review will be active soon.'),
          backgroundColor: Color(0xFFD4AF37),
        ),
      );
      return false;
    }
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (sheetContext) => _QuickMessageSheet(
        profile: profile,
        onSend: (message) => _sendQuickMessage(profile, message),
      ),
    );
    return sent ?? false;
  }

  Future<void> _sendQuickMessage(FeedProfile profile, String message) async {
    try {
      await _repository.createChatRequest(profile.id, message);
      if (!mounted) return;
      setState(() {
        _messagedProfileIds.add(profile.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: _BrandedMessageSentToast(name: profile.name),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (e is DailyActionLimitException) {
        _showDailyLimitSheet(e);
        rethrow;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send message: $e')));
      rethrow;
    }
  }

  Future<void> _showDailyLimitSheet(DailyActionLimitException limit) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (sheetContext) => _DailyLimitSheet(
        limit: limit,
        onUpgrade: () {
          Navigator.pop(sheetContext);
          context.push('/paywall');
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Premium Grid Card
// ──────────────────────────────────────────────────────────────────────────────
class _ProfileGridCard extends StatefulWidget {
  final FeedProfile profile;
  final bool initialKnocked;
  final bool initialMessaged;
  final VoidCallback onTap;
  final Future<bool> Function() onKnock;
  final Future<bool> Function() onMessage;
  const _ProfileGridCard({
    super.key,
    required this.profile,
    this.initialKnocked = false,
    this.initialMessaged = false,
    required this.onTap,
    required this.onKnock,
    required this.onMessage,
  });

  @override
  State<_ProfileGridCard> createState() => _ProfileGridCardState();
}

class _ProfileGridCardState extends State<_ProfileGridCard> {
  late bool _knocked;
  late bool _messaged;
  bool _isOpeningMessage = false;
  bool _isSendingKnock = false;

  @override
  void initState() {
    super.initState();
    _knocked = widget.initialKnocked;
    _messaged = widget.initialMessaged;
  }

  Future<void> _handleKnock() async {
    if (_knocked || _isSendingKnock) return;
    setState(() => _isSendingKnock = true);
    try {
      final sent = await widget.onKnock();
      if (mounted && sent) setState(() => _knocked = true);
    } catch (_) {
      // Knock failed (daily limit, etc.) — don't change state
    } finally {
      if (mounted) setState(() => _isSendingKnock = false);
    }
  }

  Future<void> _handleMessage() async {
    if (_messaged || _isOpeningMessage) return;
    setState(() => _isOpeningMessage = true);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    setState(() => _isOpeningMessage = false);
    final sent = await widget.onMessage();
    if (mounted && sent) setState(() => _messaged = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final actionFontSize = MediaQuery.sizeOf(context).width < 360 ? 10.0 : 11.0;
    final messageFontSize = _messaged ? actionFontSize - 1.0 : actionFontSize;
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
              CachedNetworkImage(
                imageUrl: p.imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (_, __) =>
                    const ColoredBox(color: Color(0xFFEDE6E2)),
                errorWidget: (_, __, ___) => Container(
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
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF6B0F2A),
                                          Color(0xFF3D0717),
                                        ],
                                      )
                                    : AppColors.premiumBurgundyGradient,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.circular,
                                ),
                                border: Border.all(
                                  color: _knocked
                                      ? const Color(
                                          0xFFE8B86D,
                                        ).withOpacity(0.85)
                                      : const Color(0xFFD4956A),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _knocked
                                        ? const Color(
                                            0xFF2E0713,
                                          ).withOpacity(0.26)
                                        : const Color(
                                            0xFF380512,
                                          ).withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      if (_isSendingKnock)
                                        const SizedBox(
                                          width: 13,
                                          height: 13,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.8,
                                            color: Color(0xFFF7D5C4),
                                          ),
                                        )
                                      else if (_knocked)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: Color(0xFFE8B86D),
                                        )
                                      else
                                        SvgPicture.asset(
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
                                        _isSendingKnock
                                            ? 'Sending'
                                            : _knocked
                                                ? 'Sent'
                                                : 'Knock',
                                        style: TextStyle(
                                          color: _knocked
                                              ? const Color(0xFFFFE8C8)
                                              : const Color(0xFFF7D5C4),
                                          fontSize: actionFontSize,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Chat (translucent floating pill action)
                        Expanded(
                          child: GestureDetector(
                            onTap: _handleMessage,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 32,
                              decoration: BoxDecoration(
                                color: _messaged
                                    ? const Color(0xFF6B0F2A).withOpacity(0.88)
                                    : Colors.white.withOpacity(0.2),
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      if (_isOpeningMessage)
                                        const SizedBox(
                                          width: 13,
                                          height: 13,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.8,
                                            color: Colors.white,
                                          ),
                                        )
                                      else if (_messaged)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 12,
                                          color: Color(0xFFE8B86D),
                                        )
                                      else
                                        Image.asset(
                                          'Assets/Messages.png',
                                          width: 13,
                                          height: 13,
                                          color: Colors.white,
                                        ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _isOpeningMessage
                                            ? 'Opening'
                                            : _messaged
                                                ? 'Messaged'
                                                : 'Message',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: messageFontSize,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

class _BrandedKnockSentToast extends StatelessWidget {
  final String name;

  const _BrandedKnockSentToast({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7A1230), Color(0xFF4D0A1E)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8B86D).withOpacity(0.72)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2A0611).withOpacity(0.30),
          blurRadius: 22,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFE8B86D).withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE8B86D)),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFFFFE8C8),
            size: 15,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Knock sent to $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFF2E2),
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BrandedMessageSentToast extends StatelessWidget {
  final String name;

  const _BrandedMessageSentToast({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7A1230), Color(0xFF4D0A1E)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8B86D).withOpacity(0.72)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2A0611).withOpacity(0.30),
          blurRadius: 22,
          spreadRadius: -4,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFE8B86D).withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE8B86D)),
          ),
          child: const Icon(
            Icons.send_rounded,
            color: Color(0xFFFFE8C8),
            size: 13,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Message request sent to $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFF2E2),
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _QuickMessageSheet extends StatefulWidget {
  final FeedProfile profile;
  final Future<void> Function(String message) onSend;

  const _QuickMessageSheet({required this.profile, required this.onSend});

  @override
  State<_QuickMessageSheet> createState() => _QuickMessageSheetState();
}

class _QuickMessageSheetState extends State<_QuickMessageSheet> {
  static const _maxLength = 300;
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await widget.onSend(text);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final remaining = _maxLength - _controller.text.length;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.58,
        minChildSize: 0.42,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFAF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8C9C5),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: const Color(0xFFE8B86D),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF34121D).withOpacity(0.14),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: CachedNetworkImage(
                          imageUrl: widget.profile.imageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 100),
                          placeholder: (_, __) =>
                              const ColoredBox(color: Color(0xFFF1E7E3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message ${widget.profile.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.profile.city}, ${widget.profile.country}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isSending
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.primaryBurgundy,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE9D8D2)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34121D).withOpacity(0.10),
                        blurRadius: 28,
                        spreadRadius: -10,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLength: _maxLength,
                    minLines: 5,
                    maxLines: 8,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Write a thoughtful message...',
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(16, 15, 16, 15),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Image.asset(
                      'Assets/Messages.png',
                      width: 15,
                      height: 15,
                      color: AppColors.primaryBurgundy,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Sends as a request first',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$remaining',
                      style: TextStyle(
                        color: remaining < 80
                            ? AppColors.error
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSending
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(
                            color: AppColors.primaryBurgundy.withOpacity(0.24),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.primaryBurgundy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final enabled =
                              _controller.text.trim().isNotEmpty && !_isSending;
                          return GestureDetector(
                            onTap: enabled ? _send : null,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 160),
                              opacity: enabled || _isSending ? 1 : 0.55,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF8B1234),
                                      Color(0xFF520B20),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE8B86D),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF520B20,
                                      ).withOpacity(0.28),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFFFE8C8),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.send_rounded,
                                            color: Color(0xFFFFE8C8),
                                            size: 17,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Send Request',
                                            style: TextStyle(
                                              color: Color(0xFFFFE8C8),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyLimitSheet extends StatelessWidget {
  final DailyActionLimitException limit;
  final VoidCallback onUpgrade;

  const _DailyLimitSheet({required this.limit, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final title = limit.action == 'knock'
        ? 'Daily knocks used'
        : 'Daily chats used';
    final body = limit.action == 'knock'
        ? 'You used all ${limit.limit} knocks for today. Upgrade for unlimited actions or wait until your daily refill.'
        : 'You used all ${limit.limit} chat requests for today. Upgrade for more access or wait until your daily refill.';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFAF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8C9C5),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B1234), Color(0xFF520B20)],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFE8B86D)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF520B20).withOpacity(0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: Color(0xFFFFE8C8),
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${limit.sent}/${limit.limit} used',
                      style: const TextStyle(
                        color: AppColors.primaryBurgundy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(
                      color: AppColors.primaryBurgundy.withOpacity(0.24),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Wait',
                    style: TextStyle(
                      color: AppColors.primaryBurgundy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onUpgrade,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B1234), Color(0xFF520B20)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8B86D)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF520B20).withOpacity(0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Upgrade Plan',
                      style: TextStyle(
                        color: Color(0xFFFFE8C8),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
