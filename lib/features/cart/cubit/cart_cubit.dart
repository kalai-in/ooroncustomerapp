import 'package:customer/commons/utils/app_log.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/local_storage/auth_hive_box.dart';
import 'package:customer/core/local_storage/guest_cart_hive_box.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/features/cart/repositories/cart_repository.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartEntry {
  final String variantId;
  final double price;
  final int quantity;
  final String imageUrl;

  const CartEntry({
    required this.variantId,
    required this.price,
    required this.quantity,
    this.imageUrl = '',
  });

  CartEntry copyWith({int? quantity}) => CartEntry(
    variantId: variantId,
    price: price,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl,
  );
}

class CartState {
  final Map<String, CartEntry> entries;
  const CartState({this.entries = const {}});

  int get totalItems => entries.values.fold(0, (s, e) => s + e.quantity);
  double get totalPrice =>
      entries.values.fold(0.0, (s, e) => s + e.price * e.quantity);
  int countFor(String variantId) => entries[variantId]?.quantity ?? 0;

  /// Last 3 unique product image URLs for the floating cart bar preview.
  List<String> get previewImages => entries.values
      .map((e) => e.imageUrl)
      .where((url) => url.isNotEmpty)
      .toSet()
      .take(3)
      .toList();
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  bool get canAddMore {
    final limit = SettingsHiveBox.instance.maxCartItemsCount;
    return limit <= 0 || state.totalItems < limit;
  }

  void add(String variantId, double price, {String imageUrl = ''}) {
    final limit = SettingsHiveBox.instance.maxCartItemsCount;
    if (limit > 0 && state.totalItems >= limit) return;

    final map = Map<String, CartEntry>.from(state.entries);
    final current = map[variantId];
    map[variantId] = CartEntry(
      variantId: variantId,
      price: price,
      quantity: (current?.quantity ?? 0) + 1,
      imageUrl: current?.imageUrl.isNotEmpty == true
          ? current!.imageUrl
          : imageUrl,
    );
    emit(CartState(entries: map));
    _persistGuestCart(map);
  }

  int _loadGeneration = 0;

  Future<void> loadFromApi() async {
    final generation = ++_loadGeneration;
    try {
      final cart = await CartRepository().getCart();
      // Discard stale response: a newer loadFromApi (e.g. from a channel
      // switch) started after this one and must win, regardless of which
      // network call actually resolves first.
      if (generation != _loadGeneration) return;
      final items = cart.data?.cart;
      seedFromApi(items ?? []);
    } catch (e) {
      logDebug('CartCubit.loadFromApi error: $e');
    }
  }

  void seedFromApi(List<ProductDataModel> items) {
    final channel = SettingsHiveBox.instance.channel;
    final map = <String, CartEntry>{};
    for (final item in items) {
      // Backend's /cart response is not reliably channel-scoped — drop
      // items belonging to the other channel so a mixed list never leaks
      // into the currently displayed channel's cart.
      if (item.salesChannel != null &&
          item.salesChannel != channel &&
          item.salesChannel != AppConstants.both) {
        continue;
      }
      final id =
          (item.variantId?.toString().isNotEmpty == true
              ? item.variantId.toString()
              : item.variants?.isNotEmpty == true
              ? item.variants!.first.id?.toString()
              : null) ??
          '';
      if (id.isEmpty) continue;
      final qty = item.variants?.isNotEmpty == true
          ? (item.variants!.first.quantity ?? 0)
          : 0;
      if (qty <= 0) continue;
      map[id] = CartEntry(
        variantId: id,
        price: (item.discountedPrice != null && item.discountedPrice! > 0)
            ? item.discountedPrice!
            : (item.price ?? 0),
        quantity: qty,
        imageUrl: item.variants?.isNotEmpty == true
            ? (item.variants!.first.image ?? item.images?.first.imageUrl ?? '')
            : (item.images?.first.imageUrl ?? ''),
      );
    }
    emit(CartState(entries: map));
  }

  void clear() {
    GuestCartHiveBox.instance.clearChannel(SettingsHiveBox.instance.channel);
    emit(const CartState());
  }

  /// Clears guest cart for ALL channels (called after login sync).
  void clearAllGuestData() {
    GuestCartHiveBox.instance.clearAll();
    emit(const CartState());
  }

  /// Switch displayed cart when user toggles quick ↔ ecommerce on home screen.
  /// No-op for logged-in users (server handles their cart via [loadFromApi]).
  void switchChannel(String channel) {
    if (AuthHiveBox.instance.isLoggedIn) return;
    final map = _loadEntriesFromHive(channel);
    emit(CartState(entries: map));
  }

  /// Drops the currently displayed cart without touching persisted storage.
  /// Call right after a channel switch for logged-in users so the old
  /// channel's items don't linger on screen while [loadFromApi] is in flight.
  void resetForChannelSwitch() => emit(const CartState());

  /// Force a variant's quantity to an exact value (used to revert an
  /// optimistic add/remove when the server sync call fails).
  void setQuantity(
    String variantId,
    double price,
    int quantity, {
    String imageUrl = '',
  }) {
    final map = Map<String, CartEntry>.from(state.entries);
    if (quantity <= 0) {
      map.remove(variantId);
    } else {
      final current = map[variantId];
      map[variantId] = CartEntry(
        variantId: variantId,
        price: price,
        quantity: quantity,
        imageUrl: current?.imageUrl.isNotEmpty == true
            ? current!.imageUrl
            : imageUrl,
      );
    }
    emit(CartState(entries: map));
    _persistGuestCart(map);
  }

  void remove(String variantId, double price) {
    final map = Map<String, CartEntry>.from(state.entries);
    final current = map[variantId];
    if (current == null) return;
    final newQty = current.quantity - 1;
    if (newQty <= 0) {
      map.remove(variantId);
    } else {
      map[variantId] = current.copyWith(quantity: newQty);
    }
    emit(CartState(entries: map));
    _persistGuestCart(map);
  }

  /// Drops the entire line item, regardless of its current quantity.
  void removeAll(String variantId) {
    final map = Map<String, CartEntry>.from(state.entries);
    if (map.remove(variantId) == null) return;
    emit(CartState(entries: map));
    _persistGuestCart(map);
  }

  /// Load guest cart from Hive on app start when user is not logged in.
  void loadGuestCartFromHive() {
    final map = _loadEntriesFromHive(SettingsHiveBox.instance.channel);
    if (map.isNotEmpty) emit(CartState(entries: map));
  }

  Map<String, CartEntry> _loadEntriesFromHive(String channel) {
    final raw = GuestCartHiveBox.instance.loadEntries(channel);
    if (raw.isEmpty) return {};
    final map = <String, CartEntry>{};
    for (final entry in raw.entries) {
      final v = entry.value;
      map[entry.key] = CartEntry(
        variantId: v['variantId'] as String? ?? entry.key,
        price: (v['price'] as num?)?.toDouble() ?? 0.0,
        quantity: v['quantity'] as int? ?? 1,
        imageUrl: v['imageUrl'] as String? ?? '',
      );
    }
    return map;
  }

  void _persistGuestCart(Map<String, CartEntry> entries) {
    if (AuthHiveBox.instance.isLoggedIn) return;
    final raw = entries.map(
      (k, e) => MapEntry(k, {
        'variantId': e.variantId,
        'price': e.price,
        'quantity': e.quantity,
        'imageUrl': e.imageUrl,
      }),
    );
    GuestCartHiveBox.instance.saveEntries(
      raw,
      SettingsHiveBox.instance.channel,
    );
  }
}
