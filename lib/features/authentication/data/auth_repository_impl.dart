import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/account_status.dart';
import '../domain/auth_repository_interface.dart';

class AuthRepositoryImpl implements AuthRepositoryInterface {
  final SupabaseClient _supabase;
  final _statusController = StreamController<AccountStatus>.broadcast();
  AccountStatus _status = AccountStatus.unauthenticated;

  AuthRepositoryImpl(this._supabase) {
    _syncSupabaseSession(_supabase.auth.currentSession);
    _supabase.auth.onAuthStateChange.listen(
      (data) {
        _syncSupabaseSession(data.session);
      },
      onError: (_) {
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
      _setStatus(AccountStatus.unauthenticated);
      return;
    }

    if (session.user.emailConfirmedAt == null) {
      _setStatus(AccountStatus.emailUnverified);
      return;
    }

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
    } else if (profileStatus == 'active' && verificationStatus == 'approved') {
      _setStatus(AccountStatus.verificationApproved);
    } else if (profileStatus == 'verification_pending' ||
        verificationStatus == 'pending') {
      _setStatus(AccountStatus.verificationPending);
    } else if (profileStatus == 'verification_not_submitted') {
      _setStatus(AccountStatus.verificationNotSubmitted);
    } else {
      _setStatus(AccountStatus.registrationIncomplete);
    }
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
  String? get currentUserEmail => _supabase.auth.currentSession?.user.email;

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
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    await _syncSupabaseSession(response.session);
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _setStatus(AccountStatus.unauthenticated);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> verifyEmail() async {
    await _supabase.auth.refreshSession();
    await _syncSupabaseSession(_supabase.auth.currentSession);
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
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('No authenticated user');

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
    });

    await _supabase.from('private_user_data').upsert({
      'user_id': userId,
      'date_of_birth': dob.toIso8601String().substring(0, 10),
      'exact_latitude': latitude,
      'exact_longitude': longitude,
    });

    _setStatus(AccountStatus.verificationNotSubmitted);
  }

  @override
  Future<void> submitFaceVerification(String videoPath) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('No authenticated user');

    await _supabase.from('verification_submissions').insert({
      'user_id': userId,
      'video_storage_path': videoPath,
      'status': 'pending',
    });

    await _supabase
        .from('profiles')
        .update({
          'verification_status': 'pending',
          'profile_status': 'verification_pending',
        })
        .eq('id', userId);

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

  @override
  Future<void> resendVerificationEmail() async {
    final email = currentUserEmail;
    if (email == null) throw Exception('No email address available');
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  int _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day))
      age--;
    return age;
  }
}
