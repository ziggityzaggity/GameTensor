import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap.dart';
import '../../data/repositories/profiles_repository.dart';
import '../../features/auth/application/password_recovery_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/friends/presentation/screens/friend_requests_screen.dart';
import '../../features/game_detail/presentation/screens/game_detail_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/lists/presentation/screens/list_detail_screen.dart';
import '../../features/lists/presentation/screens/lists_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_link_or_manual_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_manual_add_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_rate_games_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_username_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import 'go_router_refresh_stream.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshStream = GoRouterRefreshStream(supabase.auth.onAuthStateChange);
  ref.onDispose(refreshStream.dispose);
  // Keep the recovery listener alive for the app's lifetime so a
  // PASSWORD_RECOVERY event is captured even before redirect first reads it.
  ref.listen(passwordRecoveryProvider, (_, __) {});

  return GoRouter(
    initialLocation: RoutePaths.search,
    refreshListenable: refreshStream,
    redirect: (context, state) async {
      final session = supabase.auth.currentSession;
      // Unauthenticated routes reachable without a session. Password reset is
      // included so a user who forgot their password (and thus can't sign in)
      // can still request a link.
      final onPublicAuthRoute = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.signup ||
          state.matchedLocation == RoutePaths.forgotPassword;

      // A password-recovery deep link creates a real session, which would
      // otherwise get swept into /search or /onboarding by the gate below.
      // While recovery is active, pin the user to the reset screen so they must
      // set a new password before entering the app.
      final inRecovery = ref.read(passwordRecoveryProvider);
      if (inRecovery) {
        return state.matchedLocation == RoutePaths.resetPassword
            ? null
            : RoutePaths.resetPassword;
      }

      if (session == null) {
        return onPublicAuthRoute ? null : RoutePaths.login;
      }
      if (onPublicAuthRoute) return RoutePaths.search;
      // Reaching /reset-callback with a normal (non-recovery) session — e.g. an
      // already signed-in user opening a stale link — has nothing to reset.
      if (state.matchedLocation == RoutePaths.resetPassword) return RoutePaths.search;

      final onOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
      final profile = await ref.read(currentProfileProvider.future);
      final onboardingDone = profile?.onboardingCompletedAt != null;

      if (!onboardingDone && !onOnboardingRoute) {
        return RoutePaths.onboardingWelcome;
      }
      if (onboardingDone && onOnboardingRoute) {
        return RoutePaths.search;
      }
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RoutePaths.signup, builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingWelcome,
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingUsername,
        builder: (context, state) => const OnboardingUsernameScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingLinkOrManual,
        builder: (context, state) => const OnboardingLinkOrManualScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingManualAdd,
        builder: (context, state) => const OnboardingManualAddScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboardingRateGames,
        builder: (context, state) => const OnboardingRateGamesScreen(),
      ),
      GoRoute(path: RoutePaths.search, builder: (context, state) => const SearchScreen()),
      GoRoute(
        path: RoutePaths.gameDetail,
        builder: (context, state) => GameDetailScreen(gameId: state.pathParameters['id']!),
      ),
      GoRoute(path: RoutePaths.library, builder: (context, state) => const LibraryScreen()),
      GoRoute(path: RoutePaths.lists, builder: (context, state) => const ListsScreen()),
      GoRoute(
        path: RoutePaths.listDetail,
        builder: (context, state) => ListDetailScreen(listId: state.pathParameters['id']!),
      ),
      GoRoute(path: RoutePaths.feed, builder: (context, state) => const FeedScreen()),
      GoRoute(
        path: RoutePaths.friendRequests,
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      // Registered before /profile/:username so the literal "edit" segment isn't
      // captured as a username.
      GoRoute(
        path: RoutePaths.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.profile,
        builder: (context, state) => ProfileScreen(username: state.pathParameters['username']!),
      ),
    ],
  );
});
