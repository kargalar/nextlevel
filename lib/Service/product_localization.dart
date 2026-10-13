import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/locales_enum.dart';

@immutable

/// Product localization manager
final class ProductLocalization extends EasyLocalization {
  /// ProductLocalization need to [child] for a wrap locale item
  ProductLocalization({
    required super.child,
    super.startLocale,
    super.key,
  }) : super(
          supportedLocales: _supportedItems,
          path: _translationPath,
          useOnlyLangCode: true,
          fallbackLocale: Locales.en.locale,
        );

  static final List<Locale> _supportedItems = [
    Locales.en.locale,
  ];

  static const String _translationPath = 'assets/translations';

  /// Keeps the product interface in English on every device.
  static Future<Locale?> loadSelectedLanguage() async {
    return Locales.en.locale;
  }
}
