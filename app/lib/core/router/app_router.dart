import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap.dart';
import '../../data/repositories/profiles_repository.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/game_detail/presentation/screens/game_detail_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/lists/presentation/screens/list_detail_screen.dart';
import '../../features/lists/presentation/screens/lists_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_link_or_manual_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_manual_add_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_rate_games_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import 'go_router_refresh_stream.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshStream = GoRouterRefreshStream(supabase.auth.onAuthStateChange);
  ref.onDispose(refreshStream.dispose);

  return GoRouter(
    initialLocation: RoutePaths.search,
    refreshListenable: refreshStream,
    redirect: (context, state) async {
      final session = supabase.auth.currentSession;
      final loggingIn = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.signup;

      if (session == null) {
        return loggingIn ? null : RoutePaths.login;
      }
      if (loggingIn) return RoutePaths.search;

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
        path: RoutePaths.onboardingWelcome,
        builder: (context, state) => const OnboardingWelcomeScreen(),
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
      GoRoute(
        path: RoutePaths.profile,
        builder: (context, state) => ProfileScreen(username: state.pathParameters['username']!),
      ),
    ],
  );
});
