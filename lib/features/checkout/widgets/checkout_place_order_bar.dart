import 'package:customer/commons/widgets/app_button.dart';
import 'package:customer/commons/widgets/loading_widget.dart';
import 'package:customer/commons/widgets/shimmer_builder.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/address/models/address_model.dart';
import 'package:customer/features/cart/models/cart_model.dart';
import 'package:customer/features/checkout/utils/checkout_totals.dart';
import 'package:customer/features/payment_method/models/payment_method_item.dart';
import 'package:customer/features/promo_code/models/promo_code_model.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

class CheckoutPlaceOrderBar extends StatelessWidget {
  const CheckoutPlaceOrderBar({
    super.key,
    required this.cartData,
    required this.currency,
    required this.isLoading,
    required this.selectedAddress,
    required this.selectedPayment,
    required this.onPlaceOrder,
    required this.onChooseAddress,
    required this.onChoosePayment,
    this.isLoggedIn = true,
    this.onLoginAndCheckout,
    this.useWallet = false,
    this.appliedPromo,
    this.hasMissingRequiredPrescription = false,
    this.onUploadPrescription,
  });

  final CartData cartData;
  final String currency;
  final bool isLoading;
  final AddressData? selectedAddress;
  final PaymentMethodItem? selectedPayment;
  final VoidCallback onPlaceOrder;
  final VoidCallback onChooseAddress;
  final VoidCallback onChoosePayment;
  final bool isLoggedIn;
  final VoidCallback? onLoginAndCheckout;
  final bool useWallet;
  final PromoCodeData? appliedPromo;

  /// At least one medical item still needs its mandatory prescription
  /// uploaded — swaps the pay/place-order row for an "Upload Prescription"
  /// CTA that scrolls to the missing item, mirroring the address/payment
  /// selection prompts.
  final bool hasMissingRequiredPrescription;
  final VoidCallback? onUploadPrescription;

  double get _postPromoTotal => resolveCheckoutPostPromoTotal(
    cartData: cartData,
    appliedPromo: appliedPromo,
  );

  bool get _walletCoversFull => resolveCheckoutWalletCoversFull(
    cartData: cartData,
    useWallet: useWallet,
    postPromoTotal: _postPromoTotal,
  );
  bool get _showPaymentMethod => !_walletCoversFull;

  double get _walletAmountUsed => resolveCheckoutWalletAmountUsed(
    cartData: cartData,
    useWallet: useWallet,
    postPromoTotal: _postPromoTotal,
  );

  double get _remainingAmount => _postPromoTotal - _walletAmountUsed;

  /// A payment method is required (wallet doesn't cover the full amount) but the
  /// user hasn't picked one yet — show a dedicated "Select Payment" button
  /// instead of the compact pay-using + place-order row.
  bool get _needsPaymentSelection =>
      _showPaymentMethod && selectedPayment == null;

  /// Selected address is outside every serviceable zone
  /// (is_deliverable_address == 0): the order can't be placed, so the pay /
  /// place-order controls are swapped for a "not available here" prompt.
  bool get _notDeliverable => cartData.isDeliverableAddress == 0;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return _LoginRequiredBar(onLoginAndCheckout: onLoginAndCheckout);
    }

    final hasAddress = selectedAddress != null;

    return _BarContainer(
      padding: EdgeInsetsDirectional.fromSTEB(
        0,
        0,
        0,
        MediaQuery.paddingOf(context).bottom + ThemeConstants.paddingL,
      ),
      child: hasAddress
          ? Column(
              mainAxisSize: .min,
              spacing: 10,
              children: [
                _AddressStrip(
                  selectedAddress: selectedAddress!,
                  onChooseAddress: onChooseAddress,
                ),
                if (_notDeliverable)
                  _NotDeliverablePrompt(onChooseAddress: onChooseAddress)
                else if (hasMissingRequiredPrescription)
                  _UploadPrescriptionPrompt(
                    isLoading: isLoading,
                    onUploadPrescription: onUploadPrescription,
                  )
                else if (_needsPaymentSelection)
                  _SelectPaymentPrompt(
                    isLoading: isLoading,
                    onChoosePayment: onChoosePayment,
                  )
                else
                  _PayAndPlaceOrderRow(
                    showPaymentMethod: _showPaymentMethod,
                    isLoading: isLoading,
                    selectedPayment: selectedPayment,
                    onChoosePayment: onChoosePayment,
                    currency: currency,
                    total: _remainingAmount,
                    onPlaceOrder: onPlaceOrder,
                  ),
              ],
            )
          : Padding(
              padding: const EdgeInsetsDirectional.only(
                top: ThemeConstants.paddingL,
                start: ThemeConstants.paddingL,
                end: ThemeConstants.paddingL,
              ),
              child: AppButton(
                label: context.translate(
                  LanguageLabelKeys.chooseAddressAtNextStep,
                ),
                onPressed: onChooseAddress,
                height: 50,
              ),
            ),
    );
  }
}

/// Shared surface + shadow chrome for the bottom bar container.
class _BarContainer extends StatelessWidget {
  const _BarContainer({required this.padding, required this.child});

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: AppDecorations.box(
        color: context.cs.surface,
        borderRadius: AppRadius.top16,
        boxShadow: [
          BoxShadow(
            color: context.cs.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoginRequiredBar extends StatelessWidget {
  const _LoginRequiredBar({required this.onLoginAndCheckout});

  final VoidCallback? onLoginAndCheckout;

  @override
  Widget build(BuildContext context) {
    return _BarContainer(
      padding: EdgeInsetsDirectional.fromSTEB(
        ThemeConstants.paddingL,
        ThemeConstants.paddingM,
        ThemeConstants.paddingL,
        MediaQuery.paddingOf(context).bottom + ThemeConstants.paddingL,
      ),
      child: AppButton(
        label: context.translate(LanguageLabelKeys.loginAndCheckout),
        onPressed: onLoginAndCheckout,
        height: 50,
      ),
    );
  }
}

class _AddressStrip extends StatelessWidget {
  const _AddressStrip({
    required this.selectedAddress,
    required this.onChooseAddress,
  });

  final AddressData selectedAddress;
  final VoidCallback onChooseAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.only(
        start: ThemeConstants.paddingL,
        end: ThemeConstants.paddingL,
        top: 10,
        bottom: 10,
      ),
      decoration: AppDecorations.box(
        color: context.cs.surfaceContainerLow,
        borderRadius: AppRadius.top16,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppDecorations.box(
              color: context.cs.primaryContainer,
              borderRadius: AppRadius.r8,
            ),
            child: AppSvgIcon(
              AssetsConstants.buildingIcon,
              size: 24,
              color: context.cs.onSurfaceVariant,
              fit: BoxFit.scaleDown,
            ),
          ),
          AppSpacing.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                RichText(
                  text: TextSpan(
                    style: context.tt.bodySmall?.copyWith(
                      color: context.cs.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '${context.translate(LanguageLabelKeys.deliveringTo)} ',
                      ),
                      TextSpan(
                        text:
                            selectedAddress.type ??
                            context.translate(LanguageLabelKeys.address),
                        style: context.tt.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                AppText(
                  selectedAddress.formattedAddress,
                  style: context.tt.bodySmall?.copyWith(
                    color: context.cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.w8,
          GestureDetector(
            onTap: onChooseAddress,
            child: AppText(
              context.translate(LanguageLabelKeys.change),
              style: context.tt.bodySmall?.copyWith(
                color: context.cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom prompt shown in place of the pay / place-order controls when the
/// selected address can't be served — a warning strip plus a clear CTA to
/// change the address.
class _NotDeliverablePrompt extends StatelessWidget {
  const _NotDeliverablePrompt({required this.onChooseAddress});

  final VoidCallback onChooseAddress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: ThemeConstants.paddingL),
      child: Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(10),
            decoration: AppDecorations.box(
              color: context.cs.error.withValues(alpha: 0.08),
              borderRadius: AppRadius.r10,
            ),
            child: Row(
              children: [
                AppSvgIcon(
                  AssetsConstants.infoCircleIcon,
                  size: 18,
                  color: context.cs.error,
                ),
                AppSpacing.w8,
                Expanded(
                  child: AppText(
                    context.translate(
                      LanguageLabelKeys.zoneUnavailableSubtitle,
                    ),
                    style: context.tt.bodySmall?.copyWith(
                      color: context.cs.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.h10,
          AppButton(
            label: context.translate(LanguageLabelKeys.changeAddress),
            onPressed: onChooseAddress,
            height: 50,
          ),
        ],
      ),
    );
  }
}

class _UploadPrescriptionPrompt extends StatelessWidget {
  const _UploadPrescriptionPrompt({
    required this.isLoading,
    required this.onUploadPrescription,
  });

  final bool isLoading;
  final VoidCallback? onUploadPrescription;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: ThemeConstants.paddingL),
      child: AppButton(
        label: context.translate(LanguageLabelKeys.uploadPrescription),
        onPressed: isLoading ? null : onUploadPrescription,
        height: 50,
      ),
    );
  }
}

class _SelectPaymentPrompt extends StatelessWidget {
  const _SelectPaymentPrompt({
    required this.isLoading,
    required this.onChoosePayment,
  });

  final bool isLoading;
  final VoidCallback onChoosePayment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: ThemeConstants.paddingL),
      child: AppButton(
        label: context.translate(LanguageLabelKeys.selectPayment),
        onPressed: isLoading ? null : onChoosePayment,
        height: 50,
      ),
    );
  }
}

class _PayAndPlaceOrderRow extends StatelessWidget {
  const _PayAndPlaceOrderRow({
    required this.showPaymentMethod,
    required this.isLoading,
    required this.selectedPayment,
    required this.onChoosePayment,
    required this.currency,
    required this.total,
    required this.onPlaceOrder,
  });

  final bool showPaymentMethod;
  final bool isLoading;
  final PaymentMethodItem? selectedPayment;
  final VoidCallback onChoosePayment;
  final String currency;
  final double total;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        if (showPaymentMethod)
          Expanded(
            flex: 2,
            child: _PaymentMethodTile(
              isLoading: isLoading,
              selectedPayment: selectedPayment,
              onChoosePayment: onChoosePayment,
            ),
          ),
        Expanded(
          flex: showPaymentMethod ? 3 : 1,
          child: _PlaceOrderButton(
            isLoading: isLoading,
            onPlaceOrder: onPlaceOrder,
            currency: currency,
            total: total,
            startInset: showPaymentMethod ? 0 : 16,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.isLoading,
    required this.selectedPayment,
    required this.onChoosePayment,
  });

  final bool isLoading;
  final PaymentMethodItem? selectedPayment;
  final VoidCallback onChoosePayment;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: ThemeConstants.paddingL),
        child: ShimmerBuilder(
          builder: (context, color) => Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              ShimmerBox(color, width: double.infinity, height: 12),
              AppSpacing.h6,
              ShimmerBox(color, width: 70, height: 14),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onChoosePayment,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: ThemeConstants.paddingL),
        child: Row(
          mainAxisSize: .min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Row(
                    mainAxisSize: .min,
                    children: [
                      selectedPayment != null
                          ? AppSvgIcon(selectedPayment!.iconPath, size: 15)
                          : AppSvgIcon(
                              AssetsConstants.cardIcon,
                              size: 15,
                              color: context.cs.onSurfaceVariant,
                            ),
                      AppSpacing.w8,
                      AppText(
                        context.translate(LanguageLabelKeys.payUsing),
                        style: context.tt.labelSmall?.copyWith(
                          color: context.cs.onSurface,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      AppSpacing.w2,
                      AppSvgIcon(
                        AssetsConstants.arrowUpIcon,
                        size: 13,
                        color: context.cs.onSurface,
                      ),
                    ],
                  ),
                  AppText(
                    context.translate(
                      selectedPayment?.label ?? LanguageLabelKeys.selectPayment,
                    ),
                    style: context.tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceOrderButton extends StatelessWidget {
  const _PlaceOrderButton({
    required this.isLoading,
    required this.onPlaceOrder,
    required this.currency,
    required this.total,
    required this.startInset,
  });

  final bool isLoading;
  final VoidCallback onPlaceOrder;
  final String currency;
  final double total;
  final double startInset;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPlaceOrder,
      child: Container(
        padding: const EdgeInsetsDirectional.all(10),
        margin: EdgeInsetsDirectional.only(end: ThemeConstants.paddingL, start: startInset),
        height: 50,
        decoration: AppDecorations.box(
          color: context.cs.primary,
          borderRadius: AppRadius.r12,
        ),
        child: isLoading
            ? LoadingWidget(size: 22, color: context.cs.onPrimary)
            : Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Column(
                        mainAxisSize: .min,
                        mainAxisAlignment: .center,
                        crossAxisAlignment: .start,
                        children: [
                          AppText(
                            '$currency${total.toStringAsFixed(2)}',
                            style: context.tt.bodyMedium?.copyWith(
                              color: context.cs.onPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          AppText(
                            context
                                .translate(LanguageLabelKeys.total)
                                .toUpperCase(),
                            style: context.tt.labelSmall?.copyWith(
                              color: context.cs.onPrimary.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppText(
                    context.translate(LanguageLabelKeys.placeOrder),
                    style: context.tt.displayMedium?.copyWith(
                      color: context.cs.onPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.w6,
                  Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: AppSvgIcon(
                      AssetsConstants.arrowRightIcon,
                      color: context.cs.onPrimary,
                      size: 12,
                    ),
                  ),
                  AppSpacing.w8,
                ],
              ),
      ),
    );
  }
}
