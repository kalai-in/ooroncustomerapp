class OrderDetailArgs {
  final String orderId;

  /// True when opened from the Ongoing tab/tracking flow — gates OTP
  /// visibility, since a completed order's OTP is no longer relevant.
  final bool isOngoing;

  const OrderDetailArgs({required this.orderId, this.isOngoing = false});
}

class EcommerceOrderDetailArgs {
  final String orderItemId;

  /// True when opened from the Ongoing tab/tracking flow — gates OTP
  /// visibility, since a completed order's OTP is no longer relevant.
  final bool isOngoing;

  const EcommerceOrderDetailArgs({
    required this.orderItemId,
    this.isOngoing = false,
  });
}

class OrderSuccessArgs {
  final String orderId;

  /// Ecommerce channel's item-level id, from the place-order/payment
  /// response — needed to route "Track My Order" to EcommerceOrderDetailArgs.
  final String orderItemId;

  const OrderSuccessArgs({required this.orderId, this.orderItemId = ''});
}
