import 'dart:convert';
import 'package:crypto/crypto.dart';

/// PIN is never stored in plaintext — only its SHA-256 hash.
///
/// Add to pubspec.yaml dependencies if not already there:
///   crypto: ^3.0.3
class PinService {
  static String hash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  static bool verify(String pin, String storedHash) =>
      hash(pin) == storedHash;
}
