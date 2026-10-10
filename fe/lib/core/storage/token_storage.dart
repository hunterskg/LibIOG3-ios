import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fe/features/auth/domain/models/user_res.dart';

abstract class TokenStorage {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUser(UserRes user);
  Future<UserRes?> getUser();
  Future<void> clear();
}

class SharedPreferencesTokenStorage implements TokenStorage {
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUser = 'user_data';

  final SharedPreferences _prefs;

  SharedPreferencesTokenStorage(this._prefs);

  static Future<SharedPreferencesTokenStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesTokenStorage(prefs);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_kAccessToken, accessToken);
    await _prefs.setString(_kRefreshToken, refreshToken);
  }

  @override
  Future<String?> getAccessToken() async => _prefs.getString(_kAccessToken);

  @override
  Future<String?> getRefreshToken() async => _prefs.getString(_kRefreshToken);

  @override
  Future<void> saveUser(UserRes user) async {
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
  }

  @override
  Future<UserRes?> getUser() async {
    final raw = _prefs.getString(_kUser);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserRes.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
    await _prefs.remove(_kUser);
  }
}
