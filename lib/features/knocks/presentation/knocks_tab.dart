import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/data/loverage_repository.dart';

class KnocksTab extends ConsumerStatefulWidget {
  const KnocksTab({super.key});

  @override
  ConsumerState<KnocksTab> createState() => _KnocksTabState();
}

class _KnocksTabState extends ConsumerState<KnocksTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _isLoading = false;
  List<_Knock> _incoming = [];
  List<_Knock> _sent = [];
  LoverageRepository get _repository =>
      LoverageRepository(Supabase.instance.client);

  Future<void> _loadKnocks() async {
    setState(() => _isLoading = true);
    try {
      final incomingRows = await _repository.incomingKnocks();
      final sentRows = await _repository.sentKnocks();
      if (!mounted) return;
      setState(() {
        _incoming = incomingRows
            .map((row) => _knockFromRow(row, 'sender'))
            .toList();
        _sent = sentRows.map((row) => _knockFromRow(row, 'receiver')).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load knocks: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _loadKnocks();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: Text(
          'Knocks',
          style: AppTheme.sansText(
            fontSize: 16.0,
            weight: FontWeight.w300,
            color: Colors.white.withOpacity(0.9),
          ).copyWith(letterSpacing: 0.5),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('Assets/home background .png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBurgundy,
                ),
              )
            : Column(
                children: [
                  // Modern Pill Selector for tab states
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ), // Sleeker width and margin
                    padding: const EdgeInsets.all(3), // More compact padding
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EAE6), // soft warm cream-grey
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabCtrl.animateTo(0),
                            child: Container(
                              height: 30, // Smaller compact height
                              decoration: BoxDecoration(
                                gradient: _tabCtrl.index == 0
                                    ? AppColors.roseGoldGradient
                                    : null,
                                color: _tabCtrl.index == 0
                                    ? null
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.circular,
                                ),
                                boxShadow: _tabCtrl.index == 0
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accentRoseGold
                                              .withOpacity(0.20),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Received',
                                    style: TextStyle(
                                      color: _tabCtrl.index == 0
                                          ? AppColors.primaryDarkBurgundy
                                          : AppColors.textSecondary,
                                      fontWeight: _tabCtrl.index == 0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 12.5, // Sleeker font size
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _tabCtrl.index == 0
                                          ? AppColors.primaryBurgundy
                                          : const Color(
                                              0xFFD4C8C2,
                                            ), // Distinct active/inactive badge colors
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _incoming.length.toString(),
                                      style: TextStyle(
                                        color: _tabCtrl.index == 0
                                            ? Colors.white
                                            : const Color(0xFF7E726C),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabCtrl.animateTo(1),
                            child: Container(
                              height: 30, // Smaller compact height
                              decoration: BoxDecoration(
                                gradient: _tabCtrl.index == 1
                                    ? AppColors.roseGoldGradient
                                    : null,
                                color: _tabCtrl.index == 1
                                    ? null
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.circular,
                                ),
                                boxShadow: _tabCtrl.index == 1
                                    ? [
                                        BoxShadow(
                                          color: AppColors.accentRoseGold
                                              .withOpacity(0.20),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sent',
                                    style: TextStyle(
                                      color: _tabCtrl.index == 1
                                          ? AppColors.primaryDarkBurgundy
                                          : AppColors.textSecondary,
                                      fontWeight: _tabCtrl.index == 1
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 12.5, // Sleeker font size
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _tabCtrl.index == 1
                                          ? AppColors.primaryBurgundy
                                          : const Color(
                                              0xFFD4C8C2,
                                            ), // Distinct active/inactive badge colors
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _sent.length.toString(),
                                      style: TextStyle(
                                        color: _tabCtrl.index == 1
                                            ? Colors.white
                                            : const Color(0xFF7E726C),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
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
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _KnockList(
                          knocks: _incoming,
                          showActions: true,
                          onAccept: _accept,
                          onDecline: _decline,
                        ),
                        _KnockList(
                          knocks: _sent,
                          showActions: false,
                          onAccept: (_) {},
                          onDecline: (_) {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _accept(_Knock k) async {
    try {
      final conversationId = await _repository.acceptKnock(k.id);
      if (!mounted) return;
      setState(() => _incoming.removeWhere((x) => x.id == k.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You accepted ${k.name}\'s knock. Say hello.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.push('/chat/$conversationId');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not accept knock: $e')));
    }
  }

  Future<void> _decline(_Knock k) async {
    try {
      await _repository.declineKnock(k.id);
      if (mounted) setState(() => _incoming.removeWhere((x) => x.id == k.id));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not decline knock: $e')));
    }
  }
}

_Knock _knockFromRow(Map<String, dynamic> row, String profileKey) {
  final profile = row[profileKey] as Map<String, dynamic>? ?? const {};
  final repo = LoverageRepository(Supabase.instance.client);
  return _Knock(
    id: row['id'].toString(),
    name: (profile['public_name'] as String?) ?? 'Loverage member',
    age: (profile['age'] as num?)?.toInt() ?? 0,
    city:
        (profile['public_city'] as String?) ??
        (profile['public_country_code'] as String?) ??
        'Nearby',
    imageUrl: repo.photoUrl(profile),
    time: _timeAgo(DateTime.tryParse((row['created_at'] ?? '').toString())),
    isNew:
        DateTime.tryParse(
          (row['created_at'] ?? '').toString(),
        )?.isAfter(DateTime.now().subtract(const Duration(days: 1))) ??
        false,
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

class _KnockList extends StatelessWidget {
  final List<_Knock> knocks;
  final bool showActions;
  final void Function(_Knock) onAccept;
  final void Function(_Knock) onDecline;

  const _KnockList({
    required this.knocks,
    required this.showActions,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (knocks.isEmpty) {
      return Center(
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
                Icons.favorite_border_rounded,
                size: 40,
                color: AppColors.primaryBurgundy,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No knocks yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When someone knocks, they\'ll appear here',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: knocks.length,
      itemBuilder: (_, i) => _KnockGridCard(
        knock: knocks[i],
        showActions: showActions,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }
}

class _KnockGridCard extends StatefulWidget {
  final _Knock knock;
  final bool showActions;
  final void Function(_Knock) onAccept;
  final void Function(_Knock) onDecline;

  const _KnockGridCard({
    required this.knock,
    required this.showActions,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_KnockGridCard> createState() => _KnockGridCardState();
}

class _KnockGridCardState extends State<_KnockGridCard> {
  bool _isProcessed = false;

  void _handleAccept() {
    setState(() => _isProcessed = true);
    widget.onAccept(widget.knock);
  }

  void _handleDecline() {
    setState(() => _isProcessed = true);
    widget.onDecline(widget.knock);
  }

  String _getCountryFlag(String city) {
    final c = city.toLowerCase();
    if (c.contains('abu dhabi') || c.contains('dubai')) return '🇦🇪';
    if (c.contains('cairo')) return '🇪🇬';
    if (c.contains('istanbul')) return '🇹🇷';
    if (c.contains('london')) return '🇬🇧';
    return '🏳️';
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessed) return const SizedBox.shrink();
    final k = widget.knock;

    return Container(
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
        border: Border.all(
          color: k.isNew
              ? AppColors.primaryBurgundy.withOpacity(0.3)
              : AppColors.borderLight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo background occupying full bleed
            Image.network(
              k.imageUrl,
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

            // Gradient vignette overlay for readability
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(
                  _getCountryFlag(k.city),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),

            // Time indicator on top right corner
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(
                  k.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Overlaid Information & Action Buttons
            Positioned(
              bottom: 12,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Age Row
                  Text(
                    '${k.name}, ${k.age}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
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
                  const SizedBox(height: 4),

                  // Modern Translucent Capsule for City/Country
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          k.city,
                          style: const TextStyle(
                            color: Color(0xFFF7F7F7),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (widget.showActions) ...[
                    // Floating action row: Decline (X) and Accept
                    Row(
                      children: [
                        // Decline circular button (X)
                        GestureDetector(
                          onTap: _handleDecline,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Accept stadium pill
                        Expanded(
                          child: GestureDetector(
                            onTap: _handleAccept,
                            child: Container(
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: AppColors.premiumBurgundyGradient,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.circular,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFD4956A),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
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
                                  Image.asset(
                                    'Assets/accept.png',
                                    width: 14,
                                    height: 14,
                                    color: const Color(0xFFF7D5C4),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Accept',
                                    style: TextStyle(
                                      color: Color(0xFFF7D5C4),
                                      fontSize: 12.0,
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
                  ] else ...[
                    // Just status tag for sent knocks
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBurgundy.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryBurgundy.withOpacity(0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Sent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Knock {
  final String id, name, city, imageUrl, time;
  final int age;
  final bool isNew;
  const _Knock({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.imageUrl,
    required this.time,
    required this.isNew,
  });
}
