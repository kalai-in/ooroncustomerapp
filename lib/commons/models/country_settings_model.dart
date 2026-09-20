import 'package:customer/utils/json_parsers.dart';

class CountrySettings {
  int? status;
  String? message;
  CountrySettingsData? data;

  CountrySettings({this.status, this.message, this.data});

  CountrySettings.fromJson(Map<String, dynamic> json) {
    status = parseInt(json['status']) ?? 0;
    message = parseString(json['message']) ?? "";
    data = json['data'] is Map<String, dynamic>
        ? CountrySettingsData.fromJson(json['data'] as Map<String, dynamic>)
        : null;
  }
}

class CountrySettingsData {
  num? referralMinOrderAmount;
  num? referralCreditFirstOrder;
  num? referralCreditReferred;
  String? dateFormat;
  String? timeFormat;
  String? currency;
  String? currencyCode;
  int? decimalPoint;
  String? privacyPolicy;
  String? returnPolicy;
  String? shippingPolicy;
  String? cancellationPolicy;
  String? termsConditions;

  CountrySettingsData({
    this.referralMinOrderAmount,
    this.referralCreditFirstOrder,
    this.referralCreditReferred,
    this.dateFormat,
    this.timeFormat,
    this.currency,
    this.currencyCode,
    this.decimalPoint,
    this.privacyPolicy,
    this.returnPolicy,
    this.shippingPolicy,
    this.cancellationPolicy,
    this.termsConditions,
  });

  CountrySettingsData.fromJson(Map<String, dynamic> json) {
    referralMinOrderAmount = parseNum(json['referral_min_order_amount']);
    referralCreditFirstOrder = parseNum(json['referral_credit_first_order']);
    referralCreditReferred = parseNum(json['referral_credit_referred']);
    dateFormat = json['date_format']?.toString();
    timeFormat = json['time_format']?.toString();
    currency = json['currency']?.toString();
    currencyCode = json['currency_code']?.toString();
    decimalPoint = parseInt(json['decimal_point']);
    privacyPolicy = json['privacy_policy']?.toString();
    returnPolicy = json['return_policy']?.toString();
    shippingPolicy = json['shipping_policy']?.toString();
    cancellationPolicy = json['cancellation_policy']?.toString();
    termsConditions = json['terms_conditions']?.toString();
  }
}
