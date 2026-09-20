import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/address/cubit/address_cubit.dart';
import 'package:customer/features/address/models/address_model.dart';
import 'package:customer/features/cart/cubit/cart_fetch_cubit.dart';
import 'package:customer/features/cart/models/cart_model.dart';
import 'package:customer/features/checkout/cubit/place_order_cubit.dart';
import 'package:customer/features/checkout/models/billing_address_model.dart';
import 'package:customer/features/checkout/widgets/checkout_bill_section.dart';
import 'package:customer/features/checkout/widgets/checkout_cart_items_section.dart';
import 'package:customer/features/checkout/widgets/checkout_order_note_section.dart';
import 'package:customer/features/checkout/widgets/checkout_place_order_bar.dart';
import 'package:customer/features/checkout/widgets/checkout_promo_section.dart';
import 'package:customer/features/checkout/widgets/checkout_recommendations_section.dart';
import 'package:customer/features/checkout/widgets/checkout_wallet_section.dart';
import 'package:customer/features/checkout/utils/checkout_totals.dart';
import 'package:customer/features/payment_method/cubit/payment_cubit.dart';
import 'package:customer/features/payment_method/cubit/payment_methods_cubit.dart';
import 'package:customer/features/payment_method/models/payment_method_item.dart';
import 'package:customer/features/promo_code/models/promo_code_model.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'dart:io';
import 'package:customer/features/checkout/utils/checkout_variant_id.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The logged-in checkout body: item list, promo/wallet/note sections, bill
/// summary and the sticky place-order bar. Rendered once [CartFetchLoaded]
/// resolves with a non-empty cart.
class CheckoutLoadedBody extends StatelessWidget {
  const CheckoutLoadedBody({
    super.key,
    required this.cartData,
    required this.currency,
    required this.addressLat,
    required this.addressLng,
    required this.appliedPromo,
    required this.useWallet,
    required this.selectedAddress,
    required this.selectedPayment,
    required this.onRemovePromo,
    required this.onBrowseCodes,
    required this.onWalletToggle,
    required this.onNoteChanged,
    required this.onPlaceOrder,
    required this.onChooseAddress,
    required this.onChoosePayment,
    required this.billingSameAsShipping,
    required this.billingAddress,
    required this.onBillingToggle,
    required this.onEditBillingAddress,
    this.prescriptions = const {},
    this.onPrescriptionPicked,
    this.onPrescriptionRemoved,
    this.prescriptionKeyOf,
    this.onUploadPrescriptionRequested,
  });

  final CartData cartData;
  final String currency;
  final String addressLat;
  final String addressLng;
  final PromoCodeData? appliedPromo;
  final bool useWallet;
  final AddressData? selectedAddress;
  final PaymentMethodItem? selectedPayment;
  final VoidCallback onRemovePromo;
  final ValueChanged<String> onBrowseCodes;
  final ValueChanged<bool> onWalletToggle;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onPlaceOrder;
  final VoidCallback onChooseAddress;
  final ValueChanged<bool> onChoosePayment;
  final bool billingSameAsShipping;
  final BillingAddressData? billingAddress;
  final ValueChanged<bool> onBillingToggle;
  final VoidCallback onEditBillingAddress;

  /// Picked prescription files keyed by product variant id (medical products).
  final Map<String, File> prescriptions;
  final void Function(String variantId, File file)? onPrescriptionPicked;
  final void Function(String variantId)? onPrescriptionRemoved;

  /// Returns the scroll-target key for a variant's prescription tile.
  final GlobalKey Function(String variantId)? prescriptionKeyOf;

  /// Called with the variant id to scroll to when the "Upload Prescription"
  /// CTA is tapped.
  final ValueChanged<String>? onUploadPrescriptionRequested;

  /// Variant id of the first medical item still missing its mandatory
  /// prescription upload, or null if none is missing.
  String? get _firstMissingRequiredVariantId {
    for (final item in cartData.cart ?? <ProductDataModel>[]) {
      if (!item.requiresPrescription) continue;
      final variantId = resolveCheckoutVariantId(item);
      if (prescriptions[variantId] == null) return variantId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Not-deliverable only applies once an address is actually selected: with
    // no address the user must pick one first (the place-order bar shows the
    // "choose address" prompt), so sections stay visible until then.
    final notDeliverable =
        selectedAddress != null && cartData.isDeliverableAddress == 0;
    return BlocSelector<PlaceOrderCubit, PlaceOrderState, bool>(
      selector: (s) => s is PlaceOrderLoading,
      builder: (context, isPlacing) {
        // Gateway attempt (initiate_transaction + SDK/webview launch) runs
        // straight off this screen once the order is placed — keep the
        // button loading through that too, not just order creation.
        final isPaying =
            context.watch<PaymentCubit>().state is PaymentProcessing;
        final loading = isPlacing || isPaying;
        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: context.cs.primary,
                onRefresh: () async {
                  final addressCubit = context.read<AddressCubit>();
                  final paymentCubit = context.read<PaymentMethodsCubit>();
                  await context.read<CartFetchCubit>().fetchCart(
                    latitude: addressLat,
                    longitude: addressLng,
                    addressId: selectedAddress?.id,
                  );
                  addressCubit.refresh();
                  paymentCubit.loadPaymentMethods();
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingM, ThemeConstants.paddingL, 0),
                  children: [
                    CheckoutCartItemsSection(
                      cartData: cartData,
                      currency: currency,
                      prescriptions: prescriptions,
                      onPrescriptionPicked: onPrescriptionPicked,
                      onPrescriptionRemoved: onPrescriptionRemoved,
                      prescriptionKeyOf: prescriptionKeyOf,
                    ),
                    AppSpacing.h12,
                    // Delivery isn't available for the selected address
                    // (is_deliverable_address == 0): the place-order bar
                    // already surfaces the notice next to the address strip
                    // — hide promo / wallet / note / bill here, none apply
                    // until a serviceable address is picked.
                    if (notDeliverable)
                      const SizedBox.shrink()
                    else ...[
                      const CheckoutRecommendationsSection(),
                      CheckoutPromoSection(
                        appliedPromo: appliedPromo,
                        onRemove: onRemovePromo,
                        onBrowseCodes: () =>
                            onBrowseCodes((cartData.subTotal ?? 0).toString()),
                        unlockMessage: cartData.unlockMessage,
                        unlockPromoCode: cartData.unlockPromoCode,
                      ),
                      AppSpacing.h12,
                      if (cartData.userBalance != null &&
                          (cartData.userBalance ?? 0.0) > 0)
                        CheckoutWalletSection(
                          walletBalance: cartData.userBalance ?? 0.0,
                          // Post-promo total, same figure the place-order bar
                          // and payload actually charge against — otherwise a
                          // percentage promo makes this section's "wallet
                          // used" disagree with what's really deducted.
                          orderAmount: resolveCheckoutPostPromoTotal(
                            cartData: cartData,
                            appliedPromo: appliedPromo,
                          ),
                          currency: currency,
                          isWalletSelected: useWallet,
                          onWalletToggle: onWalletToggle,
                        ),
                      if (cartData.userBalance != null &&
                          (cartData.userBalance ?? 0) > 0)
                        AppSpacing.h12,
                      if (SettingsHiveBox.instance.channel ==
                          AppConstants.quick) ...[
                        CheckoutOrderNoteSection(onNoteChanged: onNoteChanged),
                        AppSpacing.h12,
                      ],
                      CheckoutBillDetailsSection(
                        cartData: cartData,
                        currency: currency,
                        appliedPromo: appliedPromo,
                        useWallet: useWallet,
                      ),
                    ],
                    AppSpacing.h100,
                  ],
                ),
              ),
            ),
            CheckoutPlaceOrderBar(
              cartData: cartData,
              currency: currency,
              isLoading: loading,
              selectedAddress: selectedAddress,
              selectedPayment: selectedPayment,
              useWallet: useWallet,
              appliedPromo: appliedPromo,
              onPlaceOrder: onPlaceOrder,
              onChooseAddress: onChooseAddress,
              onChoosePayment: () => onChoosePayment(cartData.codAllowed == 1),
              billingSameAsShipping: billingSameAsShipping,
              billingAddress: billingAddress,
              onBillingToggle: onBillingToggle,
              onEditBillingAddress: onEditBillingAddress,
              hasMissingRequiredPrescription:
                  !notDeliverable && _firstMissingRequiredVariantId != null,
              onUploadPrescription: () {
                final variantId = _firstMissingRequiredVariantId;
                if (variantId != null) {
                  onUploadPrescriptionRequested?.call(variantId);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
