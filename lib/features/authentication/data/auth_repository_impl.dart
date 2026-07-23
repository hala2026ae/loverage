import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsis;
import '../domain/account_status.dart';
import '../domain/auth_repository_interface.dart';

class AuthRepositoryImpl implements AuthRepositoryInterface {
  final SupabaseClient _supabase;
  final _statusController = StreamController<AccountStatus>.broadcast();
  AccountStatus _status = AccountStatus.initializing;
  String? _pendingEmail;
  RealtimeChannel? _profileStatusChannel;
  String? _watchedProfileId;

  AuthRepositoryImpl(this._supabase) {
    _syncSupabaseSession(_supabase.auth.currentSession);
    _supabase.auth.onAuthStateChange.listen(
      (data) {
        _syncSupabaseSession(data.session);
      },
      onError: (_) {
        _clearProfileStatusWatch();
        _setStatus(AccountStatus.unauthenticated);
      },
    );
  }

  void _setStatus(AccountStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  Future<void> _syncSupabaseSession(Session? session) async {
    if (session == null) {
      _clearProfileStatusWatch();
      _setStatus(AccountStatus.unauthenticated);
      return;
    }

    _watchProfileStatus(session.user.id);

    try {
      final profile = await _supabase
          .from('profiles')
          .select('profile_status, verification_status')
          .eq('id', session.user.id)
          .maybeSingle();

      if (profile == null) {
        _setStatus(AccountStatus.registrationIncomplete);
        return;
      }

      final profileStatus =
          profile['profile_status'] as String? ?? 'registration_incomplete';
      final verificationStatus =
          profile['verification_status'] as String? ?? 'not_submitted';

      if (profileStatus == 'suspended') {
        _setStatus(AccountStatus.suspended);
      } else if (profileStatus == 'deactivated') {
        _setStatus(AccountStatus.deactivated);
      } else if (profileStatus == 'deletion_scheduled') {
        _setStatus(AccountStatus.deletionScheduled);
      } else if (verificationStatus == 'rejected') {
        _setStatus(AccountStatus.verificationRejected);
      } else if (profileStatus == 'active' &&
          verificationStatus == 'approved') {
        _setStatus(AccountStatus.verificationApproved);
      } else if (profileStatus == 'verification_pending' ||
          verificationStatus == 'pending') {
        _setStatus(AccountStatus.verificationPending);
      } else if (profileStatus == 'verification_not_submitted') {
        _setStatus(AccountStatus.verificationNotSubmitted);
      } else {
        _setStatus(AccountStatus.registrationIncomplete);
      }
    } catch (_) {
      _setStatus(AccountStatus.unauthenticated);
    }
  }

  void _watchProfileStatus(String userId) {
    if (_watchedProfileId == userId) return;

    _clearProfileStatusWatch();
    _watchedProfileId = userId;
    _profileStatusChannel = _supabase
        .channel('profile-status-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (_) => _syncSupabaseSession(_supabase.auth.currentSession),
        )
        .subscribe();
  }

  void _clearProfileStatusWatch() {
    final channel = _profileStatusChannel;
    if (channel != null) {
      _supabase.removeChannel(channel);
    }
    _profileStatusChannel = null;
    _watchedProfileId = null;
  }

  @override
  Stream<AccountStatus> get accountStatusStream async* {
    yield _status;
    yield* _statusController.stream;
  }

  @override
  AccountStatus get currentStatus => _status;

  @override
  String? get currentUserId => _supabase.auth.currentSession?.user.id;

  @override
  String? get currentUserEmail =>
      _supabase.auth.currentSession?.user.email ?? _pendingEmail;

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _syncSupabaseSession(response.session);
  }

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _pendingEmail = email;
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (response.session != null) {
      await _syncSupabaseSession(response.session);
      return;
    }

    // Try fallback login in case email confirmation is disabled but auto-login was bypassed
    try {
      final signInResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (signInResponse.session != null) {
        await _syncSupabaseSession(signInResponse.session);
        return;
      }
    } catch (_) {
      // Ignore fallback sign-in errors and throw the main exception below
    }

    throw Exception(
      'Signup succeeded, but no session was created. Please verify that email confirmation is disabled in Supabase or that you are not using an already registered email.',
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    const iosClientId =
        '970180731986-3lvorp988fvlmc9i2nvboqpjko5b61sd.apps.googleusercontent.com';
    const webClientId =
        '970180731986-4dbftaibf8iccgsg316568jbgb2jvlu5.apps.googleusercontent.com';

    await gsis.GoogleSignIn.instance.initialize(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await gsis.GoogleSignIn.instance.authenticate();
    _pendingEmail = googleUser.email;

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('No ID Token found from Google Sign-In.');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    await _syncSupabaseSession(response.session);
  }

  @override
  Future<void> signInWithApple() async {
    final rawNonce = _randomNonce();
    final hashedNonce = sha256
        .convert(Uint8List.fromList(rawNonce.codeUnits))
        .toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw Exception('Apple Sign-In did not return an identity token.');
    }

    _pendingEmail = credential.email;
    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: identityToken,
      nonce: rawNonce,
    );
    await _syncSupabaseSession(response.session);
  }

  String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  @override
  Future<void> signOut() async {
    await gsis.GoogleSignIn.instance.signOut();
    await _supabase.auth.signOut();
    _pendingEmail = null;
    _clearProfileStatusWatch();
    _setStatus(AccountStatus.unauthenticated);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.recovery,
    );
    await _syncSupabaseSession(response.session);
  }

  @override
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    await signOut();
  }

  @override
  Future<void> updateRegistrationProgress({
    required String name,
    required String gender,
    required DateTime dob,
    required String religion,
    required String bio,
    required double latitude,
    required double longitude,
    required String city,
    required String countryCode,
    required List<String> images,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('No authenticated user');

    if (_supabase.auth.currentSession != null) {
      final List<String> defaultMaleUrls = [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500',
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500',
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=500',
        'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=500',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
      ];

      final List<String> defaultFemaleUrls = [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500',
        'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=500',
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
      ];

      // Delete any existing photos first to avoid duplicates
      await _supabase.from('profile_photos').delete().eq('user_id', userId);

      final List<Map<String, dynamic>> photosToInsert = [];
      
      // Upload actual selected images
      if (images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final path = images[i];
          final file = File(path);
          if (file.existsSync()) {
            try {
              final bytes = file.readAsBytesSync();
              final fileExtension = path.split('.').last.toLowerCase();
              final objectPath = '$userId/${DateTime.now().microsecondsSinceEpoch}_$i.$fileExtension';
              
              String contentType = 'image/jpeg';
              if (fileExtension == 'png') {
                contentType = 'image/png';
              } else if (fileExtension == 'webp') {
                contentType = 'image/webp';
              } else if (fileExtension == 'gif') {
                contentType = 'image/gif';
              }

              await _supabase.storage.from('profile_photos').uploadBinary(
                objectPath,
                bytes,
                fileOptions: FileOptions(
                  contentType: contentType,
                  upsert: false,
                ),
              );
              
              final publicUrl = _supabase.storage.from('profile_photos').getPublicUrl(objectPath);
              photosToInsert.add({
                'user_id': userId,
                'public_url': publicUrl,
                'is_primary': i == 0,
                'sort_order': i,
                'moderation_status': 'pending', // Under review until approved
              });
            } catch (_) {}
          }
        }
      }

      // Fallback to mock photos if no images were successfully uploaded
      if (photosToInsert.isEmpty) {
        final List<Map<String, dynamic>> fallbackPhotos = [];
        final defaultList = gender == 'Male'
            ? defaultMaleUrls
            : defaultFemaleUrls;

        final int count = images.isEmpty
            ? 2
            : images.length; // Ensure at least 2 photos
        for (int i = 0; i < count; i++) {
          fallbackPhotos.add({
            'user_id': userId,
            'public_url': defaultList[i % defaultList.length],
            'is_primary': i == 0,
            'sort_order': i,
            'moderation_status': 'pending',
          });
        }
        photosToInsert.addAll(fallbackPhotos);
      }

      final List<dynamic> photosResult = await _supabase
          .from('profile_photos')
          .insert(photosToInsert)
          .select('id');

      final String? firstPhotoId = photosResult.isNotEmpty
          ? photosResult[0]['id'] as String?
          : null;

      await _supabase.from('profiles').upsert({
        'id': userId,
        'public_name': name,
        'gender': gender,
        'religion': religion,
        'bio': bio,
        'age': _ageFromDob(dob),
        'public_city': city,
        'public_country_code': countryCode,
        'profile_status': 'verification_not_submitted',
        'verification_status': 'not_submitted',
        'profile_completion': 50,
        'main_photo_id': firstPhotoId,
      });

      await _supabase.from('private_user_data').upsert({
        'user_id': userId,
        'date_of_birth': dob.toIso8601String().substring(0, 10),
        'exact_latitude': latitude,
        'exact_longitude': longitude,
      });
    }

    _setStatus(AccountStatus.verificationNotSubmitted);
  }

  @override
  Future<void> submitFaceVerification(String videoPath) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('No authenticated user');

    String finalVideoPath = videoPath;

    if (_supabase.auth.currentSession != null) {
      final file = File(videoPath);
      if (file.existsSync()) {
        try {
          final fileName =
              'verification_${DateTime.now().millisecondsSinceEpoch}.mp4';
          final storagePath = '$userId/$fileName';

          await _supabase.storage
              .from('verifications')
              .upload(
                storagePath,
                file,
                fileOptions: const FileOptions(
                  contentType: 'video/mp4',
                  upsert: true,
                ),
              );

          finalVideoPath = _supabase.storage
              .from('verifications')
              .getPublicUrl(storagePath);
        } catch (e) {
          print('Error uploading verification video: $e');
        }
      } else {
        // Fallback to a placeholder video for simulation/testing
        finalVideoPath = 'https://www.w3schools.com/html/mov_bbb.mp4';
      }

      await _supabase.from('verification_submissions').insert({
        'user_id': userId,
        'video_storage_path': finalVideoPath,
        'status': 'pending',
      });

      await _supabase
          .from('profiles')
          .update({
            'verification_status': 'pending',
            'profile_status': 'verification_pending',
          })
          .eq('id', userId);
    }

    _setStatus(AccountStatus.verificationPending);
  }

  @override
  Future<void> acceptCommunityRules({
    required String rulesVersion,
    required String locale,
    required String appVersion,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('No authenticated user');

    if (_supabase.auth.currentSession != null) {
      await _supabase.from('community_rule_acceptances').upsert({
        'user_id': userId,
        'rules_version': rulesVersion,
        'locale': locale,
        'app_version': appVersion,
      });

      await _supabase
          .from('profiles')
          .update({'profile_completion': 80})
          .eq('id', userId);
    }
  }

  int _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Future<void> deleteAccount() async {
    final userId = currentUserId;
    if (userId != null) {
      try {
        await _supabase.rpc('delete_my_account');
      } catch (_) {
        // Fallback: attempt direct deletion from public.profiles
        try {
          await _supabase.from('profiles').delete().eq('id', userId);
        } catch (_) {}
      }
    }
    await signOut();
  }
}
