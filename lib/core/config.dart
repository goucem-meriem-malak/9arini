/// Values injected at build time with --dart-define-from-file=config.json.
/// Nothing private is stored in source code.
abstract final class AppConfig {
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const String legalVersion = '1.0';
  static const String functionsRegion = 'europe-west1';
  static const int maxUploadBytes = 10 * 1024 * 1024;
}
