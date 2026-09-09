import 'package:customer/features/cart/models/cart_model.dart';
import 'package:customer/features/promo_code/models/enums/promo_discount_type.dart';
import 'package:customer/features/promo_code/models/promo_code_model.dart';

/// Post-promo payable total. A flat promo is credited as wallet cashback
/// after delivery rather than subtracted here, a percentage promo is —
/// mirrors `CheckoutBillDetailsSection`'s `_PromoTotals`. Every screen/widget
/// computing what's actually charged (place-order payload, payment-method
/// gating, the sticky bar's displayed total) must derive it from here so the
/// displayed total and the amount actually sent to the gateway can't drift.
double resolveCheckoutPostPromoTotal({
  required CartData cartData,
  PromoCodeData? appliedPromo,
}) {
  final orderAmount = cartData.totalAmount ?? 0.0;
  final promo = appliedPromo;
  if (promo == null) return orderAmount;
  if (promo.discountTypeEnum == PromoDiscountType.flat) return orderAmount;
  return orderAmount - promo.discount;
}

/// True when the wallet balance alone covers [postPromoTotal] and the user
/// has opted to use it — no separate payment method is needed.
bool resolveCheckoutWalletCoversFull({
  required CartData cartData,
  required bool useWallet,
  required double postPromoTotal,
}) => useWallet && (cartData.userBalance ?? 0.0) >= postPromoTotal;

/// Portion of [postPromoTotal] paid from the wallet — capped at the
/// available balance so any remainder still goes through the selected
/// payment method.
double resolveCheckoutWalletAmountUsed({
  required CartData cartData,
  required bool useWallet,
  required double postPromoTotal,
}) {
  if (!useWallet) return 0.0;
  final balance = cartData.userBalance ?? 0.0;
  if (balance <= 0) return 0.0;
  return balance >= postPromoTotal ? postPromoTotal : balance;
}
