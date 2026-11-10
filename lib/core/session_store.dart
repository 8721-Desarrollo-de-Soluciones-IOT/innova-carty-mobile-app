import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_client.dart';

/// Keeps the signed-in user on the phone so the app opens straight in its view.
class SessionStore {
  SessionStore._();

  static const _key = 'innova-carty-user';
  static UserAccount? current;

  static Future<UserAccount?> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final user = UserAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _activate(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(UserAccount user) async {
    _activate(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }

  static Future<void> clear() async {
    current = null;
    ApiClient.instance.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static void _activate(UserAccount user) {
    current = user;
    ApiClient.instance.token = user.token;
  }
}
