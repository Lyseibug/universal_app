import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure store for the PDT authentication token.
///
/// Backed by encrypted Shared Preferences on Android and Keychain on iOS.
class TokenStore {
  final _s = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Read the stored auth token ("api_key:api_secret").
  Future<String?> read() => _s.read(key: 'pdt_token');

  /// Write the auth token to secure storage.
  Future<void> write(String t) => _s.write(key: 'pdt_token', value: t);

  /// Delete the stored auth token.
  Future<void> clear() => _s.delete(key: 'pdt_token');
}
