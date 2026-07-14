import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/account_status.dart';

abstract class AuthRepositoryInterface {
  Stream<AccountStatus> get accountStatusStream;
  AccountStatus get currentStatus;
  String? get currentUserId;
  String? get currentUserEmail;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  });

  Future<void> verifyEmail();

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
  });

  Future<void> submitFaceVerification(String videoPath);

  Future<void> acceptCommunityRules({
    required String rulesVersion,
    required String locale,
    required String appVersion,
  });

  Future<void> resendVerificationEmail();
}

final authRepositoryProvider = Provider<AuthRepositoryInterface>((ref) {
  throw UnimplementedError('authRepositoryProvider is not overridden');
});
