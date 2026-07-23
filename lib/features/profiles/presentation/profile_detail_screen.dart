import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../core/presentation/loverage_image.dart';
import '../../../core/utils/country_helper.dart';

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final String profileId;
  final bool isSelfPreview;
  final bool initialKnocked;
  final bool initialMessaged;
  final String? initialActiveConversationId;

  const ProfileDetailScreen({
    super.key,
    required this.profileId,
    this.isSelfPreview = false,
    this.initialKnocked = false,
    this.initialMessaged = false,
    this.initialActiveConversationId,
  });

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  static const _reportReasons = [
    'Fake profile',
    'Inappropriate photos',
    'Sexual or offensive messages',
    'Harassment',
    'Scam or asking for money',
    'Dishonest relationship status',
    'Threatening behavior',
    'Other',
  ];

  late bool _knocked;
  late bool _chatRequested;
  String? _activeConversationId;
  bool _isSending = false;
  bool _isLoadingProfile = true;
  bool _isLoadingInteraction = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _details = {};
  Map<String, dynamic> _filters = {};
  List<String> _profileTraits = [];
  List<String> _profileInterests = [];
  final _scrollCtrl = ScrollController();
  final _photoPageCtrl = PageController();
  RealtimeChannel? _photosChannel;
  int _heroPhotoIndex = 0;
  bool _isGalleryCollapsed = true;
  bool _showTopTitle = false;

  @override
  void initState() {
    super.initState();
    _knocked = widget.initialKnocked;
    _chatRequested = widget.initialMessaged;
    _activeConversationId = widget.initialActiveConversationId;
    _isLoadingInteraction =
        !_knocked && !_chatRequested && _activeConversationId == null;
    _profile = widget.isSelfPreview
        ? null
        : _repository.cachedProfile(widget.profileId);
    final cachedDetails = widget.isSelfPreview
        ? null
        : _repository.cachedProfileDetails(widget.profileId);
    if (cachedDetails != null) {
      _profile = cachedDetails.profile;
      _details = cachedDetails.details;
      _filters = cachedDetails.filters;
      _profileTraits = cachedDetails.traits;
      _profileInterests = cachedDetails.interests;
    }
    _isLoadingProfile = _profile == null;
    _loadProfile();
    _subscribeToPhotoChanges();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 220;
      if (show != _showTopTitle) setState(() => _showTopTitle = show);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _photoPageCtrl.dispose();
    final photosChannel = _photosChannel;
    if (photosChannel != null) {
      Supabase.instance.client.removeChannel(photosChannel);
    }
    super.dispose();
  }

  LoverageRepository get _repository =>
      LoverageRepository(Supabase.instance.client);

  String get _displayName => (_profile?['public_name'] as String?) ?? _name;
  int get _displayAge => (_profile?['age'] as num?)?.toInt() ?? _age;
  String get _displayCity {
    final city = _profile?['public_city'] as String?;
    final country = _profile?['public_country_code'] as String?;
    if (city != null && country != null && country.isNotEmpty) {
      return '$city, $country';
    }
    return city ?? country ?? _city;
  }

  bool get _isSelfOwner =>
      widget.isSelfPreview ||
      widget.profileId == Supabase.instance.client.auth.currentUser?.id;

  String get _displayProfession =>
      (_profile?['profession'] as String?) ?? _profession;
  String get _displayBio => (_profile?['bio'] as String?) ?? _bio;
  String get _fallbackProfileImageUrl => _repository.photoUrl(_profile);
  String get _profileImageUrl => _profileImageUrls.first;
  List<Map<String, dynamic>> get _visibleProfilePhotos {
    final photosValue = _profile?['profile_photos'];
    final photos = switch (photosValue) {
      List list =>
        list.whereType<Map>().map(Map<String, dynamic>.from).toList(),
      Map map => [Map<String, dynamic>.from(map)],
      _ => <Map<String, dynamic>>[],
    };
    if (!_isSelfOwner) {
      photos.removeWhere(
        (photo) => photo['moderation_status']?.toString() != 'approved',
      );
    }
    photos.sort((a, b) {
      final primaryA = a['is_primary'] == true ? 0 : 1;
      final primaryB = b['is_primary'] == true ? 0 : 1;
      if (primaryA != primaryB) return primaryA.compareTo(primaryB);
      final sortA = (a['sort_order'] as num?)?.toInt() ?? 999;
      final sortB = (b['sort_order'] as num?)?.toInt() ?? 999;
      return sortA.compareTo(sortB);
    });
    return photos
        .where(
          (photo) => (photo['public_url']?.toString().trim() ?? '').isNotEmpty,
        )
        .toList();
  }

  List<String> get _profileImageUrls {
    final urls = _visibleProfilePhotos
        .map((photo) => photo['public_url']?.toString().trim() ?? '')
        .toList();
    return urls.isEmpty ? [_fallbackProfileImageUrl] : urls;
  }

  String? _photoStatusAt(int index) {
    final photos = _visibleProfilePhotos;
    if (index < 0 || index >= photos.length) return null;
    return photos[index]['moderation_status']?.toString();
  }

  List<String> get _displayTraits => _profileTraits.isNotEmpty
      ? _profileTraits
      : List<String>.from((_profile?['traits'] as List?) ?? _traits);
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
    return 'Member since ${months[joined.month - 1]} ${joined.year}';
  }



  List<_ProfileSectionData> get _profileSections => [
    _ProfileSectionData(
      title: 'Basic Information',
      assetPath: 'Assets/Basic Information.png',
      rows: [
        _InfoRow(
          Icons.favorite_border_rounded,
          'Marital Status',
          _detail('marital_status'),
        ),
        _InfoRow(
          Icons.public_rounded,
          'Nationality',
          _detail('nationality'),
          isCountry: true,
        ),
        _InfoRow(
          Icons.location_on_outlined,
          'Residence',
          _detail('country_of_residence'),
          isCountry: true,
        ),
        _InfoRow(
          Icons.home_outlined,
          'Raised In',
          _detail('raised_in'),
          isCountry: true,
        ),
        _InfoRow(
          Icons.flight_takeoff_rounded,
          'Relocate',
          _boolDetail('willing_to_relocate'),
        ),
        _InfoRow(
          Icons.forum_outlined,
          'Languages',
          _listDetail('languages_spoken', _profile?['languages']),
        ),
      ],
    ),
    _ProfileSectionData(
      title: 'Appearance',
      assetPath: 'Assets/Appearance.png',
      rows: [
        _InfoRow(
          Icons.straighten_rounded,
          'Height',
          _heightLabel(_details['height']),
        ),
        _InfoRow(
          Icons.monitor_weight_outlined,
          'Weight',
          _weightLabel(_details['weight']),
        ),
        _InfoRow(
          Icons.accessibility_new_rounded,
          'Body Type',
          _detail('body_type'),
        ),
        _InfoRow(
          Icons.fitness_center_rounded,
          'Fitness',
          _detail('fitness_level'),
        ),
        _InfoRow(
          Icons.checkroom_outlined,
          'Dress Style',
          _detail('style_of_dress'),
        ),
      ],
    ),
    _ProfileSectionData(
      title: 'Education & Career',
      assetPath: 'Assets/Education & Career.png',
      rows: [
        _InfoRow(
          Icons.school_outlined,
          'Education',
          _detail('education_level', fallback: _profile?['education']),
        ),
        _InfoRow(Icons.menu_book_outlined, 'Field', _detail('field_of_study')),
        _InfoRow(
          Icons.work_outline_rounded,
          'Job Title',
          _detail('job_title', fallback: _profile?['profession']),
        ),
        _InfoRow(
          Icons.badge_outlined,
          'Employment',
          _detail('employment_status'),
        ),
      ],
    ),
    _ProfileSectionData(
      title: 'Personality',
      assetPath: 'Assets/Personality.png',
      rows: [
        _InfoRow(
          Icons.psychology_outlined,
          'Traits',
          _listLabel(_displayTraits),
        ),
      ],
    ),
    _ProfileSectionData(
      title: 'Interests & Lifestyle',
      assetPath: 'Assets/interest and life.png',
      rows: [
        _InfoRow(
          Icons.explore_outlined,
          'Interests',
          _listLabel(_profileInterests),
        ),
        _InfoRow(Icons.smoke_free_rounded, 'Smoking', _detail('smoking')),
        _InfoRow(Icons.local_bar_outlined, 'Drinking', _detail('drinking')),
        _InfoRow(Icons.pets_outlined, 'Pet Lover', _boolDetail('pet_lover')),
      ],
    ),
    _ProfileSectionData(
      title: 'Family & Children',
      assetPath: 'Assets/family.png',
      rows: [
        _InfoRow(
          Icons.family_restroom_outlined,
          'Has Children',
          _detail('children'),
        ),
        _InfoRow(
          Icons.child_care_outlined,
          'Children Count',
          _numberDetail('children_count'),
        ),
        _InfoRow(
          Icons.child_friendly_outlined,
          'Wants Children',
          _boolDetail('wants_children'),
        ),
        _InfoRow(
          Icons.diversity_3_outlined,
          'Family Values',
          _detail('family_values'),
        ),
      ],
    ),
    _ProfileSectionData(
      title: 'Faith & Values',
      assetPath: 'Assets/Faith & Values.png',
      rows: [
        _InfoRow(Icons.mosque_outlined, 'Religion', _profileValue('religion')),
        _InfoRow(
          Icons.auto_awesome_outlined,
          'Religion Level',
          _detail('religion_level'),
        ),
      ],
    ),
    _ProfileSectionData(
      title: 'Partner Expectations',
      assetPath: 'Assets/Partner Expectations.png',
      rows: [
        _InfoRow(
          Icons.favorite_outline_rounded,
          'Ideal Partner',
          _listDetail(
            'preferred_partner_traits',
            _filters['preferred_partner_traits'],
          ),
        ),
        _InfoRow(Icons.calendar_month_outlined, 'Age Range', _ageRangeLabel()),
      ],
    ),
  ].where((section) => section.rows.isNotEmpty).toList();

  String _profileValue(String key) => _clean(_profile?[key]);

  String _detail(String key, {dynamic fallback}) =>
      _clean(_details[key] ?? fallback);

  String _numberDetail(String key) {
    final value = _details[key];
    if (value == null) return '';
    return value.toString();
  }

  String _boolDetail(String key) {
    if (!_details.containsKey(key)) return '';
    return _details[key] == true ? 'Yes' : 'No';
  }

  String _listDetail(String key, dynamic fallback) {
    final value = _details[key] ?? fallback;
    if (value is List) {
      return _listLabel(value.map((e) => e.toString()).toList());
    }
    return _clean(value);
  }

  String _listLabel(List<String> values) {
    final cleaned = values.where((v) => v.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) return '';
    return cleaned.join(', ');
  }

  String _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'not specified') {
      return '';
    }
    return text;
  }

  String _heightLabel(dynamic value) {
    final cm = (value as num?)?.toInt();
    if (cm == null) return '';
    final totalInches = (cm / 2.54).round();
    return '$cm cm · ${totalInches ~/ 12} ft ${totalInches % 12} in';
  }

  String _weightLabel(dynamic value) {
    final kg = (value as num?)?.toInt();
    if (kg == null) return '';
    return '$kg kg · ${(kg * 2.2046226218).round()} lb';
  }

  String _ageRangeLabel() {
    final min = (_filters['min_age'] as num?)?.toInt();
    final max = (_filters['max_age'] as num?)?.toInt();
    if (min == null || max == null) return '';
    return '$min-$max years';
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait<dynamic>([
        _repository.profileDetails(widget.profileId, forceRefresh: true),
        _repository.profileInteractionStatus(widget.profileId),
      ]);
      final data = results[0] as ProfileDetailData;
      final interaction = results[1] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _profile = data.profile;
        _details = data.details;
        _filters = data.filters;
        _profileTraits = data.traits;
        _profileInterests = data.interests;
        // Only upgrade state (false→true), never downgrade (true→false)
        // This prevents flicker when navigating with initial state already set
        if (interaction['knocked'] == true) _knocked = true;
        if (interaction['chat_requested'] == true) _chatRequested = true;
        _activeConversationId ??= interaction['active_conversation_id']
            ?.toString();
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

  void _subscribeToPhotoChanges() {
    _photosChannel = Supabase.instance.client
        .channel('profile_photos_${widget.profileId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profile_photos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: widget.profileId,
          ),
          callback: (_) {
            _repository.invalidateProfile(widget.profileId);
            _loadProfile();
          },
        )
        .subscribe();
  }

  void _preloadAdjacentHeroImages(int index) {
    if (!mounted) return;
    final urls = _profileImageUrls;
    for (final i in [index - 1, index, index + 1]) {
      if (i >= 0 && i < urls.length) {
        final url = urls[i];
        if (url.startsWith('http')) {
          try {
            precacheImage(CachedNetworkImageProvider(url), context);
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _openPhotoViewer(int initialIndex) async {
    final imageUrls = _profileImageUrls;
    if (imageUrls.isEmpty) return;
    final selectedIndex = await showDialog<int>(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => _ProfilePhotoViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex.clamp(0, imageUrls.length - 1).toInt(),
      ),
    );

    if (selectedIndex != null && mounted && selectedIndex != _heroPhotoIndex) {
      setState(() {
        _heroPhotoIndex = selectedIndex;
      });
      if (_photoPageCtrl.hasClients) {
        _photoPageCtrl.jumpToPage(selectedIndex);
      }
    }
  }

  // Fallback profile used only while the real profile loads.
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

  Widget _buildCollapsedStack(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();

    final mainUrl = urls[0];
    final secondUrl = urls.length > 1 ? urls[1] : null;
    final thirdUrl = urls.length > 2 ? urls[2] : null;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isGalleryCollapsed = false;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(28, 64, 28, 28),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Third card (backmost)
            if (thirdUrl != null)
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(12, 12),
                  child: Transform.rotate(
                    angle: 0.04,
                    child: Opacity(
                      opacity: 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: LoverageImage(
                            imageUrl: thirdUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Second card (middle)
            if (secondUrl != null)
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(-8, 6),
                  child: Transform.rotate(
                    angle: -0.03,
                    child: Opacity(
                      opacity: 0.8,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: LoverageImage(
                            imageUrl: secondUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Main card (frontmost)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: LoverageImage(
                    imageUrl: mainUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Tap helper label overlay
            if (urls.length > 1)
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${urls.length} photos · Tap to expand',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authStatusProvider).valueOrNull;
    final isPendingReview = authStatus == AccountStatus.verificationPending;
    final photoUrls = _profileImageUrls;
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
                    background: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isGalleryCollapsed
                          ? _buildCollapsedStack(photoUrls)
                          : Stack(
                              key: const ValueKey('uncollapsed_gallery'),
                              fit: StackFit.expand,
                              children: [
                                PageView.builder(
                                  controller: _photoPageCtrl,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: photoUrls.length,
                                  onPageChanged: (index) {
                                    setState(() => _heroPhotoIndex = index);
                                    _preloadAdjacentHeroImages(index);
                                  },
                                  itemBuilder: (context, index) => GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _openPhotoViewer(index),
                                    child: LoverageImage(
                                      imageUrl: photoUrls[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Gradient overlay (wrapped in IgnorePointer to allow gestures to pass to PageView)
                                IgnorePointer(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [0.4, 1.0],
                                        colors: [Colors.transparent, Color(0xEE000000)],
                                      ),
                                    ),
                                  ),
                                ),
                                if (photoUrls.length > 1)
                                  Positioned(
                                    bottom: 24,
                                    left: 0,
                                    right: 0,
                                    child: IgnorePointer(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(
                                          photoUrls.length,
                                          (index) => AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            width: _heroPhotoIndex == index ? 18 : 6,
                                            height: 6,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _heroPhotoIndex == index
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(0.45),
                                              borderRadius: BorderRadius.circular(99),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_isSelfOwner &&
                                    _photoStatusAt(_heroPhotoIndex) != null)
                                  Positioned(
                                    top: MediaQuery.of(context).padding.top + 48,
                                    right: 16,
                                    child: _PhotoModerationBadge(
                                      status: _photoStatusAt(_heroPhotoIndex)!,
                                    ),
                                  ),
                              ],
                            ),
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

                        // Main Text (Name, Age, Verified status, Location, Profession)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                        color: AppColors.textPrimary,
                                        fontSize: 28,
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
                                      size: 24,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.textMuted,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _displayCity,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_displayProfession.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBurgundy.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.circular,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primaryBurgundy.withOpacity(0.15),
                                        ),
                                      ),
                                      child: Text(
                                        _displayProfession,
                                        style: const TextStyle(
                                          color: AppColors.primaryBurgundy,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_isNewProfile)
                                const _MetaChip(
                                  label: 'New',
                                  backgroundColor: Color(0xFFE8F2FF),
                                  foregroundColor: Color(0xFF2563EB),
                                  borderColor: Color(0xFFBFDBFE),
                                ),
                              _MetaChip(
                                label: _joinedLabel,
                                backgroundColor: const Color(0xFFEAF6F0),
                                foregroundColor: const Color(0xFF28735A),
                                borderColor: const Color(0xFFC7E7D8),
                              ),
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



                        if (_profileSections.isNotEmpty)
                          _Section(
                            title: 'More about $_displayName',
                            child: Column(
                              children: _profileSections
                                  .map(
                                    (section) => _BrandedProfileSection(
                                      section: section,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),

                        SizedBox(
                          height:
                              !widget.isSelfPreview &&
                                  _activeConversationId != null
                              ? 32
                              : 120,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_isLoadingProfile)
              const Positioned.fill(child: _ProfileDetailShimmer()),

            // ── Bottom Action Bar ────────────────────────────────────────────
            if (widget.isSelfPreview || _activeConversationId == null)
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
                                onTap: _chatRequested
                                    ? null
                                    : _openConversation,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                                  color: const Color(
                                                    0xFFF7D5C4,
                                                  ),
                                                ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _chatRequested
                                                ? 'Messaged'
                                                : 'Message',
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _knocked
                                                    ? const Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color: Color(
                                                          0xFFE8B86D,
                                                        ),
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
                                                        ? const Color(
                                                            0xFFFFE8C8,
                                                          )
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

  Future<void> _confirmBlockProfile() async {
    final shouldBlock = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        title: const Text('Block user'),
        content: Text(
          'Block $_displayName? They will not be able to message or interact with you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Block',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldBlock != true || !mounted) return;

    try {
      await _repository.blockProfile(widget.profileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_displayName has been blocked.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not block user: $e')));
    }
  }

  Future<void> _reportProfile() async {
    final reason = await _showReportReasonSheet();
    if (reason == null || !mounted) return;

    try {
      await _repository.reportProfile(
        reportedId: widget.profileId,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent to moderation.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not report profile: $e')));
    }
  }

  Future<String?> _showReportReasonSheet() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Report reason',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            ..._reportReasons.map(
              (reason) => ListTile(
                title: Text(reason),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, reason),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
              onTap: () {
                Navigator.pop(ctx);
                _confirmBlockProfile();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.flag_outlined,
                color: AppColors.warning,
              ),
              title: const Text('Report Profile'),
              onTap: () {
                Navigator.pop(ctx);
                _reportProfile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PhotoModerationBadge extends StatelessWidget {
  final String status;

  const _PhotoModerationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'approved') return const SizedBox.shrink();
    final (label, icon, color) = switch (status) {
      'approved' => (
        'Approved',
        Icons.check_circle_outline_rounded,
        const Color(0xFF34D399),
      ),
      'rejected' => (
        'Rejected',
        Icons.error_outline_rounded,
        const Color(0xFFF87171),
      ),
      _ => ('In Review', Icons.hourglass_top_rounded, const Color(0xFFFBBF24)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePhotoViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ProfilePhotoViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ProfilePhotoViewer> createState() => _ProfilePhotoViewerState();
}

class _ProfilePhotoViewerState extends State<_ProfilePhotoViewer> {
  late final PageController _controller;
  late final Map<int, TransformationController> _transformControllers;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _transformControllers = {
      for (var i = 0; i < widget.imageUrls.length; i++)
        i: TransformationController(),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAdjacentImages(_index);
    });
  }

  void _preloadAdjacentImages(int index) {
    if (!mounted) return;
    for (final i in [index - 1, index, index + 1]) {
      if (i >= 0 && i < widget.imageUrls.length) {
        final url = widget.imageUrls[i];
        if (url.startsWith('http')) {
          try {
            precacheImage(CachedNetworkImageProvider(url), context);
          } catch (_) {}
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final ctrl in _transformControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _handleDoubleTap(int index) {
    final ctrl = _transformControllers[index];
    if (ctrl == null) return;
    if (ctrl.value.isIdentity()) {
      ctrl.value = Matrix4.identity()..scale(2.0, 2.0);
    } else {
      ctrl.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _index = index);
                _preloadAdjacentImages(index);
              },
              itemBuilder: (context, index) {
                final transformCtrl = _transformControllers[index];
                return GestureDetector(
                  onDoubleTap: () => _handleDoubleTap(index),
                  child: InteractiveViewer(
                    transformationController: transformCtrl,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: LoverageImage(
                        imageUrl: widget.imageUrls[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 12,
              right: 14,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(_index),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.42),
                  fixedSize: const Size(44, 44),
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.52),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.imageUrls.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: _index == index ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: _index == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
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
                  child: LoverageImage(
                    imageUrl: widget.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
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

class _BrandedProfileSection extends StatelessWidget {
  final _ProfileSectionData section;

  const _BrandedProfileSection({required this.section});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF2E8E4)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryBurgundy.withOpacity(0.025),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                section.assetPath,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 34,
                  height: 34,
                  color: const Color(0xFFFFF1EC),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryBurgundy,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                section.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        ...section.rows.map((row) => _ProfileSectionLine(row: row)),
      ],
    ),
  );
}

class _ProfileSectionLine extends StatelessWidget {
  final _InfoRow row;

  const _ProfileSectionLine({required this.row});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF4E4DE)),
          ),
          child: Icon(row.icon, size: 14, color: AppColors.primaryBurgundy),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Builder(
                builder: (_) {
                  final flagPath = row.isCountry
                      ? CountryHelper.getFlagAsset(row.value)
                      : null;
                  return Row(
                    children: [
                      if (flagPath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2.5),
                          child: Image.asset(flagPath, width: 18, height: 12, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          row.value,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileSectionData {
  final String title;
  final String assetPath;
  final List<_InfoRow> rows;

  _ProfileSectionData({
    required this.title,
    required this.assetPath,
    required List<_InfoRow> rows,
  }) : rows = rows.where((row) => row.value.trim().isNotEmpty).toList();
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
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const _MetaChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: borderColor),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foregroundColor,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _InfoRow {
  final IconData icon;
  final String label, value;
  final bool isCountry;

  const _InfoRow(
    this.icon,
    this.label,
    this.value, {
    this.isCountry = false,
  });
}
