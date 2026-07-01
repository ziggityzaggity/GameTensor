class RoutePaths {
  static const login = '/login';
  static const signup = '/signup';
  static const onboardingWelcome = '/onboarding';
  static const onboardingLinkOrManual = '/onboarding/link-or-manual';
  static const onboardingManualAdd = '/onboarding/manual-add';
  static const onboardingRateGames = '/onboarding/rate-games';
  static const search = '/search';
  static const gameDetail = '/game/:id';
  static const library = '/library';
  static const lists = '/lists';
  static const listDetail = '/lists/:id';
  static const profile = '/profile/:username';

  static String gameDetailPath(String id) => '/game/$id';
  static String listDetailPath(String id) => '/lists/$id';
  static String profilePath(String username) => '/profile/$username';
}
