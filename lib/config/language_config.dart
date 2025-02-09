import 'package:flutter/material.dart';

class LanguageConfig {
  static const supportedLocales = [
    Locale('en', 'US'), // English
    Locale('ar', 'SA'), // Arabic
    // Add more locales as needed
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'العربية',
    // Add more languages as needed
  };
}
