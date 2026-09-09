import 'package:customer/core/api/api_client.dart';
import 'package:customer/core/api/api_endpoints.dart';
import 'package:customer/core/api/api_exception.dart';
import 'package:customer/core/api/api_parameters.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/features/cart/models/cart_model.dart';
import 'package:customer/features/cart/models/cart_recommendations_model.dart';

class CartRepository {
  final ApiClient _apiClient;

  CartRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Cart> getCart({String? latitude, String? longitude}) async {
    try {
      final lat = latitude ?? SettingsHiveBox.instance.userLatitude;
      final lng = longitude ?? SettingsHiveBox.instance.userLongitude;
      final params = <String, dynamic>{
        ApiParameters.latitude: lat,
        ApiParameters.longitude: lng,
      };
      final response = await _apiClient.get(
        ApiEndpoints.cart,
        queryParameters: params,
      );
      return Cart.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Guest cart — items stored locally; send variant_ids + quantities to get server pricing.
  /// [variantIds] and [quantities] are parallel lists (index 0 matches index 0).
  Future<Cart> getGuestCart({
    required List<String> variantIds,
    required List<String> quantities,
  }) async {
    try {
      final lat = SettingsHiveBox.instance.userLatitude;
      final lng = SettingsHiveBox.instance.userLongitude;
      final params = <String, dynamic>{
        ApiParameters.latitude: lat,
        ApiParameters.longitude: lng,
        ApiParameters.variantIds: variantIds.join(','),
        ApiParameters.quantities: quantities.join(','),
      };
      final response = await _apiClient.get(
        ApiEndpoints.guestCart,
        queryParameters: params,
      );
      return Cart.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Returns the full cart payload (same shape as [getCart]) so callers can
  /// update state from the response without a separate get_cart call.
  Future<Cart> addToCart({
    required String productId,
    required String productVariantId,
    required int qty,
  }) async {
    try {
      final hive = SettingsHiveBox.instance;
      final params = <String, dynamic>{
        ApiParameters.productId: productId,
        ApiParameters.productVariantId: productVariantId,
        ApiParameters.qty: qty,
        ApiParameters.latitude: hive.userLatitude,
        ApiParameters.longitude: hive.userLongitude,
      };
      final response = await _apiClient.post(
        ApiEndpoints.cartAdd,
        queryParameters: params,
      );
      return Cart.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Pass qty > 0 to update, qty = 0 to remove that item.
  /// Returns the full cart payload (same shape as [getCart]).
  Future<Cart> removeFromCart({
    required String productId,
    required String productVariantId,
    int qty = 0,
  }) async {
    try {
      final hive = SettingsHiveBox.instance;
      final params = <String, dynamic>{
        ApiParameters.productId: productId,
        ApiParameters.productVariantId: productVariantId,
        ApiParameters.qty: qty,
        ApiParameters.latitude: hive.userLatitude,
        ApiParameters.longitude: hive.userLongitude,
      };
      final response = await _apiClient.post(
        ApiEndpoints.cartRemove,
        queryParameters: params,
      );
      return Cart.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> clearCart() async {
    try {
      final params = <String, dynamic>{ApiParameters.isRemoveAll: '1'};
      final response = await _apiClient.post(
        ApiEndpoints.cartRemove,
        queryParameters: params,
      );
      final map = response as Map<String, dynamic>;
      return map['message']?.toString() ?? '';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CartRecommendations> getCartRecommendations({
    String? latitude,
    String? longitude,
    String? productId,
    int crossSellLimit = 10,
    int crossSellOffset = 1,
    int upsellLimit = 10,
    int upsellOffset = 1,
  }) async {
    try {
      final hive = SettingsHiveBox.instance;
      final params = <String, dynamic>{
        ApiParameters.latitude: latitude ?? hive.userLatitude,
        ApiParameters.longitude: longitude ?? hive.userLongitude,
        ApiParameters.crossSellLimit: crossSellLimit,
        ApiParameters.crossSellOffset: crossSellOffset,
        ApiParameters.upsellLimit: upsellLimit,
        ApiParameters.upsellOffset: upsellOffset,
        ApiParameters.productId: ?productId,
      };
      final response = await _apiClient.get(
        ApiEndpoints.cartRecommendations,
        queryParameters: params,
      );
      return CartRecommendations.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Merge guest cart into authenticated cart after login.
  /// [variantIds] and [quantities] are parallel lists from local guest cart state.
  Future<String> bulkAddToCart({
    required List<String> quickVariantIds,
    required List<String> quickQuantities,
    required List<String> ecommerceVariantIds,
    required List<String> ecommerceQuantities,
  }) async {
    try {
      final hive = SettingsHiveBox.instance;
      final params = <String, dynamic>{
        ApiParameters.quickVariantIds: quickVariantIds.join(','),
        ApiParameters.quickQuantities: quickQuantities.join(','),
        ApiParameters.ecommerceVariantIds: ecommerceVariantIds.join(','),
        ApiParameters.ecommerceQuantities: ecommerceQuantities.join(','),
        ApiParameters.latitude: hive.userLatitude,
        ApiParameters.longitude: hive.userLongitude,
      };
      final response = await _apiClient.post(
        ApiEndpoints.guestCartBulkAddToCartWhileLogin,
        queryParameters: params,
      );
      final map = response as Map<String, dynamic>;
      return map['message']?.toString() ?? '';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
