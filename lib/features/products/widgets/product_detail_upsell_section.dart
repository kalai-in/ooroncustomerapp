import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/features/cart/cubit/cart_recommendations_cubit.dart';
import 'package:customer/features/products/screens/product_screen.dart';
import 'package:customer/features/products/widgets/product_card.dart';
import 'package:customer/features/products/widgets/product_card_grid.dart';
import 'package:customer/features/products/widgets/view_more_button.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

/// "Upgrade your order" upsell grid, shown above Similar Products. Backed
/// by the same cart-wide [CartRecommendationsCubit] used at checkout (no
/// per-product upsell endpoint exists), so it's not specific to the
/// product being viewed.
class ProductDetailUpsellSection extends StatelessWidget {
  final String heroSuffix;
  final Key? sectionKey;

  const ProductDetailUpsellSection({
    super.key,
    this.heroSuffix = '_upsell',
    this.sectionKey,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartRecommendationsCubit, CartRecommendationsState>(
      builder: (context, state) {
        if (state is! CartRecommendationsLoaded) return const SizedBox.shrink();
        final products = state.recommendations.data?.upsell?.products ?? [];
        if (products.isEmpty) return const SizedBox.shrink();

        final displayProducts = products.take(6).toList();
        final total = state.recommendations.data?.upsell?.total;
        final hasMore = (total ?? products.length) > 6;
        final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
        final crossAxisCount = isTablet ? 5 : 3;

        return Column(
          key: sectionKey,
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingS, ThemeConstants.paddingL, ThemeConstants.paddingS, ThemeConstants.paddingM),
              child: AppText(
                context.translate(LanguageLabelKeys.upgradeYourOrder),
                style: context.tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.cs.onSurface,
                ),
              ),
            ),
            ProductCardGrid(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingS, 0, ThemeConstants.paddingS, ThemeConstants.paddingS),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10 * (isTablet ? 1.75 : 1.0),
              mainAxisSpacing: 10 * (isTablet ? 1.75 : 1.0),
              itemCount: displayProducts.length,
              itemBuilder: (context, i, cardWidth) => ProductCard(
                product: displayProducts[i],
                heroSuffix: heroSuffix,
                siblingProducts: displayProducts,
                index: i,
                cardWidth: cardWidth,
              ),
            ),
            if (hasMore)
              ViewMoreButton(
                products: products,
                onTap: () => AppNavigator.push(
                  context,
                  ProductScreen(
                    title: context.translate(LanguageLabelKeys.upgradeYourOrder),
                    products: products,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
