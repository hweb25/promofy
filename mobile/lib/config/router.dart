import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/consumer/consumer_shell.dart';
import '../screens/consumer/home_screen.dart';
import '../screens/consumer/map_screen.dart';
import '../screens/consumer/promotions_screen.dart';
import '../screens/consumer/promotion_detail_screen.dart';
import '../screens/consumer/profile_screen.dart';
import '../screens/consumer/redemption_screen.dart';
import '../screens/business/business_shell.dart';
import '../screens/business/business_home_screen.dart';
import '../screens/business/create_promotion_screen.dart';
import '../screens/business/analytics_screen.dart';
import '../screens/business/qr_scanner_screen.dart';
import '../screens/business/business_profile_screen.dart';
import '../screens/business/subscription_screen.dart';
import '../screens/shared/splash_screen.dart';
import '../screens/shared/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (isSplash || isOnboarding) return null;

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/consumer';

      return null;
    },
    routes: [
      // Splash & Onboarding
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // Auth
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/role-select', builder: (_, __) => const RoleSelectionScreen()),

      // Consumer App
      ShellRoute(
        builder: (_, __, child) => ConsumerShell(child: child),
        routes: [
          GoRoute(
            path: '/consumer',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/consumer/map',
            builder: (_, __) => const MapScreen(),
          ),
          GoRoute(
            path: '/consumer/promotions',
            builder: (_, __) => const PromotionsScreen(),
          ),
          GoRoute(
            path: '/consumer/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/consumer/promotion/:id',
        builder: (_, state) => PromotionDetailScreen(
          promotionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/consumer/redemption/:id',
        builder: (_, state) => RedemptionScreen(
          redemptionId: state.pathParameters['id']!,
        ),
      ),

      // Business App
      ShellRoute(
        builder: (_, __, child) => BusinessShell(child: child),
        routes: [
          GoRoute(
            path: '/business',
            builder: (_, __) => const BusinessHomeScreen(),
          ),
          GoRoute(
            path: '/business/analytics',
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/business/scanner',
            builder: (_, __) => const QrScannerScreen(),
          ),
          GoRoute(
            path: '/business/profile',
            builder: (_, __) => const BusinessProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/business/promotions/create',
        builder: (_, __) => const CreatePromotionScreen(),
      ),
      GoRoute(
        path: '/business/subscription',
        builder: (_, __) => const SubscriptionScreen(),
      ),
    ],
  );
});
