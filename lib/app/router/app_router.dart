import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/authentication/domain/account_status.dart';
import '../../features/authentication/domain/auth_repository_interface.dart';

// Import screens (which we will create next)
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/authentication/presentation/welcome_screen.dart';
import '../../features/authentication/presentation/signin_screen.dart';
import '../../features/authentication/presentation/signup_screen.dart';
import '../../features/authentication/presentation/password_reset_screens.dart';
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
import '../../features/account/presentation/profile_editor_screen.dart';
import '../../features/account/presentation/policy_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  AccountStatus _status = AccountStatus.initializing;

  RouterNotifier(this._ref) {
    // Listen to changes in authRepository and trigger notifyListeners()
    _ref.listen<AsyncValue<AccountStatus>>(authStatusProvider, (
      previous,
      next,
    ) {
      final nextStatus = next.valueOrNull ?? _status;
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
    redirect: (context, state) async {
      final status = notifier.status;
      final location = state.uri.path;

      // Unauthenticated paths
      final isAuthPath =
          location == '/welcome' ||
          location == '/signin' ||
          location == '/signup';
      final isPasswordResetPath =
          location == '/forgot-password' ||
          location == '/forgot-password/otp' ||
          location == '/reset-password';
      final isOnboardingPath = location == '/onboarding';
      final isSplash = location == '/splash';

      // Keep the launch gate visible while Supabase restores its session and
      // the repository resolves the user's profile status.
      if (status == AccountStatus.initializing) {
        return isSplash ? null : '/splash';
      }

      // 1. Handle unauthenticated states
      if (status == AccountStatus.unauthenticated) {
        if (isSplash) {
          final prefs = await SharedPreferences.getInstance();
          final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
          return seenOnboarding ? '/welcome' : '/onboarding';
        }
        if (!isOnboardingPath && !isAuthPath && !isPasswordResetPath) {
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

      // 3. Handle registration steps
      if (status == AccountStatus.registrationIncomplete) {
        if (location != '/register') return '/register';
        return null;
      }

      // 4. Handle verification video submission
      if (status == AccountStatus.verificationNotSubmitted) {
        if (location != '/face-verification' &&
            location != '/community-rules') {
          return '/face-verification';
        }
        return null;
      }

      // 5. Handle community rules acceptance (verification pending users can go to /home directly)
      if (status == AccountStatus.verificationPending) {
        if (isSplash ||
            isAuthPath ||
            isOnboardingPath ||
            location == '/register' ||
            location == '/face-verification' ||
            location == '/verification-pending') {
          return '/home';
        }
        return null;
      }

      // 6. Handle rejected state
      if (status.isRejected) {
        if (location != '/verification-rejected') {
          return '/verification-rejected';
        }
        return null;
      }

      // 7. Handle approved state (access to main application)
      if (status.isApproved) {
        // Prevent approved users from seeing auth/onboarding/registration
        if (isSplash ||
            isAuthPath ||
            isOnboardingPath ||
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
        builder: (context, state) => SigninScreen(
          initialEmail: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordEmailScreen(
          initialEmail: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/forgot-password/otp',
        builder: (context, state) => PasswordResetOtpScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
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
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final requests = state.uri.queryParameters['requests'];
          return HomeShell(
            initialIndex: switch (tab) {
              'knocks' => 1,
              'messages' => 2,
              'account' => 3,
              _ => 0,
            },
            initialMessageTabIndex: tab == 'messages' ? 1 : 0,
            initialRequestTabIndex: requests == 'sent' ? 0 : 1,
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) =>
            const ProfileEditorScreen(sectionId: 'basic'),
      ),
      GoRoute(
        path: '/edit-profile/:section',
        builder: (context, state) =>
            ProfileEditorScreen(sectionId: state.pathParameters['section']!),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final profileId = state.pathParameters['id']!;
          final knocked = state.uri.queryParameters['knocked'] == 'true';
          final messaged = state.uri.queryParameters['messaged'] == 'true';
          return ProfileDetailScreen(
            profileId: profileId,
            initialKnocked: knocked,
            initialMessaged: messaged,
          );
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
        path: '/terms',
        builder: (context, state) => const PolicyScreen(
          title: 'Terms & Conditions',
          content: _termsPolicyContent,
        ),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PolicyScreen(
          title: 'Privacy Policy',
          content: _privacyPolicyContent,
        ),
      ),
      GoRoute(
        path: '/refund',
        builder: (context, state) => const PolicyScreen(
          title: 'Refund Policy',
          content: _refundPolicyContent,
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
    ],
  );
});

const _termsPolicyContent = '''
Welcome to Loverage. By using the app, you agree to use the service respectfully, provide accurate profile information, and follow all community safety requirements.

Loverage is designed for serious relationship and marriage-minded connections. Misrepresentation, harassment, abusive behavior, spam, or attempts to move users into unsafe interactions may result in restricted access or account removal.

Subscriptions and paid features are billed through the applicable app store or payment provider. Continued use of the service means you accept updates to these terms when they are posted in the app.
''';

const _privacyPolicyContent = '''
Loverage collects account, profile, verification, preference, messaging, and app usage information needed to operate the service, improve matching, protect members, and provide support.

Profile details and photos may be visible to other approved members according to app features and your settings. Verification and moderation data are used for safety review and abuse prevention.

We use service providers such as authentication, hosting, storage, analytics, messaging, and payment platforms to run the app. You can request account deletion from settings, subject to legal, safety, and fraud-prevention retention needs.
''';

const _refundPolicyContent = '''
Refund eligibility depends on the payment provider used for your purchase. App store purchases must generally be requested through Apple App Store or Google Play.

Refunds are not guaranteed for partially used subscription periods, account restrictions caused by policy violations, or unused premium features after access has been delivered.

If you believe a purchase was charged incorrectly, contact support with your account email, purchase date, and transaction reference so the team can review it.
''';

// Temporary SplashScreen widget definition (highly lightweight)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 0.88, end: 1.08).animate(curve);
    _opacity = Tween<double>(begin: 0.68, end: 1.0).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 1.25,
            colors: [Color(0xFF9B294A), Color(0xFF5E0B24), Color(0xFF23030D)],
            stops: [0.0, 0.58, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.16),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'Assets/loverage text.png',
                    height: 34,
                    fit: BoxFit.contain,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(scale: _scale.value, child: child),
                    ),
                    child: Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF7D5C4), Color(0xFFC57A68)],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.38),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF3B89F,
                            ).withValues(alpha: 0.34),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFF5E0B24),
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Opening your journey',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.8,
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
