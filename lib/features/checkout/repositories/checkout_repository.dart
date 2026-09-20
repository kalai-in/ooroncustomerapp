import 'package:dio/dio.dart';
import 'package:customer/core/api/api_client.dart';
import 'package:customer/core/api/api_endpoints.dart';
import 'package:customer/core/api/api_exception.dart';
import 'package:customer/core/api/api_parameters.dart';

class CheckoutRepository {
  final ApiClient _apiClient;

  CheckoutRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? promoCodeId,
    String? walletUsed,
    String? walletBalance,
    String? orderNote,
    Map<String, String>? prescriptions,
    required bool billingSameAsShipping,
    String? billingName,
    String? billingMobile,
    String? billingAddress,
    String? billingCity,
    String? billingPincode,
    String? billingCountry,
    String? billingState,
    int? billingRegionId,
  }) async {
    try {
      final data = <String, dynamic>{
        ApiParameters.addressId: addressId,
        ApiParameters.paymentMethod: paymentMethod,
        if (promoCodeId != null && promoCodeId != '0')
          ApiParameters.promoCodeId: promoCodeId,
        if (walletUsed != null && walletUsed != '0')
          ApiParameters.walletUsed: walletUsed,
        if (walletBalance != null && (double.tryParse(walletBalance) ?? 0) != 0)
          ApiParameters.walletBalance: walletBalance,
        if (orderNote != null && orderNote.isNotEmpty)
          ApiParameters.orderNote: orderNote,
        ApiParameters.billingSameAsShipping: billingSameAsShipping ? '1' : '0',
        if (!billingSameAsShipping) ...{
          ApiParameters.billingName: billingName ?? '',
          ApiParameters.billingMobile: billingMobile ?? '',
          ApiParameters.billingAddress: billingAddress ?? '',
          ApiParameters.billingCity: billingCity ?? '',
          ApiParameters.billingPincode: billingPincode ?? '',
          ApiParameters.billingCountry: billingCountry ?? '',
          ApiParameters.billingState: billingState ?? '',
          ApiParameters.billingRegionId: (billingRegionId ?? '').toString(),
        },
      };

      // With prescription files attached, switch to multipart. Each file is
      // keyed by its product variant id — `prescription[<variant_id>]`.
      if (prescriptions != null && prescriptions.isNotEmpty) {
        for (final entry in prescriptions.entries) {
          data['${ApiParameters.prescription}[${entry.key}]'] =
              await MultipartFile.fromFile(
                entry.value,
                filename: entry.value.split('/').last,
              );
        }
        final response = await _apiClient.upload(
          ApiEndpoints.placeOrder,
          formData: FormData.fromMap(data),
        );
        return response as Map<String, dynamic>;
      }

      final response = await _apiClient.post(
        ApiEndpoints.placeOrder,
        data: data,
      );
      return response as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
