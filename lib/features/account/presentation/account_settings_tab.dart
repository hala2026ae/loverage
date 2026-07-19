import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:typed_data';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';
import '../../../core/data/loverage_repository.dart';
import '../../profiles/presentation/profile_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSettingsTab extends ConsumerStatefulWidget {
  const AccountSettingsTab({super.key});

  @override
  ConsumerState<AccountSettingsTab> createState() => _AccountSettingsTabState();
}

class _AccountSettingsTabState extends ConsumerState<AccountSettingsTab> {
  bool _isSigningOut = false;
  final _scrollCtrl = ScrollController();
  bool _showTitle = false;
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _details = {};
  Map<String, dynamic> _filters = {};
  List<String> _traits = [];
  List<String> _interests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 240;
      if (show != _showTitle) {
        setState(() => _showTitle = show);
      }
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final repository = LoverageRepository(Supabase.instance.client);
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final profile = await repository.myProfile();
      final premiumSubscriptions = await _safeRows(
        () => supabase
            .from('subscriptions')
            .select('id')
            .eq('user_id', userId)
            .eq('status', 'active')
            .eq('entitlement', 'premium')
            .gt('current_period_end', DateTime.now().toUtc().toIso8601String())
            .limit(1),
      );
      final details = await _safeMaybeSingle(
        () => supabase
            .from('profile_optional_details')
            .select()
            .eq('user_id', userId)
            .maybeSingle(),
      );
      final traits = await _safeRows(
        () => supabase
            .from('profile_traits')
            .select('trait')
            .eq('user_id', userId),
      );
      final interests = await _safeRows(
        () => supabase
            .from('profile_interests')
            .select('interest')
            .eq('user_id', userId),
      );
      final filters = await _safeMaybeSingle(
        () => supabase
            .from('user_filters')
            .select()
            .eq('user_id', userId)
            .maybeSingle(),
      );
      if (!mounted) return;
      setState(() {
        _profile = {...?profile, 'is_premium': premiumSubscriptions.isNotEmpty};
        _details = details;
        _traits = _stringList(traits, 'trait');
        _interests = _stringList(interests, 'interest');
        _filters = filters;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load profile: $e')));
    }
  }

  Future<Map<String, dynamic>> _safeMaybeSingle(
    Future<Map<String, dynamic>?> Function() load,
  ) async {
    try {
      return await load() ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<List<dynamic>> _safeRows(Future<List<dynamic>> Function() load) async {
    try {
      return await load();
    } catch (_) {
      return const [];
    }
  }

  List<String> _stringList(dynamic rows, String key) =>
      (rows as List? ?? const [])
          .map((row) => row[key]?.toString())
          .whereType<String>()
          .toList();

  _ProfileCompletion _profileCompletion() {
    final parts = [
      _CompletionPart(
        title: 'Basic Information',
        weight: 15,
        route: 'basic',
        score: _fieldsRatio([
          _details['marital_status'],
          _details['nationality'],
          _details['country_of_residence'],
          _details['raised_in'],
          _details['languages_spoken'],
        ]),
      ),
      _CompletionPart(
        title: 'Appearance',
        weight: 15,
        route: 'appearance',
        score: _fieldsRatio([
          _details['height'],
          _details['body_type'],
          _details['fitness_level'],
          _details['style_of_dress'],
        ]),
      ),
      _CompletionPart(
        title: 'Education & Career',
        weight: 10,
        route: 'education',
        score: _fieldsRatio([
          _details['education_level'],
          _details['field_of_study'],
          _details['job_title'],
          _details['employment_status'],
        ]),
      ),
      _CompletionPart(
        title: 'Personality',
        weight: 15,
        route: 'personality',
        score: (_traits.length / 5).clamp(0, 1).toDouble(),
      ),
      _CompletionPart(
        title: 'Interests & Lifestyle',
        weight: 15,
        route: 'lifestyle',
        score: _average([
          (_interests.length / 5).clamp(0, 1).toDouble(),
          _filled(_details['smoking']) ? 1 : 0,
          _filled(_details['drinking']) ? 1 : 0,
          _details['pet_lover'] == true ? 1 : 0,
        ]),
      ),
      _CompletionPart(
        title: 'Family & Children',
        weight: 10,
        route: 'family',
        score: _fieldsRatio([
          _details['children'],
          _details['wants_children'],
          _details['family_values'],
        ]),
      ),
      _CompletionPart(
        title: 'Faith & Values',
        weight: 10,
        route: 'faith',
        score: _filled(_details['religion_level']) ? 1 : 0,
      ),
      _CompletionPart(
        title: 'Partner Expectations',
        weight: 10,
        route: 'partner',
        score: _average([
          (((_filters['preferred_partner_traits'] as List?)?.length ?? 0) / 3)
              .clamp(0, 1)
              .toDouble(),
          _filled(_filters['min_age']) && _filled(_filters['max_age']) ? 1 : 0,
        ]),
      ),
    ];

    final percent = parts.fold<double>(
      0,
      (sum, part) => sum + (part.weight * part.score),
    );
    final missing = parts.where((part) => part.score < .98).toList()
      ..sort((a, b) {
        final byWeight = b.remainingWeight.compareTo(a.remainingWeight);
        return byWeight == 0 ? a.title.compareTo(b.title) : byWeight;
      });

    return _ProfileCompletion(
      percent: percent.round().clamp(0, 100),
      parts: parts,
      nextPart: missing.isEmpty ? null : missing.first,
    );
  }

  bool _filled(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    return true;
  }

  double _fieldsRatio(List<dynamic> values) {
    if (values.isEmpty) return 0;
    return values.where(_filled).length / values.length;
  }

  double _average(List<num> values) {
    if (values.isEmpty) return 0;
    return values.fold<double>(0, (sum, value) => sum + value.toDouble()) /
        values.length;
  }

  Future<void> _openProfileEditor(String section) async {
    await context.push('/edit-profile/$section');
    if (mounted) _loadProfile();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBurgundy),
        ),
      );
    }
    final name = _profile?['public_name'] as String? ?? 'Loverage Member';
    final isPremium = _profile?['is_premium'] as bool? ?? false;
    final completion = _profileCompletion();
    final completionByRoute = {
      for (final part in completion.parts) part.route: part,
    };

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
              expandedHeight: 430,
              pinned: true,
              backgroundColor: const Color(0xFF5A0E22),
              elevation: 0,
              scrolledUnderElevation: 10,
              shadowColor: const Color(0xFF3D0717).withOpacity(0.28),
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: _ProfileHeader(profile: _profile),
              ),
              title: AnimatedOpacity(
                opacity: _showTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      name,
                      style: AppTheme.sansText(
                        fontSize: 16.0,
                        weight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.9),
                      ).copyWith(letterSpacing: 0.5),
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
                          color: isPremium
                              ? null
                              : Colors.grey.withOpacity(0.6),
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
                  _StatsDashboard(isPremium: isPremium),
                  const SizedBox(height: 20),
                  // Premium Banner
                  _PremiumBanner(onTap: () => context.push('/paywall')),
                  const SizedBox(height: 24),

                  // Account section
                  _SectionHeader(
                    title: 'Account',
                    value: '${completion.percent}%',
                  ),
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: Icons.person_outline_rounded,
                        assetPath: 'Assets/Basic Information.png',
                        label: 'Basic Information',
                        trailing: _CompletionValue(
                          percent: completionByRoute['basic']!.percent,
                        ),
                        onTap: () => _openProfileEditor('basic'),
                      ),
                      _SettingsItem(
                        icon: Icons.auto_awesome_outlined,
                        assetPath: 'Assets/Appearance.png',
                        label: 'Appearance',
                        trailing: _CompletionValue(
                          percent: completionByRoute['appearance']!.percent,
                        ),
                        onTap: () => _openProfileEditor('appearance'),
                      ),
                      _SettingsItem(
                        icon: Icons.school_outlined,
                        assetPath: 'Assets/Education & Career.png',
                        label: 'Education & Career',
                        trailing: _CompletionValue(
                          percent: completionByRoute['education']!.percent,
                        ),
                        onTap: () => _openProfileEditor('education'),
                      ),
                      _SettingsItem(
                        icon: Icons.psychology_outlined,
                        assetPath: 'Assets/Personality.png',
                        label: 'Personality',
                        trailing: _CompletionValue(
                          percent: completionByRoute['personality']!.percent,
                        ),
                        onTap: () => _openProfileEditor('personality'),
                      ),
                      _SettingsItem(
                        icon: Icons.explore_outlined,
                        assetPath: 'Assets/interest and life.png',
                        label: 'Interests & Lifestyle',
                        trailing: _CompletionValue(
                          percent: completionByRoute['lifestyle']!.percent,
                        ),
                        onTap: () => _openProfileEditor('lifestyle'),
                      ),
                      _SettingsItem(
                        icon: Icons.family_restroom_outlined,
                        assetPath: 'Assets/family.png',
                        label: 'Family & Children',
                        trailing: _CompletionValue(
                          percent: completionByRoute['family']!.percent,
                        ),
                        onTap: () => _openProfileEditor('family'),
                      ),
                      _SettingsItem(
                        icon: Icons.auto_awesome_rounded,
                        assetPath: 'Assets/Faith & Values.png',
                        label: 'Faith & Values',
                        trailing: _CompletionValue(
                          percent: completionByRoute['faith']!.percent,
                        ),
                        onTap: () => _openProfileEditor('faith'),
                      ),
                      _SettingsItem(
                        icon: Icons.favorite_border_rounded,
                        assetPath: 'Assets/Partner Expectations.png',
                        label: 'Partner Expectations',
                        trailing: _CompletionValue(
                          percent: completionByRoute['partner']!.percent,
                        ),
                        onTap: () => _openProfileEditor('partner'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Preferences section
                  _SectionHeader(title: 'Preferences'),
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: Icons.notifications_none_rounded,
                        assetPath: 'Assets/Notifications.png',
                        label: 'Notifications',
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Support section
                  _SectionHeader(title: 'Support'),
                  _SettingsGroup(
                    items: [
                      _SettingsItem(
                        icon: Icons.receipt_long_outlined,
                        label: 'Refund Policy',
                        onTap: () => context.push('/refund'),
                      ),
                      _SettingsItem(
                        icon: Icons.article_outlined,
                        assetPath: 'Assets/Terms of service.png',
                        label: 'Terms of Service',
                        onTap: () => context.push('/terms'),
                      ),
                      _SettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        assetPath: 'Assets/Privacy PolICY.png',
                        label: 'Privacy Policy',
                        onTap: () => context.push('/privacy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Sign Out
                  _isSigningOut
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBurgundy,
                          ),
                        )
                      : GestureDetector(
                          onTap: _signOut,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 7),
                                ),
                              ],
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
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.5,
                          decoration: TextDecoration.underline,
                        ),
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
        content: const Text(
          'This will permanently delete your account and all data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
  final Map<String, dynamic>? profile;
  const _ProfileHeader({super.key, required this.profile});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  List<String> _profileImages = [];
  List<Map<String, dynamic>> _profilePhotoRows = [];
  int _mainImageIndex = 0;
  int _selectedImageIndex = 0;
  int _storedPhotoCount = 0;
  final ScrollController _galleryScrollCtrl = ScrollController();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _initPhotos();
  }

  @override
  void didUpdateWidget(covariant _ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _initPhotos();
    }
  }

  void _initPhotos() {
    final photosValue = widget.profile?['profile_photos'];
    final photos = switch (photosValue) {
      final List list => list,
      final Map<String, dynamic> map => [map],
      _ => null,
    };
    if (photos != null && photos.isNotEmpty) {
      _storedPhotoCount = photos.length;
      final sorted = List<Map<String, dynamic>>.from(photos)
        ..sort(
          (a, b) => (a['sort_order'] as num? ?? 0).compareTo(
            b['sort_order'] as num? ?? 0,
          ),
        );
      _profileImages = sorted
          .map((p) => p['public_url'] as String? ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
      _profilePhotoRows = sorted
          .where((p) => (p['public_url'] as String? ?? '').isNotEmpty)
          .toList();

      final primaryIndex = sorted.indexWhere((p) => p['is_primary'] == true);
      _mainImageIndex = primaryIndex >= 0 ? primaryIndex : 0;
      _selectedImageIndex = _mainImageIndex;
    } else {
      _storedPhotoCount = 0;
      _profileImages = [
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      ];
      _profilePhotoRows = const [];
      _mainImageIndex = 0;
      _selectedImageIndex = 0;
    }
  }

  @override
  void dispose() {
    _galleryScrollCtrl.dispose();
    super.dispose();
  }

  Future<_PickedProfilePhoto?> _pickProfilePhoto() async {
    final source = await showModalBottomSheet<_ProfilePhotoSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ProfilePhotoSourceSheet(),
    );
    if (source == null || !mounted) return null;

    try {
      switch (source) {
        case _ProfilePhotoSource.gallery:
          final file = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 90,
            maxWidth: 2200,
          );
          if (file == null) return null;
          return _cropProfilePhoto(file.path, file.name);
        case _ProfilePhotoSource.camera:
          final file = await ImagePicker().pickImage(
            source: ImageSource.camera,
            imageQuality: 90,
            maxWidth: 2200,
          );
          if (file == null) return null;
          return _cropProfilePhoto(file.path, file.name);
        case _ProfilePhotoSource.files:
          const imageTypes = XTypeGroup(
            label: 'Images',
            extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
            uniformTypeIdentifiers: [
              'public.jpeg',
              'public.png',
              'org.webmproject.webp',
              'public.heic',
            ],
          );
          final file = await openFile(acceptedTypeGroups: [imageTypes]);
          if (file == null) return null;
          return _cropProfilePhoto(file.path, file.name);
      }
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not select photo: $e')));
    }
    return null;
  }

  Future<_PickedProfilePhoto?> _cropProfilePhoto(
    String path,
    String fileName,
  ) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo to Square',
          toolbarColor: const Color(0xFF5E0B24),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo to Square',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );
    final finalPath = croppedFile?.path ?? path;
    final croppedBytes = await XFile(finalPath).readAsBytes();
    return _PickedProfilePhoto(croppedBytes, fileName);
  }

  Future<void> _showPhotoSourceSheet() async {
    final photo = await _pickProfilePhoto();
    if (photo == null || !mounted) return;
    await _uploadProfilePhoto(photo.bytes, photo.fileName);
  }

  Future<void> _uploadProfilePhoto(Uint8List bytes, String fileName) async {
    if (_isUploadingPhoto) return;
    setState(() => _isUploadingPhoto = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final extension = _imageExtension(fileName);
      final objectPath =
          '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';
      final isFirstPhoto = _storedPhotoCount == 0;

      await supabase.storage
          .from('profile-photos')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: _imageContentType(extension),
              upsert: false,
            ),
          );
      final publicUrl = supabase.storage
          .from('profile-photos')
          .getPublicUrl(objectPath);
      final inserted = await supabase
          .from('profile_photos')
          .insert({
            'user_id': userId,
            'public_url': publicUrl,
            'is_primary': isFirstPhoto,
            'sort_order': _storedPhotoCount,
            'moderation_status': 'pending',
          })
          .select('id')
          .single();

      if (isFirstPhoto) {
        await supabase
            .from('profiles')
            .update({'main_photo_id': inserted['id']})
            .eq('id', userId);
      }

      if (!mounted) return;
      setState(() {
        _storedPhotoCount += 1;
        final row = {
          'id': inserted['id'],
          'public_url': publicUrl,
          'is_primary': isFirstPhoto,
          'sort_order': _storedPhotoCount - 1,
        };
        if (isFirstPhoto) {
          _profileImages = [publicUrl];
          _profilePhotoRows = [row];
          _mainImageIndex = 0;
          _selectedImageIndex = 0;
        } else {
          _profileImages.add(publicUrl);
          _profilePhotoRows.add(row);
          _selectedImageIndex = _profileImages.length - 1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded and sent for review.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not upload photo: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  String _imageExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extension)
        ? extension
        : 'jpg';
  }

  String _imageContentType(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => 'image/jpeg',
  };

  Future<void> _showImageManagementSheet(int index) async {
    if (index < 0 || index >= _profileImages.length) return;
    setState(() => _selectedImageIndex = index);
    final isMain = index == _mainImageIndex;
    final action = await showModalBottomSheet<_ProfilePhotoAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ProfilePhotoActionSheet(canDelete: !isMain, canSetAsMain: !isMain),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ProfilePhotoAction.add:
        await _showPhotoSourceSheet();
        break;
      case _ProfilePhotoAction.replace:
        await _replaceProfilePhoto(index);
        break;
      case _ProfilePhotoAction.setAsMain:
        await _setAsMainPhoto(index);
        break;
      case _ProfilePhotoAction.preview:
        _showProfilePreview();
        break;
      case _ProfilePhotoAction.delete:
        await _deleteProfilePhoto(index);
        break;
    }
  }

  Future<void> _setAsMainPhoto(int index) async {
    if (index == _mainImageIndex || index >= _profilePhotoRows.length) return;
    final photoId = _profilePhotoRows[index]['id'];
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (photoId == null || userId == null) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('profile_photos')
          .update({'is_primary': false})
          .eq('user_id', userId);
      await supabase
          .from('profile_photos')
          .update({'is_primary': true})
          .eq('id', photoId);
      await supabase
          .from('profiles')
          .update({'main_photo_id': photoId})
          .eq('id', userId);
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _profilePhotoRows.length; i++) {
          _profilePhotoRows[i] = {
            ..._profilePhotoRows[i],
            'is_primary': i == index,
          };
        }
        _mainImageIndex = index;
        _selectedImageIndex = index;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Main photo updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update main photo: $e')),
      );
    }
  }

  Future<void> _replaceProfilePhoto(int index) async {
    if (index >= _profilePhotoRows.length) return;
    final photo = await _pickProfilePhoto();
    if (photo == null || !mounted) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final extension = _imageExtension(photo.fileName);
      final objectPath =
          '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';
      await supabase.storage
          .from('profile-photos')
          .uploadBinary(
            objectPath,
            photo.bytes,
            fileOptions: FileOptions(
              contentType: _imageContentType(extension),
              upsert: false,
            ),
          );
      final publicUrl = supabase.storage
          .from('profile-photos')
          .getPublicUrl(objectPath);
      await supabase
          .from('profile_photos')
          .update({'public_url': publicUrl, 'moderation_status': 'pending'})
          .eq('id', _profilePhotoRows[index]['id']);
      if (!mounted) return;
      setState(() {
        _profileImages[index] = publicUrl;
        _profilePhotoRows[index] = {
          ..._profilePhotoRows[index],
          'public_url': publicUrl,
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo replaced and sent for review.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not replace photo: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _deleteProfilePhoto(int index) async {
    if (index == _mainImageIndex || index >= _profilePhotoRows.length) return;
    try {
      await Supabase.instance.client
          .from('profile_photos')
          .delete()
          .eq('id', _profilePhotoRows[index]['id']);
      if (!mounted) return;
      setState(() {
        _profileImages.removeAt(index);
        _profilePhotoRows.removeAt(index);
        _storedPhotoCount = _profilePhotoRows.length;
        if (_selectedImageIndex >= _profileImages.length) {
          _selectedImageIndex = _profileImages.length - 1;
        }
        if (index < _mainImageIndex) _mainImageIndex -= 1;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Photo deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete photo: $e')));
    }
  }

  void _showProfilePreview() {
    final profile = widget.profile;
    if (profile == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ProfilePreviewSheet(
        profile: profile,
        imageUrl: _profileImages[_mainImageIndex],
        onViewDetails: userId == null
            ? null
            : () => _showFullProfilePreview(sheetContext, userId),
      ),
    );
  }

  Future<void> _showFullProfilePreview(
    BuildContext previewContext,
    String userId,
  ) async {
    Navigator.of(previewContext).pop();
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.48),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: ProfileDetailScreen(profileId: userId, isSelfPreview: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final name = p?['public_name'] as String? ?? 'Loverage Member';
    final isPremium = p?['is_premium'] as bool? ?? false;
    final city = p?['public_city'] as String?;
    final country = p?['public_country_code'] as String?;
    final location = (city != null && country != null)
        ? '$city, $country'
        : (city ?? country ?? 'Toronto, Canada');
    final verified = p?['verification_status'] == 'approved';
    final pending = p?['verification_status'] == 'pending';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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
                  name,
                  style: AppTheme.sansText(
                    fontSize: 16.0,
                    weight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.9),
                  ).copyWith(letterSpacing: 0.5),
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
                      color: isPremium ? null : Colors.grey.withOpacity(0.6),
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
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFD4956A),
                    size: 10,
                  ),
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
              height: 156,
              child: SingleChildScrollView(
                controller: _galleryScrollCtrl,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ...List.generate(_profileImages.length, (index) {
                      final isSelected = _selectedImageIndex == index;
                      final isMain = _mainImageIndex == index;
                      final imageUrl = _profileImages[index];

                      return GestureDetector(
                        onTap: () => _showImageManagementSheet(index),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: 1.0,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            scale: 1.0,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                width: isSelected ? 140 : 84,
                                height: isSelected ? 140 : 84,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        isSelected ? 9 : 5,
                                        isSelected ? 10 : 6,
                                        isSelected ? 9 : 5,
                                        isSelected ? 10 : 6,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          isSelected ? 18 : 11,
                                        ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                            ),
                                            if (!isSelected)
                                              Container(
                                                color: Colors.black.withOpacity(
                                                  0.28,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!isMain)
                                      Image.asset(
                                        'Assets/26 FRAME (1) (2).png',
                                        fit: BoxFit.fill,
                                      ),
                                    if (isMain)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: isSelected ? 12 : 7,
                                        child: const Text(
                                          'Main',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black87,
                                                blurRadius: 4,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_profileImages.length < 6)
                      GestureDetector(
                        onTap: _showPhotoSourceSheet,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 34),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  left: -8,
                  top: -12,
                  child: Transform.rotate(
                    angle: -0.7853, // -45 degrees
                    child: Image.asset(
                      'Assets/Gold mem.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      color: isPremium ? null : Colors.grey.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFFD4956A),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
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
                border: Border.all(
                  color: verified
                      ? const Color(0xFFD4956A)
                      : pending
                      ? const Color(0xFFD4AF37)
                      : Colors.grey,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (verified)
                    Image.asset(
                      'Assets/Verfied (1).png',
                      width: 17,
                      height: 17,
                      fit: BoxFit.contain,
                    )
                  else
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: pending ? const Color(0xFFD4AF37) : Colors.grey,
                      size: 14,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    verified
                        ? 'Verified'
                        : pending
                        ? 'Pending Review'
                        : 'Unverified',
                    style: const TextStyle(
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
enum _ProfilePhotoSource { gallery, camera, files }

enum _ProfilePhotoAction { add, replace, setAsMain, preview, delete }

class _PickedProfilePhoto {
  final Uint8List bytes;
  final String fileName;

  const _PickedProfilePhoto(this.bytes, this.fileName);
}

class _ProfilePhotoActionSheet extends StatelessWidget {
  final bool canDelete;
  final bool canSetAsMain;

  const _ProfilePhotoActionSheet({
    required this.canDelete,
    required this.canSetAsMain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD8CFD1),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          _PhotoSourceTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Replace Image',
            onTap: () => Navigator.pop(context, _ProfilePhotoAction.replace),
          ),
          if (canSetAsMain)
            _PhotoSourceTile(
              icon: Icons.star_rounded,
              title: 'Set as Main',
              onTap: () =>
                  Navigator.pop(context, _ProfilePhotoAction.setAsMain),
            ),
          _PhotoSourceTile(
            icon: Icons.visibility_outlined,
            title: 'See Profile',
            onTap: () => Navigator.pop(context, _ProfilePhotoAction.preview),
          ),
          if (canDelete)
            _PhotoSourceTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Image',
              onTap: () => Navigator.pop(context, _ProfilePhotoAction.delete),
            ),
        ],
      ),
    );
  }
}

class _ProfilePhotoSourceSheet extends StatelessWidget {
  const _ProfilePhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD8CFD1),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Add a profile photo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _PhotoSourceTile(
            icon: Icons.photo_library_outlined,
            title: 'Choose from Gallery',
            onTap: () => Navigator.pop(context, _ProfilePhotoSource.gallery),
          ),
          _PhotoSourceTile(
            icon: Icons.photo_camera_outlined,
            title: 'Take a Picture',
            onTap: () => Navigator.pop(context, _ProfilePhotoSource.camera),
          ),
          _PhotoSourceTile(
            icon: Icons.folder_open_outlined,
            title: 'Choose from Files',
            onTap: () => Navigator.pop(context, _ProfilePhotoSource.files),
          ),
        ],
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PhotoSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 2),
    onTap: onTap,
    leading: Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: AppColors.textMuted,
    ),
  );
}

class _ProfilePreviewSheet extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String imageUrl;
  final VoidCallback? onViewDetails;

  const _ProfilePreviewSheet({
    required this.profile,
    required this.imageUrl,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile['public_name'] as String? ?? 'Loverage Member';
    final age = profile['age'];
    final city = profile['public_city'] as String?;
    final country = profile['public_country_code'] as String?;
    final location = [
      city,
      country,
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
    final profession = profile['profession'] as String?;
    final verified = profile['verification_status'] == 'approved';
    final premium = profile['is_premium'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F5F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD8CFD1),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                color: AppColors.primaryBurgundy,
                size: 21,
              ),
              const SizedBox(width: 9),
              const Text(
                'Profile Preview',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close preview',
              ),
            ],
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: AspectRatio(
              aspectRatio: 0.74,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.cardCream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5D8D4)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34121D).withOpacity(0.20),
                      blurRadius: 30,
                      spreadRadius: -7,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 72,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.42, 0.72, 1],
                          colors: [
                            Colors.transparent,
                            Color(0x55000000),
                            Color(0xE6000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (premium) ...[
                                Image.asset(
                                  'Assets/Gold mem.png',
                                  width: 22,
                                  height: 22,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  age == null ? name : '$name, $age',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (verified)
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF72AFFF),
                                  size: 20,
                                ),
                            ],
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFFF2C4A0),
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (profession != null && profession.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              profession,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onViewDetails,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBurgundy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 19),
              label: const Text(
                'View Full Profile',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCompletion {
  final int percent;
  final List<_CompletionPart> parts;
  final _CompletionPart? nextPart;

  const _ProfileCompletion({
    required this.percent,
    required this.parts,
    required this.nextPart,
  });
}

class _CompletionPart {
  final String title, route;
  final int weight;
  final double score;

  const _CompletionPart({
    required this.title,
    required this.route,
    required this.weight,
    required this.score,
  });

  double get remainingWeight => weight * (1 - score);
  int get percent => (score * 100).round().clamp(0, 100);
}

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
              color: const Color(0xFF3D0717).withOpacity(0.24),
              blurRadius: 26,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: const Color(0xFFE8B86D).withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFE8B86D),
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? value;
  const _SectionHeader({required this.title, this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        if (value != null) ...[
          const Spacer(),
          Text(
            value!,
            style: const TextStyle(
              color: AppColors.primaryBurgundy,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    ),
  );
}

class _CompletionValue extends StatelessWidget {
  final int percent;

  const _CompletionValue({required this.percent});

  @override
  Widget build(BuildContext context) {
    final complete = percent == 100;
    final color = complete
        ? const Color(0xFF3F8A55)
        : AppColors.primaryBurgundy;

    return SizedBox(
      width: 68,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              width: 28,
              height: 3,
              child: LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: const Color(0xFFEDE5E7),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 33,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: complete ? color : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: const Color(0xFFE9DFDC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34121D).withOpacity(0.09),
            blurRadius: 28,
            spreadRadius: -7,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF6B0F2A).withOpacity(0.045),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: e.value.onTap,
                borderRadius: BorderRadius.circular(AppRadius.l),
                splashColor: AppColors.primaryBurgundy.withOpacity(0.07),
                highlightColor: AppColors.primaryBurgundy.withOpacity(0.035),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      _SettingsLeading(item: e.value),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          e.value.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (e.value.trailing != null) ...[
                        e.value.trailing!,
                        const SizedBox(width: 8),
                      ],
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
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
  final String? assetPath;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _SettingsItem({
    required this.icon,
    this.assetPath,
    required this.label,
    required this.onTap,
    this.trailing,
  });
}

class _SettingsLeading extends StatelessWidget {
  final _SettingsItem item;

  const _SettingsLeading({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.assetPath != null) {
      return SizedBox(
        width: 46,
        height: 46,
        child: Image.asset(item.assetPath!, fit: BoxFit.contain),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primaryBurgundy.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(item.icon, size: 18, color: AppColors.primaryBurgundy),
    );
  }
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
  final bool isPremium;

  const _StatsDashboard({required this.isPremium});

  @override
  State<_StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<_StatsDashboard>
    with WidgetsBindingObserver {
  static const _knockLimit = 20;
  static const _chatLimit = 5;

  Timer? _limitResetTimer;
  RealtimeChannel? _usageChannel;
  Duration _timeUntilReset = Duration.zero;
  int _knocksUsed = 0;
  int _chatsUsed = 0;
  bool _loadingUsage = true;
  int _lastUsageVersion = 0;
  late String _usageDay;

  String get _currentUsageDay {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  void _calculateTimeUntilReset() {
    final now = DateTime.now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
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
    WidgetsBinding.instance.addObserver(this);
    _usageDay = _currentUsageDay;
    _calculateTimeUntilReset();
    _loadUsage();
    _subscribeToUsage();
    LoverageRepository.dailyUsageChanged.addListener(_handleUsageChange);
    _limitResetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final newDay = _currentUsageDay;
        if (newDay != _usageDay) {
          _usageDay = newDay;
          _lastUsageVersion += 1;
          _knocksUsed = 0;
          _chatsUsed = 0;
          _loadUsage(version: _lastUsageVersion);
        }
        setState(() {
          _calculateTimeUntilReset();
        });
      }
    });
  }

  void _handleUsageChange() {
    final change = LoverageRepository.dailyUsageChanged.value;
    if (change == null) return;
    _lastUsageVersion += 1;
    if (mounted) {
      setState(() {
        if (change.action == DailyUsageAction.knock) {
          _knocksUsed = change.used.clamp(0, _knockLimit);
        } else {
          _chatsUsed = change.used.clamp(0, _chatLimit);
        }
        _loadingUsage = false;
      });
    }
  }

  void _subscribeToUsage() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    _usageChannel = supabase
        .channel('daily_usage_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_usage',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty &&
                record['usage_date']?.toString() != _currentUsageDay) {
              return;
            }
            _lastUsageVersion += 1;
            _loadUsage(version: _lastUsageVersion);
          },
        )
        .subscribe();
  }

  Future<void> _loadUsage({int? version}) async {
    final requestVersion = version ?? _lastUsageVersion;
    try {
      final usage = await LoverageRepository(
        Supabase.instance.client,
      ).dailyUsage();
      if (!mounted) return;
      if (requestVersion != _lastUsageVersion) return;
      setState(() {
        _knocksUsed = (usage['knocks_sent'] ?? 0).clamp(0, _knockLimit);
        _chatsUsed = (usage['chat_requests_sent'] ?? 0).clamp(0, _chatLimit);
        _loadingUsage = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingUsage = false);
    }
  }

  @override
  void dispose() {
    _limitResetTimer?.cancel();
    final usageChannel = _usageChannel;
    if (usageChannel != null) {
      Supabase.instance.client.removeChannel(usageChannel);
    }
    WidgetsBinding.instance.removeObserver(this);
    LoverageRepository.dailyUsageChanged.removeListener(_handleUsageChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lastUsageVersion += 1;
      _loadUsage(version: _lastUsageVersion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final knocksLeft = (_knockLimit - _knocksUsed).clamp(0, _knockLimit);
    final chatsLeft = (_chatLimit - _chatsUsed).clamp(0, _chatLimit);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFAF8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DCD8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34121D).withOpacity(0.12),
            blurRadius: 32,
            spreadRadius: -10,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B1234), Color(0xFF520B20)],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B0F2A).withOpacity(0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  'Assets/MESSAGES LIMIT NEW.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Knocks & Chats',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1219),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF2D7DC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.primaryBurgundy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(_timeUntilReset),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBurgundy,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(height: 1, color: const Color(0xFFF0E7E4)),
          const SizedBox(height: 17),
          if (widget.isPremium)
            const _PremiumUsageState()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _UsageMetric(
                    label: 'Knocks',
                    left: knocksLeft,
                    total: _knockLimit,
                    loading: _loadingUsage,
                    color: AppColors.primaryBurgundy,
                    trackColor: Color(0xFFF3E4E8),
                    icon: SvgPicture.asset(
                      'Assets/knock new .svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primaryBurgundy,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 112,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  color: const Color(0xFFF0E7E4),
                ),
                Expanded(
                  child: _UsageMetric(
                    label: 'Chats',
                    left: chatsLeft,
                    total: _chatLimit,
                    loading: _loadingUsage,
                    color: const Color(0xFFC38218),
                    trackColor: const Color(0xFFF7EBD8),
                    icon: Image.asset(
                      'Assets/Messages.png',
                      width: 16,
                      height: 16,
                      color: const Color(0xFFC38218),
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

class _UsageMetric extends StatelessWidget {
  final String label;
  final int left;
  final int total;
  final bool loading;
  final Color color;
  final Color trackColor;
  final Widget icon;

  const _UsageMetric({
    required this.label,
    required this.left,
    required this.total,
    required this.loading,
    required this.color,
    required this.trackColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : left / total;
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: trackColor,
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
            const SizedBox(width: 8),
            Text(
              '$label left',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (loading)
          SizedBox(
            height: 31,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
            ),
          )
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$left',
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: '  / $total',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: loading ? 0 : progress),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          loading ? 'Loading usage' : '$percent% available',
          style: TextStyle(
            color: loading ? AppColors.textMuted : color,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PremiumUsageState extends StatelessWidget {
  const _PremiumUsageState();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEBD29B)),
    ),
    child: Row(
      children: [
        Image.asset('Assets/Gold mem.png', width: 30, height: 30),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlimited daily actions',
                style: TextStyle(
                  color: Color(0xFF5A3510),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your Premium membership has no daily limits.',
                style: TextStyle(color: Color(0xFF8A6843), fontSize: 10.5),
              ),
            ],
          ),
        ),
        Icon(Icons.all_inclusive_rounded, color: Color(0xFFC38218), size: 24),
      ],
    ),
  );
}
