import 'package:customer/core/localization/services/localization_service.dart';
import 'package:flutter/material.dart';

extension LocalizationExtensions on BuildContext {
  /// Translate [key] using API-fetched strings. Falls back to [fallback] or the key itself.
  String translate(String key, {String? fallback}) =>
      LocalizationService.instance.translate(key, fallback: fallback);
}
