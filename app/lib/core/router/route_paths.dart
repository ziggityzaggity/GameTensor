class RoutePaths {
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  // Deep-link target for the password-recovery email. Must be in the Supabase
  // redirect allowlist (config.toml additional_redirect_urls).
  static const resetPassword = '/reset-callback';
  static const onboardingWelcome = '/onboarding';
  static const onboardingUsername = '/onboarding/username';
  static const onboardingLinkOrManual = '/onboarding/link-or-manual';
  static const onboardingManualAdd = '/onboarding/manual-add';
  static const onboardingRateGames = '/onboarding/rate-games';
  static const search = '/search';
  static const assistant = '/assistant';
  static const gameDetail = '/game/:id';
  static const library = '/library';
  static const lists = '/lists';
  static const listDetail = '/lists/:id';
  static const feed = '/feed';
  static const friendRequests = '/friends/requests';
  static const profile = '/profile/:username';
  static const editProfile = '/profile/edit';

  static String gameDetailPath(String id) => '/game/$id';
  static String listDetailPath(String id) => '/lists/$id';
  static String profilePath(String username) => '/profile/$username';
}
