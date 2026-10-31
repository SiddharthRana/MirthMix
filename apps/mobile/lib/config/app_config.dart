/// Build-time configuration, supplied with `--dart-define` (see apps/mobile/README.md).
/// Without these the app is fully playable; Premium just says it isn't available in this build.
abstract final class AppConfig {
  /// MirthMix API (apps/api), e.g. https://api.mirthmix.example. Android emulator: http://10.0.2.2:4000.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Website, where web subscriptions are managed.
  static const siteUrl = String.fromEnvironment('SITE_URL', defaultValue: 'https://mirthmix.example');

  static const packageName = 'com.mirthmix.app';

  static bool get accountsConfigured =>
      apiBaseUrl.isNotEmpty && supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
