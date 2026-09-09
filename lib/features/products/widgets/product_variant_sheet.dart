import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/utils/extensions/num_extensions.dart';
import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/commons/widgets/cart_button.dart';
import 'package:customer/commons/widgets/zigzag_badge_clipper.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:customer/commons/animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/utils/show_app_bottom_sheet.dart';
import 'package:customer/core/constants/theme_constants.dart';

class ProductVariantSheet extends StatelessWidget {
  final ProductDataModel product;
  final List<Variants> activeVariants;
  final bool isDark;
  final void Function(Variants) onFirstAdd;
  final BuildContext parentContext;

  const ProductVariantSheet({
    super.key,
    required this.product,
    required this.activeVariants,
    required this.isDark,
    required this.onFirstAdd,
    required this.parentContext,
  });

  String _unitLabel(Variants v) => v.attributesText ?? v.name ?? '';

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: context.screenHeight * 0.75,
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          AppSpacing.h16,
          AppText(
            product.name ?? '',
            style: context.tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: context.cs.onSurface,
            ),
          ),
          AppSpacing.h4,
          Flexible(
            child: SlideAnimationScope(
              builder: (context, animationController) => ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingS),
                itemCount: activeVariants.length,
                separatorBuilder: (_, _) => AppSpacing.h10,
                itemBuilder: (_, i) {
                  final v = activeVariants[i];
                  final rawPrice = (v.price ?? 0).toDouble();
                  final rawDisc = (v.discountedPrice ?? 0).toDouble();
                  final hasDisc = rawDisc > 0 && rawDisc < rawPrice;
                  final displayPrice = hasDisc ? rawDisc : rawPrice;
                  final discPct = hasDisc && rawPrice > 0
                      ? ((rawPrice - rawDisc) / rawPrice * 100).round()
                      : 0;

                  final variantImage = (v.image != null && v.image!.isNotEmpty)
                      ? v.image!
                      : '';

                  return SlideAnimation(
                    position: i,
                    slideDirection: SlideDirection.fromBottom,
                    itemCount: activeVariants.length,
                    animationController: animationController,
                    child: Container(
                      padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingM),
                      decoration: AppDecorations.box(
                        color: context.cs.surface,
                        borderRadius: AppRadius.r12,
                        border: Border.all(
                          color: context.cs.outlineVariant,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (variantImage.isNotEmpty) ...[
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AppNetworkImage(
                                  url: variantImage,
                                  width: context.screenWidth * 0.18,
                                  height: context.screenWidth * 0.18,
                                  borderRadius: AppRadius.r8,
                                  fit: BoxFit.contain,
                                ),
                                if (hasDisc)
                                  PositionedDirectional(
                                    top: 0,
                                    start: 5,
                                    child: ClipPath(
                                      clipper: const ZigzagBadgeClipper(),
                                      child: Container(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              start: ThemeConstants.paddingXS,
                                              end: ThemeConstants.paddingXS,
                                              top: 3,
                                              bottom: 6,
                                            ),
                                        color: context.cs.primary,
                                        child: AppText(
                                          '$discPct${AppConstants.percentSymbol}\n${context.translate(LanguageLabelKeys.off).toUpperCase()}',
                                          textAlign: .center,
                                          style: context.tt.labelSmall
                                              ?.copyWith(
                                                fontSize: 8,
                                                height: 1.1,
                                                fontWeight: FontWeight.w800,
                                                color: context.cs.onPrimary,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            AppSpacing.w10,
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: .start,
                              spacing: 4,
                              children: [
                                AppText(
                                  _unitLabel(v),
                                  style: context.tt.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: context.cs.onSurface,
                                  ),
                                ),
                                Row(
                                  spacing: 6,
                                  children: [
                                    AppText(
                                      '${product.currency}${displayPrice.formatPrice(product.decimalPoint ?? 2)}',
                                      style: context.tt.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: context.cs.onSurface,
                                      ),
                                    ),
                                    if (hasDisc) ...[
                                      AppText(
                                        '${product.currency}${rawPrice.formatPrice(product.decimalPoint ?? 2)}',
                                        style: context.tt.bodySmall?.copyWith(
                                          color: context.cs.onSurfaceVariant,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor:
                                              context.cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.w12,
                          CartButton(
                            key: ValueKey('sheet_btn_${v.id}'),
                            width: 80,
                            height: 36,
                            fontSize: 12,
                            optionsFontSize: 8,
                            optionCount: 1,
                            initialCount: context
                                .read<CartCubit>()
                                .state
                                .countFor(v.id?.toString() ?? ''),
                            productId: product.id?.toString() ?? '',
                            variantId: v.id?.toString() ?? '',
                            price: displayPrice,
                            imageUrl: variantImage,
                            totalAllowedQuantity:
                                product.totalAllowedQuantity ?? 0,
                            onFirstAdd: () => onFirstAdd(v),
                            onLastRemove: () {},
                            onLimitReached: () => AppNavigator.pop(context),
                            snackBarContext: parentContext,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          AppSpacing.h8,
        ],
      ),
    );
  }
}

void showProductVariantSheet({
  required BuildContext context,
  required ProductDataModel product,
  required List<Variants> variants,
  required bool isDark,
  void Function(Variants)? onFirstAdd,
}) {
  showAppBottomSheet<void>(
    context,
    backgroundColor: context.cs.surfaceContainer,
    padding: const EdgeInsetsDirectional.only(start: ThemeConstants.paddingL, end: ThemeConstants.paddingL, top: ThemeConstants.paddingM),
    builder: (_) => BlocProvider.value(
      value: context.read<CartCubit>(),
      child: ProductVariantSheet(
        product: product,
        activeVariants: variants,
        isDark: isDark,
        onFirstAdd: onFirstAdd ?? (_) {},
        parentContext: context,
      ),
    ),
  );
}
