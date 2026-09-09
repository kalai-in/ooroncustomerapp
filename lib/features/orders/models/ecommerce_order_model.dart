import 'package:customer/commons/models/additional_charges_model.dart';
import 'package:customer/commons/models/surge_charges_model.dart';
import 'package:customer/features/orders/models/order_address_model.dart';
import 'package:customer/features/orders/models/order_model.dart'
    show ItemRating, VariantAttributes;
import 'package:customer/utils/json_parsers.dart';

class EcommerceOrderModel {
  int? status;
  String? message;
  List<EcommerceOrderDataModel>? data;
  int? total;

  EcommerceOrderModel({this.status, this.message, this.data, this.total});

  EcommerceOrderModel.fromJson(Map<String, dynamic> json) {
    status = parseInt(json['status']);
    message = parseString(json['message']);
    final rawData = json['data'];
    if (rawData is List) {
      data = rawData
          .map(
            (v) => EcommerceOrderDataModel.fromJson(v as Map<String, dynamic>),
          )
          .toList();
    }
    total = parseInt(json['total']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['total'] = total;
    return data;
  }
}

class EcommerceOrderDataModel {
  int? id;
  int? userId;
  int? orderId;
  String? orderNumber;
  String? productName;
  List<VariantAttributes>? variantAttributes;
  int? productVariantId;
  int? deliveryBoyId;
  DeliveryBoyBonusDetails? deliveryBoyBonusDetails;
  double? deliveryBoyBonusAmount;
  int? quantity;
  double? price;
  double? discountedPrice;
  double? taxAmount;
  double? taxPercentage;
  double? subTotal;
  double? deliveryCharge;
  List<AdditionalCharges>? additionalCharges;
  List<SurgeCharges>? surgeCharges;
  double? promoDiscount;
  double? walletBalance;
  double? finalTotal;
  double? refundAmount;
  int? activeStatus;
  String? cancellationReason;
  String? canceledAt;
  int? storeId;
  int? isCredited;
  String? channel;
  String? paymentMethod;
  String? currency;
  String? currencyCode;
  int? variantId;
  String? name;
  int? productId;
  String? image;
  String? returnRejectReason;
  String? returnReason;
  String? storeName;
  String? deliveryBoyName;
  String? deliveryBoyMobile;
  bool? isDeliveryBoyChatVisible;
  int? returnRequested;
  String? orderStatusName;
  bool? productRating;
  String? date;
  List<Timeline>? timeline;
  List<OtherItems>? otherItems;
  List<ItemRating>? itemRating;
  bool? isCancellable;
  bool? isReturnable;
  double? savedAmount;
  double? cashbackAmount;
  int? cashbackCredited;
  OrderAddressModel? address;
  int? returnDays;
  int? otp;
  String? courierAgency;
  String? trackingId;
  String? trackingUrl;
  String? orderItemStatus;
  String? prescriptionUrl;

  EcommerceOrderDataModel({
    this.id,
    this.userId,
    this.orderId,
    this.orderNumber,
    this.productName,
    this.variantAttributes,
    this.productVariantId,
    this.deliveryBoyId,
    this.deliveryBoyBonusDetails,
    this.deliveryBoyBonusAmount,
    this.quantity,
    this.price,
    this.discountedPrice,
    this.taxAmount,
    this.taxPercentage,
    this.subTotal,
    this.deliveryCharge,
    this.additionalCharges,
    this.surgeCharges,
    this.promoDiscount,
    this.walletBalance,
    this.finalTotal,
    this.refundAmount,
    this.activeStatus,
    this.cancellationReason,
    this.canceledAt,
    this.storeId,
    this.isCredited,
    this.channel,
    this.paymentMethod,
    this.currency,
    this.currencyCode,
    this.variantId,
    this.name,
    this.productId,
    this.image,
    this.returnRejectReason,
    this.returnReason,
    this.storeName,
    this.deliveryBoyName,
    this.deliveryBoyMobile,
    this.isDeliveryBoyChatVisible,
    this.returnRequested,
    this.orderStatusName,
    this.productRating,
    this.date,
    this.timeline,
    this.otherItems,
    this.itemRating,
    this.isCancellable,
    this.isReturnable,
    this.savedAmount,
    this.cashbackAmount,
    this.cashbackCredited,
    this.address,
    this.returnDays,
    this.otp,
    this.courierAgency,
    this.trackingId,
    this.trackingUrl,
    this.orderItemStatus,
    this.prescriptionUrl,
  });

  EcommerceOrderDataModel.fromJson(Map<String, dynamic> json) {
    id = parseInt(json['id']);
    userId = parseInt(json['user_id']);
    orderId = parseInt(json['order_id']);
    orderNumber = parseString(json['order_number']);
    productName = parseString(json['product_name']);
    final rawVariantAttributes = json['variant_attributes'];
    if (rawVariantAttributes is List) {
      variantAttributes = rawVariantAttributes
          .map((v) => VariantAttributes.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    productVariantId = parseInt(json['product_variant_id']);
    deliveryBoyId = parseInt(json['delivery_boy_id']);
    deliveryBoyBonusDetails =
        json['delivery_boy_bonus_details'] is Map<String, dynamic>
        ? DeliveryBoyBonusDetails.fromJson(
            json['delivery_boy_bonus_details'] as Map<String, dynamic>,
          )
        : null;
    deliveryBoyBonusAmount = parseDouble(json['delivery_boy_bonus_amount']);
    quantity = parseInt(json['quantity']);
    price = parseDouble(json['price']);
    discountedPrice = parseDouble(json['discounted_price']);
    taxAmount = parseDouble(json['tax_amount']);
    taxPercentage = parseDouble(json['tax_percentage']);
    subTotal = parseDouble(json['sub_total']);
    deliveryCharge = parseDouble(json['delivery_charge']);
    final rawAdditionalCharges = json['additional_charges'];
    if (rawAdditionalCharges is List) {
      additionalCharges = rawAdditionalCharges
          .map((v) => AdditionalCharges.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    final rawSurgeCharges = json['surge_charges'];
    if (rawSurgeCharges is List) {
      surgeCharges = rawSurgeCharges
          .map((v) => SurgeCharges.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    promoDiscount = parseDouble(json['promo_discount']);
    walletBalance = parseDouble(json['wallet_balance']);
    finalTotal = parseDouble(json['final_total']);
    refundAmount = parseDouble(json['refund_amount']);
    activeStatus = parseInt(json['active_status']);
    cancellationReason = parseString(json['cancellation_reason']);
    canceledAt = parseString(json['canceled_at']);
    storeId = parseInt(json['store_id']);
    isCredited = parseInt(json['is_credited']);
    channel = parseString(json['channel']);
    paymentMethod = parseString(json['payment_method']);
    currency = parseString(json['currency']);
    currencyCode = parseString(json['currency_code']);
    variantId = parseInt(json['variant_id']);
    name = parseString(json['name']);
    productId = parseInt(json['product_id']);
    image = parseString(json['image']);
    returnRejectReason = parseString(json['return_reject_reason']);
    returnReason = parseString(json['return_reason']);
    storeName = parseString(json['store_name']);
    deliveryBoyName = parseString(json['delivery_boy_name']);
    deliveryBoyMobile = parseString(json['delivery_boy_mobile']);
    isDeliveryBoyChatVisible =
        parseBool(json['is_delivery_boy_chat_visible']) ?? false;
    returnRequested = parseInt(json['return_requested']);
    orderStatusName = parseString(json['order_status_name']);
    productRating = parseBool(json['product_rating']);
    date = parseString(json['date']);
    final rawTimeline = json['timeline'];
    if (rawTimeline is List) {
      timeline = rawTimeline
          .map((v) => Timeline.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    final rawOtherItems = json['other_items'];
    if (rawOtherItems is List) {
      otherItems = rawOtherItems
          .map((v) => OtherItems.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    final rawItemRating = json['item_rating'];
    if (rawItemRating is List) {
      itemRating = rawItemRating
          .map((v) => ItemRating.fromJson(v as Map<String, dynamic>))
          .toList();
    }
    isCancellable = parseBool(json['is_cancellable']) ?? false;
    isReturnable = parseBool(json['is_returnable']) ?? false;
    savedAmount = parseDouble(json['saved_amount']);
    cashbackAmount = parseDouble(json['cashback_amount']);
    cashbackCredited = parseInt(json['cashback_credited']);
    address = json['address'] is Map<String, dynamic>
        ? OrderAddressModel.fromJson(json['address'] as Map<String, dynamic>)
        : null;
    returnDays = parseInt(json['return_days']);
    otp = parseInt(json['otp']);
    courierAgency = parseString(json['courier_agency']) ?? "";
    trackingId = parseString(json['tracking_id']) ?? "";
    trackingUrl = parseString(json['tracking_url']) ?? "";
    orderItemStatus = parseString(json['order_item_status']) ?? "";
    prescriptionUrl = parseString(json['prescription_url']) ?? "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['order_id'] = orderId;
    data['order_number'] = orderNumber;
    data['product_name'] = productName;
    if (variantAttributes != null) {
      data['variant_attributes'] = variantAttributes!
          .map((v) => v.toJson())
          .toList();
    }
    data['product_variant_id'] = productVariantId;
    data['delivery_boy_id'] = deliveryBoyId;
    if (deliveryBoyBonusDetails != null) {
      data['delivery_boy_bonus_details'] = deliveryBoyBonusDetails!.toJson();
    }
    data['delivery_boy_bonus_amount'] = deliveryBoyBonusAmount;
    data['quantity'] = quantity;
    data['price'] = price;
    data['discounted_price'] = discountedPrice;
    data['tax_amount'] = taxAmount;
    data['tax_percentage'] = taxPercentage;
    data['sub_total'] = subTotal;
    data['delivery_charge'] = deliveryCharge;
    if (additionalCharges != null) {
      data['additional_charges'] = additionalCharges!
          .map((v) => v.toJson())
          .toList();
    }
    if (surgeCharges != null) {
      data['surge_charges'] = surgeCharges!.map((v) => v.toJson()).toList();
    }
    data['promo_discount'] = promoDiscount;
    data['wallet_balance'] = walletBalance;
    data['final_total'] = finalTotal;
    data['refund_amount'] = refundAmount;
    data['active_status'] = activeStatus;
    data['cancellation_reason'] = cancellationReason;
    data['canceled_at'] = canceledAt;
    data['store_id'] = storeId;
    data['is_credited'] = isCredited;
    data['channel'] = channel;
    data['payment_method'] = paymentMethod;
    data['currency'] = currency;
    data['currency_code'] = currencyCode;
    data['variant_id'] = variantId;
    data['name'] = name;
    data['product_id'] = productId;
    data['image'] = image;
    data['return_reject_reason'] = returnRejectReason;
    data['return_reason'] = returnReason;
    data['store_name'] = storeName;
    data['delivery_boy_name'] = deliveryBoyName;
    data['delivery_boy_mobile'] = deliveryBoyMobile;
    data['is_delivery_boy_chat_visible'] = isDeliveryBoyChatVisible;
    data['return_requested'] = returnRequested;
    data['order_status_name'] = orderStatusName;
    data['product_rating'] = productRating;
    data['date'] = date;
    if (timeline != null) {
      data['timeline'] = timeline!.map((v) => v.toJson()).toList();
    }
    if (otherItems != null) {
      data['other_items'] = otherItems!.map((v) => v.toJson()).toList();
    }
    if (itemRating != null) {
      data['item_rating'] = itemRating!.map((v) => v.toJson()).toList();
    }
    data['is_cancellable'] = isCancellable;
    data['is_returnable'] = isReturnable;
    data['saved_amount'] = savedAmount;
    data['cashback_amount'] = cashbackAmount;
    data['cashback_credited'] = cashbackCredited;
    if (address != null) data['address'] = address!.toJson();
    data['return_days'] = returnDays;
    data['otp'] = otp;
    data['courier_agency'] = courierAgency;
    data['tracking_id'] = trackingId;
    data['tracking_url'] = trackingUrl;
    data['order_item_status'] = orderItemStatus;
    data['prescription_url'] = prescriptionUrl;
    return data;
  }
}

class DeliveryBoyBonusDetails {
  double? finalTotal;
  int? bonusType;
  String? bonusTypeName;
  double? bonusAmount;

  DeliveryBoyBonusDetails({
    this.finalTotal,
    this.bonusType,
    this.bonusTypeName,
    this.bonusAmount,
  });

  DeliveryBoyBonusDetails.fromJson(Map<String, dynamic> json) {
    finalTotal = parseDouble(json['final_total']);
    bonusType = parseInt(json['bonus_type']);
    bonusTypeName = parseString(json['bonus_type_name']);
    bonusAmount = parseDouble(json['bonus_amount']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['final_total'] = finalTotal;
    data['bonus_type'] = bonusType;
    data['bonus_type_name'] = bonusTypeName;
    data['bonus_amount'] = bonusAmount;
    return data;
  }
}

class Timeline {
  int? status;
  String? statusName;
  String? datetime;

  Timeline({this.status, this.statusName, this.datetime});

  Timeline.fromJson(Map<String, dynamic> json) {
    status = parseInt(json['status']);
    statusName = parseString(json['status_name']);
    datetime = parseString(json['datetime']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['status_name'] = statusName;
    data['datetime'] = datetime;
    return data;
  }
}

class OtherItems {
  int? orderItemId;
  String? productName;
  int? quantity;
  double? finalTotal;
  String? image;
  int? status;
  String? statusName;

  OtherItems({
    this.orderItemId,
    this.productName,
    this.quantity,
    this.finalTotal,
    this.image,
    this.status,
    this.statusName,
  });

  OtherItems.fromJson(Map<String, dynamic> json) {
    orderItemId = parseInt(json['order_item_id']);
    productName = parseString(json['product_name']);
    quantity = parseInt(json['quantity']);
    finalTotal = parseDouble(json['final_total']);
    image = parseString(json['image']);
    status = parseInt(json['status']);
    statusName = parseString(json['status_name']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_item_id'] = orderItemId;
    data['product_name'] = productName;
    data['quantity'] = quantity;
    data['final_total'] = finalTotal;
    data['image'] = image;
    data['status'] = status;
    data['status_name'] = statusName;
    return data;
  }
}
