import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, dynamic>? _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  Future<void> load() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/${locale.languageCode}.json',
      );
      _localizedStrings = json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading translations: $e');
    }
  }

  String? translate(String key) => _localizedStrings?[key];

  static const delegate = _AppLocalizationsDelegate();
  static const supportedLocales = [
    Locale('en', ''),
    Locale('ar', ''),
  ];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
