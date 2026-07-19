import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/loverage_repository.dart';
import '../../authentication/domain/account_status.dart';
import '../../verification/presentation/verification_pending_banner.dart';
import '../../../app/router/app_router.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final String profileId;
  final bool isSelfPreview;
  final bool initialKnocked;
  final bool initialMessaged;

  const ProfileDetailScreen({
    super.key,
    required this.profileId,
    this.isSelfPreview = false,
    this.initialKnocked = false,
    this.initialMessaged = false,
  });

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  late bool _knocked;
  late bool _chatRequested;
  bool _isSending = false;
  bool _isLoadingProfile = true;
  bool _isLoadingInteraction = true;
  Map<String, dynamic>? _profile;
  final _scrollCtrl = ScrollController();
  bool _showTopTitle = false;

  @override
  void initState() {
    super.initState();
    _knocked = widget.initialKnocked;
    _chatRequested = widget.initialMessaged;
    _isLoadingInteraction = !_knocked && !_chatRequested;
    _profile = _repository.cachedProfile(widget.profileId);
    _isLoadingProfile = _profile == null;
    _loadProfile();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 220;
      if (show != _showTopTitle) setState(() => _showTopTitle = show);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  LoverageRepository get _repository =>
      LoverageRepository(Supabase.instance.client);

  String get _displayName => (_profile?['public_name'] as String?) ?? _name;
  int get _displayAge => (_profile?['age'] as num?)?.toInt() ?? _age;
  String get _displayCity {
    final city = _profile?['public_city'] as String?;
    final country = _profile?['public_country_code'] as String?;
    if (city != null && country != null && country.isNotEmpty)
      return '$city, $country';
    return city ?? country ?? _city;
  }

  String get _displayProfession =>
      (_profile?['profession'] as String?) ?? _profession;
  String get _displayBio => (_profile?['bio'] as String?) ?? _bio;
  String get _profileImageUrl => _repository.photoUrl(_profile);
  List<String> get _displayTraits =>
      List<String>.from((_profile?['traits'] as List?) ?? _traits);
  DateTime? get _joinedAt =>
      DateTime.tryParse((_profile?['created_at'] ?? '').toString());
  bool get _isNewProfile {
    final joined = _joinedAt;
    return joined != null && DateTime.now().difference(joined).inDays <= 14;
  }

  bool get _isVerified => _profile?['verification_status'] == 'approved';
  String get _joinedLabel {
    final joined = _joinedAt;
    if (joined == null) return 'Joined recently';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Joined ${months[joined.month - 1]} ${joined.year}';
  }

  List<_InfoRow> get _displayAbout {
    final list = <_InfoRow>[];

    final prof = (_profile?['profession'] as String?)?.trim();
    if (prof != null &&
        prof.isNotEmpty &&
        prof.toLowerCase() != 'not specified') {
      list.add(_InfoRow(Icons.badge_rounded, 'Profession', prof));
    }

    final edu = (_profile?['education'] as String?)?.trim();
    if (edu != null && edu.isNotEmpty && edu.toLowerCase() != 'not specified') {
      list.add(_InfoRow(Icons.school_rounded, 'Education', edu));
    }

    final langList = _profile?['languages'] as List?;
    if (langList != null && langList.isNotEmpty) {
      final langs = langList.join(', ').trim();
      if (langs.isNotEmpty && langs.toLowerCase() != 'not specified') {
        list.add(_InfoRow(Icons.translate_rounded, 'Languages', langs));
      }
    }

    final rel = (_profile?['religion'] as String?)?.trim();
    if (rel != null && rel.isNotEmpty && rel.toLowerCase() != 'not specified') {
      list.add(_InfoRow(Icons.mosque_rounded, 'Religion', rel));
    }

    return list;
  }

  Future<void> _loadProfile() async {
    try {
      final row = await _repository.profile(widget.profileId);
      final interaction = await _repository.profileInteractionStatus(
        widget.profileId,
      );
      if (!mounted) return;
      setState(() {
        _profile = row;
        // Only upgrade state (false→true), never downgrade (true→false)
        // This prevents flicker when navigating with initial state already set
        if (interaction['knocked'] == true) _knocked = true;
        if (interaction['chat_requested'] == true) _chatRequested = true;
        _isLoadingProfile = false;
        _isLoadingInteraction = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _isLoadingInteraction = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load profile: $e')));
    }
  }

  // Fallback profile used only while the real profile loads.
  static const _imageUrl =
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800';
  static const _name = 'Elizabeth';
  static const _age = 26;
  static const _city = 'London, UK';
  static const _profession = 'Architect';
  static const _bio =
      'Family-oriented and faith-driven. I believe the foundation of a strong marriage is built on mutual respect, open communication, and shared values. I enjoy cooking for people I care about, long weekend walks, and deep conversations over good coffee.\n\nI am looking for someone who is serious about building a future together — someone kind, grounded, and genuinely ready to commit.';
  static const _traits = [
    'Family-first',
    'Faith',
    'Sincere',
    'Creative',
    'Calm',
  ];
  static final _about = [
    _InfoRow(Icons.work_outline_rounded, 'Profession', _profession),
    _InfoRow(Icons.school_outlined, 'Education', 'Masters in Architecture'),
    _InfoRow(Icons.language_rounded, 'Languages', 'English, French'),
    _InfoRow(Icons.mosque_outlined, 'Religion', 'Muslim'),
    _InfoRow(Icons.child_friendly_outlined, 'Children', 'Wants 2–3 children'),
    _InfoRow(Icons.smoking_rooms_rounded, 'Smoking', 'Non-smoker'),
  ];

  Widget _buildButtonShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8DEDA),
      highlightColor: const Color(0xFFF8F4F1),
      period: const Duration(milliseconds: 1050),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
      ),
    );
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
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                // ── Hero Photo ───────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.58,
                  pinned: true,
                  backgroundColor: AppColors.primaryDarkBurgundy,
                  elevation: 0,
                  leading: _AppBarBtn(
                    icon: widget.isSelfPreview
                        ? Icons.close_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    onTap: () => widget.isSelfPreview
                        ? Navigator.of(context).pop()
                        : context.pop(),
                  ),
                  actions: widget.isSelfPreview
                      ? null
                      : [
                          _AppBarBtn(
                            icon: Icons.more_vert_rounded,
                            onTap: () => _showOptions(context),
                          ),
                          const SizedBox(width: 8),
                        ],
                  title: AnimatedOpacity(
                    opacity: _showTopTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '$_displayName, $_displayAge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _profileImageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 120),
                          placeholder: (_, __) => const ColoredBox(
                            color: AppColors.primaryDarkBurgundy,
                          ),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.primaryDarkBurgundy),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.4, 1.0],
                              colors: [Colors.transparent, Color(0xEE000000)],
                            ),
                          ),
                        ),
                        // Name/Location overlay
                        Positioned(
                          bottom: 24,
                          left: 20,
                          right: 80,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$_displayName, $_displayAge',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  if (_isVerified) ...[
                                    const SizedBox(width: 7),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF60A5FA),
                                      size: 22,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white60,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _displayCity,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.circular,
                                      ),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Text(
                                      _displayProfession,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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

                // ── Body Content ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.58,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(38),
                        topRight: Radius.circular(38),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPendingReview && !widget.isSelfPreview)
                          const VerificationPendingBanner(),
                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_isNewProfile) const _MetaChip(label: 'New'),
                              _MetaChip(label: _joinedLabel),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Traits
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _displayTraits
                                .map((t) => _TraitChip(label: t))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bio
                        _Section(
                          title: 'About Me',
                          child: Text(
                            _displayBio,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.5,
                              height: 1.7,
                            ),
                          ),
                        ),

                        // Info rows
                        if (_displayAbout.isNotEmpty)
                          _Section(
                            title: 'Profile Details',
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 2.7,
                                  ),
                              itemCount: _displayAbout.length,
                              itemBuilder: (context, index) {
                                final r = _displayAbout[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFF1ECEB),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.015),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBurgundy
                                              .withOpacity(0.06),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          r.icon,
                                          size: 15,
                                          color: AppColors.primaryBurgundy,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              r.label,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              r.value,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_isLoadingProfile)
              const Positioned.fill(child: _ProfileDetailShimmer()),

            // ── Bottom Action Bar ────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  border: const Border(
                    top: BorderSide(color: AppColors.borderLight),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: widget.isSelfPreview
                    ? const _SelfPreviewActions()
                    : _isLoadingInteraction
                    ? Row(
                        children: [
                          Expanded(child: _buildButtonShimmer()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildButtonShimmer()),
                        ],
                      )
                    : Row(
                        children: [
                          // Message button
                          Expanded(
                            child: GestureDetector(
                              onTap: _chatRequested ? null : _openConversation,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: _chatRequested
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFE5DCDA),
                                            Color(0xFFCBBFBC),
                                          ],
                                        )
                                      : AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.circular,
                                  ),
                                  border: Border.all(
                                    color: _chatRequested
                                        ? const Color(0xFFD4C8C5)
                                        : const Color(
                                            0xFFF7D5C4,
                                          ).withOpacity(0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: _chatRequested
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: AppColors.primaryBurgundy
                                                .withOpacity(0.2),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _chatRequested
                                            ? const Icon(
                                                Icons.check_circle_rounded,
                                                size: 16,
                                                color: Color(0xFF8C7D7A),
                                              )
                                            : Image.asset(
                                                'Assets/Messages.png',
                                                width: 16,
                                                height: 16,
                                                color: const Color(0xFFF7D5C4),
                                              ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _chatRequested ? 'Messaged' : 'Message',
                                          style: TextStyle(
                                            color: _chatRequested
                                                ? const Color(0xFF8C7D7A)
                                                : const Color(0xFFF7D5C4),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Knock button
                          Expanded(
                            child: _isSending
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryBurgundy,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _sendKnock,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      height: 52,
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
                                            : AppColors.roseGoldGradient,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.circular,
                                        ),
                                        border: Border.all(
                                          color: _knocked
                                              ? const Color(
                                                  0xFFE8B86D,
                                                ).withOpacity(0.85)
                                              : AppColors.primaryBurgundy
                                                    .withOpacity(0.1),
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _knocked
                                                ? const Color(
                                                    0xFF2E0713,
                                                  ).withOpacity(0.26)
                                                : AppColors.accentRoseGold
                                                      .withOpacity(0.35),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _knocked
                                                  ? const Icon(
                                                      Icons.check_circle_rounded,
                                                      color: Color(0xFFE8B86D),
                                                      size: 16,
                                                    )
                                                  : SvgPicture.asset(
                                                      'Assets/knock new .svg',
                                                      width: 16,
                                                      height: 16,
                                                      colorFilter:
                                                          const ColorFilter.mode(
                                                            AppColors
                                                                .primaryDarkBurgundy,
                                                            BlendMode.srcIn,
                                                          ),
                                                    ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _knocked ? 'Sent' : 'Knock',
                                                style: TextStyle(
                                                  color: _knocked
                                                      ? const Color(0xFFFFE8C8)
                                                      : AppColors
                                                            .primaryDarkBurgundy,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  letterSpacing: 0.1,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendKnock() async {
    final authStatus = ref.read(authStatusProvider).valueOrNull;
    if (authStatus?.isApproved != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your Account is under review will be active soon.'),
          backgroundColor: Color(0xFFD4AF37),
        ),
      );
      return;
    }
    if (_knocked) return;
    setState(() => _isSending = true);
    try {
      await _repository.createKnock(widget.profileId);
      if (!mounted) return;
      setState(() {
        _knocked = true;
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: _BrandedKnockSentToast(name: _displayName),
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
      setState(() => _isSending = false);
      if (e is DailyActionLimitException) {
        _showDailyLimitSheet(e);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send knock: $e')));
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

  Future<void> _openConversation() async {
    final authStatus = ref.read(authStatusProvider).valueOrNull;
    if (authStatus?.isApproved != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your Account is under review will be active soon.'),
          backgroundColor: Color(0xFFD4AF37),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _ProfileMessageRequestSheet(
        name: _displayName,
        imageUrl: _profileImageUrl,
        location: _displayCity,
        onSend: _sendMessageRequest,
      ),
    );
  }

  Future<void> _sendMessageRequest(String message) async {
    try {
      await _repository.createChatRequest(widget.profileId, message);
      if (!mounted) return;
      setState(() => _chatRequested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: _BrandedMessageRequestSentToast(name: _displayName),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message request: $e')),
      );
      rethrow;
    }
  }

  void _showOptions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.block_rounded, color: AppColors.error),
              title: const Text('Block User'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(
                Icons.flag_outlined,
                color: AppColors.warning,
              ),
              title: const Text('Report Profile'),
              onTap: () {},
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SelfPreviewActions extends StatelessWidget {
  const _SelfPreviewActions();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _DisabledProfileAction(
          icon: Image.asset(
            'Assets/Messages.png',
            width: 16,
            height: 16,
            color: const Color(0xFFAAA1A4),
          ),
          label: 'Message',
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _DisabledProfileAction(
          icon: SvgPicture.asset(
            'Assets/knock new .svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFFAAA1A4),
              BlendMode.srcIn,
            ),
          ),
          label: 'Send Knock',
        ),
      ),
    ],
  );
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

class _BrandedMessageRequestSentToast extends StatelessWidget {
  final String name;

  const _BrandedMessageRequestSentToast({required this.name});

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

class _ProfileMessageRequestSheet extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String location;
  final Future<void> Function(String message) onSend;

  const _ProfileMessageRequestSheet({
    required this.name,
    required this.imageUrl,
    required this.location,
    required this.onSend,
  });

  @override
  State<_ProfileMessageRequestSheet> createState() =>
      _ProfileMessageRequestSheetState();
}

class _ProfileMessageRequestSheetState
    extends State<_ProfileMessageRequestSheet> {
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
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxLength - _controller.text.length;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
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
            const SizedBox(height: 18),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 100),
                    placeholder: (_, __) =>
                        const ColoredBox(color: Color(0xFFF1E7E3)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message ${widget.name}',
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
                        widget.location,
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
                  onPressed: _isSending ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.primaryBurgundy,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE9D8D2)),
              ),
              child: TextField(
                controller: _controller,
                maxLength: _maxLength,
                minLines: 4,
                maxLines: 6,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Write a thoughtful request...',
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(16, 15, 16, 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
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
                    color: remaining < 30
                        ? AppColors.error
                        : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
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
                          colors: [Color(0xFF8B1234), Color(0xFF520B20)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8B86D)),
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
                          : const Text(
                              'Send Request',
                              style: TextStyle(
                                color: Color(0xFFFFE8C8),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
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

class _DisabledProfileAction extends StatelessWidget {
  final Widget icon;
  final String label;

  const _DisabledProfileAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Unavailable on your own profile',
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEEF),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: const Color(0xFFE2DCDE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAA1A4),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.all(8),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _ProfileDetailShimmer extends StatelessWidget {
  const _ProfileDetailShimmer();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.backgroundLight,
    child: Shimmer.fromColors(
      baseColor: const Color(0xFFE8DEDA),
      highlightColor: const Color(0xFFF8F4F1),
      period: const Duration(milliseconds: 1050),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Color(0xFFE2D7D2)),
                  ),
                  Positioned(
                    top: 12,
                    left: 16,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 90,
                    bottom: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 150,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        3,
                        (_) => Container(
                          width: 78,
                          height: 30,
                          margin: const EdgeInsets.only(right: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(height: 15),
                    for (final width in [
                      double.infinity,
                      double.infinity,
                      230.0,
                    ])
                      Container(
                        width: width,
                        height: 13,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TraitChip extends StatelessWidget {
  final String label;
  const _TraitChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primaryBurgundy.withOpacity(0.08),
      borderRadius: BorderRadius.circular(AppRadius.circular),
      border: Border.all(color: AppColors.primaryBurgundy.withOpacity(0.2)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryBurgundy,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primaryBurgundy.withOpacity(0.07),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.primaryBurgundy.withOpacity(0.16)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.primaryBurgundy,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final _InfoRow row;
  const _InfoTile({required this.row});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryBurgundy.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(row.icon, size: 18, color: AppColors.primaryBurgundy),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                row.value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoRow {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
}
