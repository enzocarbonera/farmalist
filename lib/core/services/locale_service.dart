import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  spanish,
  portugueseBrazil,
}

class LocaleService extends ChangeNotifier {
  LocaleService._();

  static final LocaleService instance = LocaleService._();
  static const _storageKey = 'app_language';

  AppLanguage _language = AppLanguage.spanish;

  AppLanguage get language => _language;
  String get analysisLanguageCode =>
      _language == AppLanguage.portugueseBrazil ? 'pt' : 'es';

  Future<void> init() async {
    final preferences = await SharedPreferences.getInstance();
    final savedLanguage = preferences.getString(_storageKey);
    _language = _languageFromCode(savedLanguage) ?? AppLanguage.spanish;
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }

    _language = language;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, _codeForLanguage(language));
  }

  static String _codeForLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.portugueseBrazil:
        return 'pt-BR';
    }
  }

  static AppLanguage? _languageFromCode(String? code) {
    switch (code) {
      case 'es':
        return AppLanguage.spanish;
      case 'pt-BR':
        return AppLanguage.portugueseBrazil;
      default:
        return null;
    }
  }
}

class LocaleScope extends InheritedNotifier<LocaleService> {
  const LocaleScope({
    super.key,
    required LocaleService notifier,
    required super.child,
  }) : super(notifier: notifier);

  static LocaleService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found in widget tree');
    return scope!.notifier!;
  }
}
