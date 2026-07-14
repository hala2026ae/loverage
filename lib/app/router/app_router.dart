import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/domain/account_status.dart';
import '../../features/authentication/domain/auth_repository_interface.dart';

// Import screens (which we will create next)
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/authentication/presentation/welcome_screen.dart';
import '../../features/authentication/presentation/signin_screen.dart';
import '../../features/authentication/presentation/signup_screen.dart';
import '../../features/authentication/presentation/verify_email_screen.dart';
import '../../features/registration/presentation/registration_wizard.dart';
import '../../features/verification/presentation/face_verification_screen.dart';
import '../../features/community_rules/presentation/community_rules_screen.dart';
import '../../features/verification/presentation/pending_screen.dart';
import '../../features/verification/presentation/rejected_screen.dart';
import '../../features/moderation/presentation/suspended_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/profiles/presentation/profile_detail_screen.dart';
import '../../features/conversations/presentation/chat_detail_screen.dart';
import '../../features/subscriptions/presentation/paywall_screen.dart';
import '../../features/notifications/presentation/notification_center_screen.dart';
import '../../features/moderation/presentation/admin_dashboard.dart';
import '../../features/moderation/presentation/deactivated_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  AccountStatus _status = AccountStatus.unauthenticated;

  RouterNotifier(this._ref) {
    // Listen to changes in authRepository and trigger notifyListeners()
    _ref.listen<AsyncValue<AccountStatus>>(authStatusProvider, (
      previous,
      next,
    ) {
      final nextStatus = next.valueOrNull ?? AccountStatus.unauthenticated;
      if (previous?.valueOrNull != nextStatus) {
        _status = nextStatus;
        notifyListeners();
      }
    }, fireImmediately: true);
  }

  AccountStatus get status => _status;
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

// A simple provider for the current account status stream
final authStatusProvider = StreamProvider<AccountStatus>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.accountStatusStream;
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final status = notifier.status;
      final location = state.uri.path;

      // Unauthenticated paths
      final isAuthPath =
          location == '/welcome' ||
          location == '/signin' ||
          location == '/signup';
      final isOnboardingPath = location == '/onboarding';
      final isSplash = location == '/splash';

      // 1. Handle unauthenticated states
      if (status == AccountStatus.unauthenticated) {
        if (isSplash) return '/onboarding'; // Route to onboarding first
        if (!isOnboardingPath && !isAuthPath) {
          return '/welcome';
        }
        return null;
      }

      // 2. Handle restricted states (Suspended / Deactivated / Deletion)
      if (status.isSuspended) {
        if (location != '/suspended') return '/suspended';
        return null;
      }
      if (status.isDeactivated) {
        if (location != '/deactivated') return '/deactivated';
        return null;
      }

      // 3. Handle email unverified
      if (status == AccountStatus.emailUnverified) {
        if (location != '/verify-email') return '/verify-email';
        return null;
      }

      // 4. Handle registration steps
      if (status == AccountStatus.registrationIncomplete) {
        if (location != '/register') return '/register';
        return null;
      }

      // 5. Handle verification video submission
      if (status == AccountStatus.verificationNotSubmitted) {
        if (location != '/face-verification') return '/face-verification';
        return null;
      }

      // 6. Handle community rules acceptance
      if (status == AccountStatus.verificationPending) {
        // If pending, check if they accepted rules. We can route rules before showing pending
        // But for clarity: rules are accepted right after video upload.
        if (location != '/verification-pending') return '/verification-pending';
        return null;
      }

      // 7. Handle rejected state
      if (status.isRejected) {
        if (location != '/verification-rejected')
          return '/verification-rejected';
        return null;
      }

      // 8. Handle approved state (access to main application)
      if (status.isApproved) {
        // Prevent approved users from seeing auth/onboarding/registration
        if (isSplash ||
            isAuthPath ||
            isOnboardingPath ||
            location == '/verify-email' ||
            location == '/register' ||
            location == '/face-verification' ||
            location == '/verification-pending') {
          return '/home';
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SigninScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationWizard(),
      ),
      GoRoute(
        path: '/face-verification',
        builder: (context, state) => const FaceVerificationScreen(),
      ),
      GoRoute(
        path: '/community-rules',
        builder: (context, state) => const CommunityRulesScreen(),
      ),
      GoRoute(
        path: '/verification-pending',
        builder: (context, state) => const VerificationPendingScreen(),
      ),
      GoRoute(
        path: '/verification-rejected',
        builder: (context, state) => const VerificationRejectedScreen(),
      ),
      GoRoute(
        path: '/suspended',
        builder: (context, state) => const SuspendedScreen(),
      ),
      GoRoute(
        path: '/deactivated',
        builder: (context, state) => const DeactivatedScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final profileId = state.pathParameters['id']!;
          return ProfileDetailScreen(profileId: profileId);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final conversationId = state.pathParameters['id']!;
          return ChatDetailScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
});

// Temporary SplashScreen widget definition (highly lightweight)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF5E0B24), // Brand burgundy
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD48E7C), // Rose gold
        ),
      ),
    );
  }
}
