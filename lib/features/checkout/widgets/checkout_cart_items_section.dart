import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/utils/extensions/num_extensions.dart';
import 'dart:async';
import 'dart:io';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/commons/widgets/app_confirm_dialog.dart';

import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/core/local_storage/auth_hive_box.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/cart/cubit/cart_action_cubit.dart';
import 'package:customer/features/cart/models/cart_model.dart';
import 'package:customer/features/checkout/widgets/checkout_delivery_eta_section.dart';
import 'package:customer/features/checkout/widgets/checkout_prescription_tile.dart';
import 'package:customer/features/checkout/widgets/checkout_shared_widgets.dart';
import 'package:customer/features/checkout/utils/checkout_variant_id.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/utils/variant_attributes_formatter.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckoutCartItemsSection extends StatelessWidget {
  const CheckoutCartItemsSection({
    super.key,
    required this.cartData,
    required this.currency,
    this.prescriptions = const {},
    this.onPrescriptionPicked,
    this.onPrescriptionRemoved,
    this.prescriptionKeyOf,
  });

  final CartData cartData;
  final String currency;

  /// Picked prescription files keyed by product variant id. Only relevant for
  /// medical products (product_type == 5).
  final Map<String, File> prescriptions;
  final void Function(String variantId, File file)? onPrescriptionPicked;
  final void Function(String variantId)? onPrescriptionRemoved;
  final GlobalKey Function(String variantId)? prescriptionKeyOf;

  @override
  Widget build(BuildContext context) {
    final items = cartData.cart ?? [];
    return CheckoutCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(
                child: CheckoutDeliveryEtaSection(
                  distance: cartData.distance,
                  timeToDeliver: cartData.timeToDeliver,
                  estimatedDeliveryDate: cartData.estimatedDeliveryDate,
                  itemCount: items.length,
                ),
              ),
              InkWell(
                borderRadius: AppRadius.r8,
                onTap: () async {
                  final cartActionCubit = context.read<CartActionCubit>();
                  final cartCubit = context.read<CartCubit>();
                  final confirmed = await AppConfirmDialog.show(
                    context: context,
                    icon: AppConfirmDialogIcon.danger,
                    isDestructive: true,
                    title: context.translate(LanguageLabelKeys.clearCart),
                    message: context.translate(
                      LanguageLabelKeys.clearCartConfirm,
                    ),
                    cancelLabel: context.translate(LanguageLabelKeys.cancel),
                    confirmLabel: context.translate(LanguageLabelKeys.clear),
                  );
                  if (confirmed == true) {
                    if (AuthHiveBox.instance.isLoggedIn) {
                      cartActionCubit.clearCart();
                    }
                    cartCubit.clear();
                  }
                },
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: ThemeConstants.paddingXS,
                    vertical: ThemeConstants.paddingXS,
                  ),
                  child: Row(
                    mainAxisSize: .min,
                    spacing: ThemeConstants.spaceXS,
                    children: [
                      AppSvgIcon(
                        AssetsConstants.deleteIcon,
                        size: ThemeConstants.iconXS,
                        color: context.cs.error,
                      ),
                      AppText(
                        context.translate(LanguageLabelKeys.clearCart),
                        style: context.tt.labelMedium?.copyWith(
                          color: context.cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 0.5),
          AppSpacing.h12,
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            final variantId = resolveCheckoutVariantId(e.value);
            return BlocSelector<CartCubit, CartState, int>(
              selector: (state) => state.countFor(variantId),
              builder: (context, qty) {
                // Qty hits 0 — drop the row entirely instead of showing "0".
                if (qty <= 0) return const SizedBox.shrink();
                return Column(
                  children: [
                    CheckoutCartItemTile(
                      item: e.value,
                      currency: currency,
                      prescriptionFile: prescriptions[variantId],
                      onPrescriptionPicked: onPrescriptionPicked == null
                          ? null
                          : (file) => onPrescriptionPicked!(variantId, file),
                      onPrescriptionRemoved: onPrescriptionRemoved == null
                          ? null
                          : () => onPrescriptionRemoved!(variantId),
                      prescriptionKey: prescriptionKeyOf?.call(variantId),
                    ),
                    if (!isLast)
                      Divider(
                        height: 20,
                        thickness: 1,
                        color: context.cs.outline.withValues(alpha: 0.1),
                      ),
                  ],
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class CheckoutCartItemTile extends StatelessWidget {
  const CheckoutCartItemTile({
    super.key,
    required this.item,
    required this.currency,
    this.prescriptionFile,
    this.onPrescriptionPicked,
    this.onPrescriptionRemoved,
    this.prescriptionKey,
  });

  final ProductDataModel item;
  final String currency;
  final File? prescriptionFile;
  final ValueChanged<File>? onPrescriptionPicked;
  final VoidCallback? onPrescriptionRemoved;
  final GlobalKey? prescriptionKey;

  static void _removeItem(BuildContext context, ProductDataModel item) {
    final variantId = resolveCheckoutVariantId(item);
    final cart = context.read<CartCubit>();
    final qty = cart.state.countFor(variantId);
    cart.removeAll(variantId);
    if (AuthHiveBox.instance.isLoggedIn && qty > 0) {
      context.read<CartActionCubit>().removeFromCart(
        productId: item.id?.toString() ?? '',
        productVariantId: variantId,
        qty: qty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgSize = context.screenWidth * 0.19;
    final price = (item.price ?? 0).toDouble();
    final discounted = item.discountedPrice ?? 0;
    final hasDiscount = discounted > 0 && discounted < price;
    final displayPrice = hasDiscount ? discounted : price;
    final dp = item.decimalPoint ?? 0;
    final variant =
        VariantAttributesFormatter.format(
          item.variants?.first.variantAttributes,
        ) ??
        "";
    final slabMessage = (item.slabDiscountMessage ?? '').trim();
    final isOutOfStock = item.isOutOfStock;

    final showPrescription =
        item.isMedicalProduct && !isOutOfStock && onPrescriptionPicked != null;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: isOutOfStock ? 0.5 : 1,
              child: Row(
                crossAxisAlignment: .start,
                spacing: ThemeConstants.spaceM,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.r10,
                        child: Container(
                          decoration: AppDecorations.box(
                            border: Border.all(
                              color: context.cs.outline.withValues(alpha: 0.12),
                            ),
                            borderRadius: AppRadius.r10,
                          ),
                          child: AppNetworkImage(
                            url:
                                item.variants?.first.image ??
                                item.images?.first.imageUrl ??
                                '',
                            width: imgSize,
                            height: imgSize,
                            memCacheWidth: 144,
                            memCacheHeight: 144,
                            borderRadius: AppRadius.r10,
                            errorIconSize: 20,
                          ),
                        ),
                      ),
                      if (isOutOfStock)
                        PositionedDirectional(
                          top: 0,
                          start: 0,
                          child: Container(
                            decoration: AppDecorations.box(
                              color: context.cs.inverseSurface,
                              borderRadius: const BorderRadiusDirectional.only(
                                topStart: Radius.circular(10),
                                bottomEnd: Radius.circular(4),
                              ),
                            ),
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: ThemeConstants.paddingXS,
                              vertical: 3,
                            ),
                            child: AppText(
                              context.translate(LanguageLabelKeys.soldOut),
                              style: context.tt.labelSmall?.copyWith(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: context.cs.onInverseSurface,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Row(
                          crossAxisAlignment: .start,
                          children: [
                            Expanded(
                              child: AppText(
                                item.name ?? '',
                                style: context.tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: .ellipsis,
                              ),
                            ),
                            InkWell(
                              borderRadius: AppRadius.r8,
                              onTap: () => _removeItem(context, item),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: ThemeConstants.paddingS,
                                ),
                                child: AppSvgIcon(
                                  AssetsConstants.closeIcon,
                                  size: ThemeConstants.iconXS,
                                  color: context.cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (variant.isNotEmpty) ...[
                          AppSpacing.h4,
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: ThemeConstants.paddingS,
                              vertical: ThemeConstants.paddingXS,
                            ),
                            decoration: AppDecorations.box(
                              color: context.cs.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: AppRadius.r6,
                            ),
                            child: AppText(
                              variant,
                              style: context.tt.labelSmall?.copyWith(
                                color: context.cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ),
                        ],
                        if (slabMessage.isNotEmpty) ...[
                          AppSpacing.h6,
                          Row(
                            mainAxisSize: .min,
                            spacing: ThemeConstants.spaceXS,
                            children: [
                              AppSvgIcon(
                                AssetsConstants.offerIcon,
                                color: context.cs.onSecondaryContainer,
                                size: ThemeConstants.iconXS,
                              ),
                              Flexible(
                                child: AppText(
                                  slabMessage,
                                  style: context.tt.labelSmall?.copyWith(
                                    color: context.cs.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        AppSpacing.h10,
                        Row(
                          children: [
                            BlocSelector<CartCubit, CartState, int>(
                              selector: (state) =>
                                  state.countFor(resolveCheckoutVariantId(item)),
                              builder: (context, qty) => Row(
                                crossAxisAlignment: .center,
                                spacing: ThemeConstants.spaceS,
                                children: [
                                  AppText(
                                    '${item.currency}${(displayPrice * qty).formatPrice(dp)}',
                                    style: context.tt.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (hasDiscount) ...[
                                    AppText(
                                      '${item.currency}${(price * qty).formatPrice(dp)}',
                                      style: context.tt.bodySmall?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: context.cs.onSurface.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (!isOutOfStock) CheckoutQtyControl(item: item),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showPrescription)
          CheckoutPrescriptionTile(
            key: prescriptionKey,
            item: item,
            file: prescriptionFile,
            onPicked: onPrescriptionPicked!,
            onRemove: onPrescriptionRemoved ?? () {},
          ),
      ],
    );
  }
}

class CheckoutQtyControl extends StatefulWidget {
  const CheckoutQtyControl({super.key, required this.item});

  final ProductDataModel item;

  @override
  State<CheckoutQtyControl> createState() => _CheckoutQtyControlState();
}

class _CheckoutQtyControlState extends State<CheckoutQtyControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  // Debounced server sync: coalesce a burst of taps into a single API call.
  Timer? _syncDebounce;
  int? _baseQty; // server-confirmed qty captured at the start of a tap burst
  CartCubit? _cartCubit;
  CartActionCubit? _actionCubit;

  ProductDataModel get item => widget.item;

  String get _variantId => resolveCheckoutVariantId(item);

  bool get _hasLimit => (item.totalAllowedQuantity ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(_scaleCtrl);
  }

  @override
  void dispose() {
    // Persist any pending change before the widget goes away.
    if (_syncDebounce?.isActive ?? false) {
      _syncDebounce!.cancel();
      _flushSync();
    }
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _scheduleSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 500), _flushSync);
  }

  /// Sends the net change accumulated during the burst as one request.
  void _flushSync() {
    _syncDebounce = null;
    final base = _baseQty;
    final cart = _cartCubit;
    final action = _actionCubit;
    _baseQty = null;
    if (base == null || cart == null || action == null) return;
    final target = cart.state.countFor(_variantId);
    final delta = target - base;
    if (delta == 0) return;
    if (delta > 0) {
      action.addToCart(
        productId: item.id?.toString() ?? '',
        productVariantId: _variantId,
        qty: target,
      );
    } else {
      action.removeFromCart(
        productId: item.id?.toString() ?? '',
        productVariantId: _variantId,
        qty: -delta,
      );
    }
  }

  void _showLimitWarning(BuildContext context) {
    AppSnackBar.show(
      context: context,
      message: context.translate(LanguageLabelKeys.maxAllowedQuantityReached),
      type: SnackBarType.warning,
    );
  }

  void _onRemove(BuildContext context) {
    final isLoggedIn = AuthHiveBox.instance.isLoggedIn;
    final cart = context.read<CartCubit>();
    if (cart.state.countFor(_variantId) <= 0) return;
    HapticFeedback.lightImpact();
    _scaleCtrl.forward(from: 0.0);
    final price = (item.discountedPrice ?? item.price ?? 0).toDouble();
    if (isLoggedIn) {
      _cartCubit = cart;
      _actionCubit = context.read<CartActionCubit>();
      _baseQty ??= cart.state.countFor(_variantId);
    }
    cart.remove(_variantId, price);
    if (isLoggedIn) _scheduleSync();
  }

  void _onAdd(BuildContext context) {
    if (item.isOutOfStock) {
      AppSnackBar.show(
        context: context,
        message: context.translate(LanguageLabelKeys.outOfStock),
        type: SnackBarType.warning,
      );
      return;
    }
    final isLoggedIn = AuthHiveBox.instance.isLoggedIn;
    final cart = context.read<CartCubit>();
    final localQty = cart.state.countFor(_variantId);

    if (_hasLimit && localQty >= (item.totalAllowedQuantity ?? 0)) {
      _showLimitWarning(context);
      return;
    }
    final maxCartItems = SettingsHiveBox.instance.maxCartItemsCount;
    if (maxCartItems > 0 && cart.state.totalItems >= maxCartItems) {
      AppSnackBar.show(
        context: context,
        message: context.translate(LanguageLabelKeys.maxCartItemsReached),
        type: SnackBarType.warning,
      );
      return;
    }

    HapticFeedback.lightImpact();
    _scaleCtrl.forward(from: 0.0);
    final price = (item.discountedPrice ?? item.price ?? 0).toDouble();
    final imageUrl =
        item.variants?.first.image ?? item.images?.first.imageUrl ?? '';
    if (isLoggedIn) {
      _cartCubit = cart;
      _actionCubit = context.read<CartActionCubit>();
      _baseQty ??= localQty;
    }
    cart.add(_variantId, price, imageUrl: imageUrl);
    if (isLoggedIn) _scheduleSync();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        height: 32,
        // Same surface as CartButton's stepper, with a softer lift — this
        // control is shorter (32px) and sits inside a list row.
        decoration: AppDecorations.cartControl(
          cs: context.cs,
          filled: true,
          softShadow: true,
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            CheckoutQtyBtn(
              icon: AssetsConstants.removeIcon,
              color: context.cs.onPrimary,
              onTap: () => _onRemove(context),
            ),
            SizedBox(
              width: 24,
              child: Center(
                child: BlocSelector<CartCubit, CartState, int>(
                  selector: (state) => state.countFor(_variantId),
                  builder: (context, qty) => AppText(
                    '$qty',
                    style: context.tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.cs.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            CheckoutQtyBtn(
              icon: AssetsConstants.addIcon,
              color: item.isOutOfStock
                  ? context.cs.onPrimary.withValues(alpha: 0.35)
                  : context.cs.onPrimary,
              onTap: () => _onAdd(context),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutQtyBtn extends StatelessWidget {
  const CheckoutQtyBtn({
    super.key,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: ThemeConstants.paddingS,
          vertical: ThemeConstants.paddingS,
        ),
        child: AppSvgIcon(icon, size: ThemeConstants.iconXS, color: color),
      ),
    );
  }
}
