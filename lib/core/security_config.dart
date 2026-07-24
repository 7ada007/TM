import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Certificate pinning for the API host.
///
/// Disabled by default and deliberately so. Dart's [X509Certificate] exposes the
/// full DER of the leaf certificate but not its SubjectPublicKeyInfo, so what is
/// pinned here is the whole leaf certificate — which changes on every renewal.
/// Let's Encrypt renews roughly every 60-90 days, so an installed build with a
/// stale pin stops being able to reach the API until the user updates.
///
/// Because of that, only turn this on if you can either:
///   * pin the certificate you control and ship an app update before it rotates, or
///   * list several pins at once, including the next certificate you plan to use.
///
/// To collect the current pin:
/// ```
/// openssl s_client -connect api.tareeqalmajd.best:443 \
///   -servername api.tareeqalmajd.best < /dev/null 2>/dev/null \
///   | openssl x509 -outform der | openssl dgst -sha256 -binary | openssl base64
/// ```
///
/// Put the result in [pinnedCertSha256], then build with:
///   flutter build apk --release --dart-define=ENABLE_CERT_PINNING=true
abstract final class SecurityConfig {
  static const bool enableCertificatePinning = bool.fromEnvironment(
    'ENABLE_CERT_PINNING',
    defaultValue: false,
  );

  static const String apiHost = 'api.tareeqalmajd.best';

  /// Base64 SHA-256 digests of trusted leaf certificates (DER form).
  /// Keep at least two entries in production: the live cert and its successor.
  static const List<String> pinnedCertSha256 = <String>[];

  static bool get pinningActive =>
      enableCertificatePinning && pinnedCertSha256.isNotEmpty;
}

/// Hook for `IOHttpClientAdapter.validateCertificate`, which runs on every HTTPS
/// connection *after* the platform's own chain validation has already passed.
///
/// Returning true accepts the connection. When pinning is off this must return
/// true, otherwise every request would fail.
bool validateApiCertificate(X509Certificate? cert, String host, int port) {
  if (!SecurityConfig.pinningActive) return true;
  if (host != SecurityConfig.apiHost) return true;
  if (cert == null) return false;

  final fingerprint = base64.encode(sha256.convert(cert.der).bytes);
  final trusted = SecurityConfig.pinnedCertSha256.contains(fingerprint);

  if (!trusted && kDebugMode) {
    debugPrint('Certificate pin mismatch for $host. Presented: $fingerprint');
  }
  return trusted;
}

/// Hook for `HttpClient.badCertificateCallback`, which only fires when the
/// platform has *rejected* the chain. Always refuse — accepting here would
/// re-open the self-signed / MITM proxy hole that pinning exists to close.
bool rejectBadCertificate(X509Certificate cert, String host, int port) => false;
