import 'package:flutter/material.dart';

extension NullableStringExtension on String? {
  /// True for a non-null, non-empty string that isn't the literal 'null' —
  /// the API sometimes serializes a missing field as the string "null"
  /// instead of omitting it, so a plain null/empty check isn't enough.
  bool get hasValue => this != null && this!.isNotEmpty && this != 'null';
}

extension StringColorExtension on String? {
  /// Parses a hex color string (e.g. "#RRGGBB" or "RRGGBB"/"AARRGGBB") into
  /// a [Color]. Returns null for null/empty/unparsable input.
  Color? toColor() {
    final hex = this;
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse(
      cleaned.length == 6 ? 'FF$cleaned' : cleaned,
      radix: 16,
    );
    return value != null ? Color(value) : null;
  }
}
