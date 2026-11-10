import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'messages.dart';
import 'server_texts.dart';

/// Language of the app: Spanish by default, English with the ES | EN selector.
class I18n {
  I18n._();

  static const supported = ['es', 'en'];
  static const _key = 'innova-carty-lang';
  static final ValueNotifier<String> lang = ValueNotifier('es');

  static bool get isSpanish => lang.value == 'es';

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && supported.contains(saved)) lang.value = saved;
    } catch (_) {
      // Keep Spanish.
    }
  }

  static Future<void> setLang(String value) async {
    if (!supported.contains(value)) return;
    lang.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }

  /// UI text by key with {placeholders}. Use context.tr() inside widgets so they rebuild.
  static String t(String key, [Map<String, Object?> params = const {}]) {
    var text = messages[lang.value]?[key] ?? messages['en']?[key] ?? key;
    params.forEach((name, value) => text = text.replaceAll('{$name}', '${value ?? ''}'));
    return text;
  }

  /// Text written by the API (events, alerts, zones) in the current language.
  static String server(String? text) => isSpanish ? translateServerText(text) : (text ?? '');
}

/// Rebuilds the widgets that read texts when the language changes.
class LangScope extends InheritedNotifier<ValueNotifier<String>> {
  LangScope({super.key, required super.child}) : super(notifier: I18n.lang);
}

extension I18nContext on BuildContext {
  String tr(String key, [Map<String, Object?> params = const {}]) {
    dependOnInheritedWidgetOfExactType<LangScope>();
    return I18n.t(key, params);
  }

  String st(String? text) {
    dependOnInheritedWidgetOfExactType<LangScope>();
    return I18n.server(text);
  }

  String get lang {
    dependOnInheritedWidgetOfExactType<LangScope>();
    return I18n.lang.value;
  }
}
