import 'dart:convert';
import 'package:customer/core/constants/app_constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/hive_box_keys.dart';

class GuestCartHiveBox {
  GuestCartHiveBox._();
  static final GuestCartHiveBox instance = GuestCartHiveBox._();

  Box get _box => Hive.box(guestCartBox);

  String _key(String channel) => channel == 'ecommerce'
      ? kEcommerceCartEntriesJson
      : kQuickCartEntriesJson;

  Map<String, Map<String, dynamic>> loadEntries(String channel) {
    final raw = _box.get(_key(channel)) as String?;
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveEntries(Map<String, dynamic> entries, String channel) async {
    await _box.put(_key(channel), jsonEncode(entries));
  }

  Future<void> clearChannel(String channel) async {
    await _box.delete(_key(channel));
  }

  Future<void> clearAll() async {
    await _box.deleteAll([kQuickCartEntriesJson, kEcommerceCartEntriesJson]);
  }

  /// Merges quick + ecommerce entries for bulk sync on login.
  /// Duplicate variantIds sum their quantities.
  Map<String, int> loadAllEntriesCombined() {
    final combined = <String, int>{};
    for (final ch in [AppConstants.quick, AppConstants.ecommerce]) {
      for (final e in loadEntries(ch).values) {
        final id = e['variantId'] as String? ?? '';
        if (id.isEmpty) continue;
        combined[id] = (combined[id] ?? 0) + (e['quantity'] as int? ?? 0);
      }
    }
    return combined;
  }

  bool isEmptyFor(String channel) => loadEntries(channel).isEmpty;
}
