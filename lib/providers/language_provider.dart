import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  Locale _locale = const Locale('en', '');

  LanguageProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLanguage = _prefs?.getString('language') ?? 'en';
    _locale = Locale(savedLanguage, '');
    notifyListeners();
  }

  Locale get locale => _locale;

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    _locale = newLocale;
    await _prefs?.setString('language', newLocale.languageCode);
    notifyListeners();
  }
}
