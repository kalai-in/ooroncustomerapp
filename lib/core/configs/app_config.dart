import 'package:customer/commons/models/countries_model.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central configuration file for buyers to customise.
///
/// ─── HOW TO CONFIGURE ───────────────────────────────────────────────────────
///   1. Pick the active environment by editing [environment] below.
///      Available environments live as JSON files in `env/`:
///        env/demo.json
///   2. Edit the URLs/host in the matching `env/<name>.json` file.
///   3. Run:  dart run tool/apply_config.dart
///      The script reads the selected env JSON and:
///        • rewrites the URL constants below
///        • patches AndroidManifest.xml, Info.plist
///   4. Build / run:  flutter clean && flutter run
/// ────────────────────────────────────────────────────────────────────────────
abstract final class AppConfig {
  /// Active environment — maps to `env/<environment>.json`.
  static const String environment = 'demo';

  // ─── AUTO-SYNCED FROM env/<environment>.json — DO NOT EDIT BY HAND ────────
  // Run `dart run tool/apply_config.dart` to refresh these values.
  // ──────────────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://admin.ooron.in/customer/';
  static const String webUrl = 'https://ooron.in';
  static const String socketBaseUrl =
      'wss://admin.ooron.in:8080/app/w73uw1egonunwexdhebg';

  /// Custom scheme deep link (e.g. `snapbuy://product/{id}`).
  static const String deeplinkScheme = 'ooron';

  /// App Links host (must match [webUrl]'s host).
  static const String deeplinkHost = 'ooron.in';
  // ──────────────────────────────────────────────────────────────────────────

  // app name
  static const String appName = 'ooron';

  // package name
  static const String appPackageName = 'app.ooron.customer';

  // Pagination
  static const int pageLimit = 10;
  static const int gridPageLimit = 12;

  // Defaults
  /// Default dial code shown in the phone field, this work only in fallback if setting API failed.
  static CountriesData defaultCountry = CountriesData(
    code: 'IN',
    dialCode: '+91',
  );
  static const String defaultLanguageCode = 'en';

  /// Countdown, in seconds, before "Resend OTP" becomes enabled.
  static const int otpResendTimerSeconds = 60;

  // Microsoft Clarity project ID (clarity.microsoft.com dashboard).
  static const String clarityProjectId = 'YOUR_CLARITY_PROJECT_ID_HERE';

  //osm map render url
  static const String osmMapRenderUrl =
      "https://tile.openstreetmap.org/{z}/{x}/{y}.png"; //"https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png";

  // App-wide font family
  static final String? fontFamily = GoogleFonts.instrumentSans().fontFamily;
}
