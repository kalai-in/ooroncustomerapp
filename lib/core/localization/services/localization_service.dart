import 'dart:convert';
import 'package:flutter/services.dart';

class LocalizationService {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  static const _assetPath = 'assets/languages/en.json';

  /// Local en.json — always loaded first as a base, so any key missing from
  /// the server response still resolves instead of falling back to the raw key.
  Map<String, String> _assetTranslations = {};
  Map<String, String> _translations = {};

  /// Server data overlays on top of the local asset base — missing keys in
  /// the server response keep their local fallback instead of disappearing.
  void load(Map<dynamic, dynamic> data) {
    final merged = Map<String, String>.from(_assetTranslations);
    data.forEach((k, v) {
      final value = v?.toString() ?? '';
      if (value.isNotEmpty) merged[k.toString()] = value;
    });
    _translations = merged;
  }

  Future<void> loadFromAssets() async {
    final raw = await rootBundle.loadString(_assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _assetTranslations = map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    _translations = Map.from(_assetTranslations);
  }

  void clear() => _translations = {};

  bool get hasTranslations => _translations.isNotEmpty;

  String translate(String key, {String? fallback}) {
    final val = _translations[key];
    if (val != null && val.isNotEmpty) return val;
    return fallback ?? key;
  }
}
