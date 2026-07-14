import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/loverage_repository.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String profileId;
  const ProfileDetailScreen({super.key, required this.profileId});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool _knocked = false;
  bool _isSending = false;
  bool _isLoadingProfile = true;
  Map<String, dynamic>? _profile;
  final _scrollCtrl = ScrollController();
  bool _showTopTitle = false;

  @override
  void initState() {
    super.initState();
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
  List<_InfoRow> get _displayAbout => [
    _InfoRow(Icons.work_outline_rounded, 'Profession', _displayProfession),
    _InfoRow(
      Icons.school_outlined,
      'Education',
      (_profile?['education'] as String?) ?? 'Not specified',
    ),
    _InfoRow(
      Icons.language_rounded,
      'Languages',
      ((_profile?['languages'] as List?)?.join(', ')) ?? 'Not specified',
    ),
    _InfoRow(
      Icons.mosque_outlined,
      'Religion',
      (_profile?['religion'] as String?) ?? 'Not specified',
    ),
  ];

  Future<void> _loadProfile() async {
    try {
      final row = await _repository.profile(widget.profileId);
      if (!mounted) return;
      setState(() {
        _profile = row;
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
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
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  actions: [
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
                        Image.network(
                          _profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
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
                                  Text(
                                    '$_displayName, $_displayAge',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Color(0xFF60A5FA),
                                    size: 22,
                                  ),
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
                    decoration: const BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

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
                        _Section(
                          title: 'Profile Details',
                          child: Column(
                            children: _displayAbout
                                .map((r) => _InfoTile(row: r))
                                .toList(),
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
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x55FFFFFF),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBurgundy,
                    ),
                  ),
                ),
              ),

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
                child: Row(
                  children: [
                    // Message button
                    Expanded(
                      child: GestureDetector(
                        onTap: _openConversation,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppRadius.circular,
                            ),
                            border: Border.all(
                              color: const Color(0xFFF7D5C4).withOpacity(0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBurgundy.withOpacity(
                                  0.2,
                                ),
                                blurRadius: 12,
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
                                width: 16,
                                height: 16,
                                color: const Color(0xFFF7D5C4),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Message',
                                style: TextStyle(
                                  color: Color(0xFFF7D5C4),
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
                    const SizedBox(width: 14),
                    // Knock button
                    Expanded(
                      flex: 2,
                      child: _isSending
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryBurgundy,
                              ),
                            )
                          : GestureDetector(
                              onTap: _sendKnock,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: _knocked
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.success,
                                            Color(0xFF166534),
                                          ],
                                        )
                                      : AppColors.roseGoldGradient,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.circular,
                                  ),
                                  border: Border.all(
                                    color: _knocked
                                        ? Colors.white.withOpacity(0.2)
                                        : AppColors.primaryBurgundy.withOpacity(
                                            0.1,
                                          ),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _knocked
                                          ? AppColors.success.withOpacity(0.3)
                                          : AppColors.accentRoseGold
                                                .withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
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
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : SvgPicture.asset(
                                            'Assets/knock new .svg',
                                            width: 16,
                                            height: 16,
                                            colorFilter: const ColorFilter.mode(
                                              AppColors.primaryDarkBurgundy,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _knocked ? 'Knock Sent!' : 'Send Knock',
                                      style: TextStyle(
                                        color: _knocked
                                            ? Colors.white
                                            : AppColors.primaryDarkBurgundy,
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
          content: Text('Knock sent to $_displayName'),
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
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send knock: $e')));
    }
  }

  Future<void> _openConversation() async {
    try {
      final conversationId = await _repository.getOrCreateConversation(
        widget.profileId,
      );
      if (mounted) context.push('/chat/$conversationId');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open chat: $e')));
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
