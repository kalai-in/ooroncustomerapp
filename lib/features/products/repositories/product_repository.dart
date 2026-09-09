import 'package:dio/dio.dart';
import 'package:customer/core/api/api_client.dart';
import 'package:customer/core/api/api_endpoints.dart';
import 'package:customer/core/api/api_exception.dart';
import 'package:customer/core/api/api_parameters.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/features/products/models/filter_model.dart';
import 'package:customer/features/products/models/product_detail_model.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/features/products/models/product_rating_model.dart';
import 'package:customer/features/products/models/rating_images_model.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ProductModel> getProducts({
    required int offset,
    required int limit,
    String? categoryId,
    String? search,
    String? sort,
    double? minPrice,
    double? maxPrice,
    List<String>? brandIds,
    List<String>? attributeValueIds,
    String? dataSource,
    String? manualProductIds,
  }) async {
    try {
      final lat = SettingsHiveBox.instance.userLatitude;
      final lng = SettingsHiveBox.instance.userLongitude;
      // Home block data source: every source sends data_source; "category"
      // additionally sends category_id, "manual" additionally sends
      // manual_product_ids.
      final isManualSource = dataSource == 'manual';
      final params = <String, dynamic>{
        ApiParameters.offset: offset,
        ApiParameters.limit: limit,
        ApiParameters.latitude: lat,
        ApiParameters.longitude: lng,
        if (!isManualSource && categoryId != null && categoryId != '0')
          ApiParameters.categoryId: categoryId,
        if (dataSource != null && dataSource.isNotEmpty)
          ApiParameters.dataSource: dataSource,
        if (isManualSource &&
            manualProductIds != null &&
            manualProductIds.isNotEmpty)
          ApiParameters.manualProductIds: manualProductIds,
        if (search != null && search.isNotEmpty) ApiParameters.search: search,
        if (sort != null && sort.isNotEmpty) ApiParameters.sort: sort,
        ApiParameters.minPrice: ?minPrice,
        ApiParameters.maxPrice: ?maxPrice,
        if (brandIds != null && brandIds.isNotEmpty)
          ApiParameters.brandIds: brandIds.join(','),
        if (attributeValueIds != null && attributeValueIds.isNotEmpty)
          ApiParameters.attributeValues: attributeValueIds.join(','),
      };
      final response = await _apiClient.post(
        ApiEndpoints.products,
        queryParameters: params,
      );
      return ProductModel.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ProductModel> searchProducts({
    required int offset,
    required int limit,
    required String search,
    String? sort,
  }) async {
    try {
      final lat = SettingsHiveBox.instance.userLatitude;
      final lng = SettingsHiveBox.instance.userLongitude;
      final params = <String, dynamic>{
        ApiParameters.offset: offset,
        ApiParameters.limit: limit,
        ApiParameters.latitude: lat,
        ApiParameters.longitude: lng,
        ApiParameters.search: search,
        if (sort != null && sort.isNotEmpty) ApiParameters.sort: sort,
      };
      final response = await _apiClient.post(
        ApiEndpoints.products,
        queryParameters: params,
      );
      return ProductModel.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ProductModel> getSimilarProducts({
    required int offset,
    required int limit,
    String? isSimilarProductId,
  }) async {
    try {
      final lat = SettingsHiveBox.instance.userLatitude;
      final lng = SettingsHiveBox.instance.userLongitude;
      final params = <String, dynamic>{
        ApiParameters.offset: offset,
        ApiParameters.limit: limit,
        ApiParameters.latitude: lat,
        ApiParameters.longitude: lng,
        if (isSimilarProductId != null && isSimilarProductId.isNotEmpty)
          ApiParameters.isSimilarProductId: isSimilarProductId,
      };
      final response = await _apiClient.post(
        ApiEndpoints.products,
        queryParameters: params,
      );
      return ProductModel.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ProductModel> getRecentlyVisited({String? productId}) async {
    try {
      final lat = SettingsHiveBox.instance.userLatitude;
      final lng = SettingsHiveBox.instance.userLongitude;
      final params = <String, dynamic>{
        ApiParameters.productId: ?productId,
        ApiParameters.latitude: lat,
        ApiParameters.longitude: lng,
      };
      final response = await _apiClient.get(
        ApiEndpoints.recentlyVisited,
        queryParameters: params,
      );
      return ProductModel.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ProductDetailModel> getProductDetail({
    required String productId,
  }) async {
    try {
      final lat = SettingsHiveBox.instance.userLatitude;
      final lng = SettingsHiveBox.instance.userLongitude;
      // The identifier may be a numeric product id or a non-numeric slug.
      // Pass it as `id` when numeric, otherwise as `slug`.
      final isNumericId = int.tryParse(productId) != null;
      final params = <String, dynamic>{
        ApiParameters.latitude: lat,
        ApiParameters.longitude: lng,
        if (isNumericId) ApiParameters.id: productId,
        if (!isNumericId) ApiParameters.slug: productId,
      };
      final response = await _apiClient.post(
        ApiEndpoints.productDetail,
        queryParameters: params,
      );
      return ProductDetailModel.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<FilterModel> getFilters({
    String? categoryId,
    String? dataSource,
    String? manualProductIds,
  }) async {
    try {
      final lat = SettingsHiveBox.instance.userLatitude;
      final lng = SettingsHiveBox.instance.userLongitude;
      // category_id goes when there's no data_source (other screens) or
      // data_source is "category"; every source with a data_source also
      // sends it, with "manual" additionally sending manual_product_ids.
      final isCategorySource = dataSource == 'category';
      final isManualSource = dataSource == 'manual';
      final params = <String, dynamic>{
        ApiParameters.latitude: lat,
        ApiParameters.longitude: lng,
        if ((dataSource == null || dataSource.isEmpty || isCategorySource) &&
            categoryId != null &&
            categoryId != '0')
          ApiParameters.categoryId: categoryId,
        if (dataSource != null && dataSource.isNotEmpty)
          ApiParameters.dataSource: dataSource,
        if (isManualSource &&
            manualProductIds != null &&
            manualProductIds.isNotEmpty)
          ApiParameters.manualProductIds: manualProductIds,
      };
      final response = await _apiClient.post(
        ApiEndpoints.filters,
        queryParameters: params,
      );
      return FilterModel.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> addRecentlyVisitedProduct({required String productId}) async {
    try {
      final params = <String, dynamic>{ApiParameters.productId: productId};
      final response = await _apiClient.post(
        ApiEndpoints.addRecentlyVisitedProduct,
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

  Future<ProductRating> getRatingsList({
    required int offset,
    required int limit,
    required String productId,
  }) async {
    try {
      final params = <String, dynamic>{
        ApiParameters.offset: offset,
        ApiParameters.limit: limit,
        ApiParameters.productId: productId,
      };
      final response = await _apiClient.get(
        ApiEndpoints.ratingsList,
        queryParameters: params,
      );
      return ProductRating.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<({String message, Map<String, dynamic>? data})> addOrUpdateRating({
    String? productId,
    String? ratingId,
    required String rate,
    required String review,
    List<String>? imagePaths,
    List<String>? deleteImageIds,
  }) async {
    try {
      final fields = <String, dynamic>{
        ApiParameters.rate: rate,
        ApiParameters.review: review,
        ApiParameters.productId: ?productId,
        ApiParameters.id: ?ratingId,
        if (ratingId != null &&
            deleteImageIds != null &&
            deleteImageIds.isNotEmpty)
          ApiParameters.deleteImageIds: deleteImageIds.join(','),
      };

      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          fields['image[$i]'] = await MultipartFile.fromFile(
            imagePaths[i],
            filename: imagePaths[i].split('/').last,
          );
        }
      }

      final endpoint = ratingId != null
          ? ApiEndpoints.ratingUpdate
          : ApiEndpoints.ratingAdd;
      final response = await _apiClient.upload(
        endpoint,
        formData: FormData.fromMap(fields),
      );
      final map = response as Map<String, dynamic>;
      final rawData = map['data'];
      Map<String, dynamic>? data;
      if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else if (rawData is List &&
          rawData.isNotEmpty &&
          rawData.first is Map<String, dynamic>) {
        data = rawData.first as Map<String, dynamic>;
      }
      return (message: map['message']?.toString() ?? '', data: data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<RatingImages> getRatingImages({
    required int offset,
    required int limit,
    required String productId,
  }) async {
    try {
      final params = <String, dynamic>{
        ApiParameters.offset: offset,
        ApiParameters.limit: limit,
        ApiParameters.productId: productId,
      };
      final response = await _apiClient.post(
        ApiEndpoints.ratingImages,
        queryParameters: params,
      );
      return RatingImages.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
