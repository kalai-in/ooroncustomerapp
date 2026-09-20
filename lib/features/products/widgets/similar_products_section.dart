import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/features/products/cubit/similar_product_cubit.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/features/products/screens/product_screen.dart';
import 'package:customer/features/products/widgets/product_card.dart';
import 'package:customer/features/products/widgets/product_card_grid.dart';
import 'package:customer/features/products/widgets/view_more_button.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

typedef _SimilarProductState = PaginationState<ProductDataModel>;
typedef _SimilarProductLoaded = PaginationLoaded<ProductDataModel>;

class SimilarProductsSection extends StatelessWidget {
  /// Scopes this section's hero tags (e.g. `product_hero_<id>_sp`) to the
  /// hosting product detail page, so concurrently-mounted pages in the
  /// swipeable pager never collide on the same tag.
  final String heroSuffix;

  const SimilarProductsSection({super.key, this.heroSuffix = '_sp'});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SimilarProductCubit, _SimilarProductState>(
      builder: (context, state) {
        if (state is! _SimilarProductLoaded || state.data.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayProducts = state.data.take(6).toList();
        final hasMore = state.total > 6;

        final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
        final crossAxisCount = isTablet ? 5 : 3;

        return Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingS, ThemeConstants.paddingL, ThemeConstants.paddingS, ThemeConstants.paddingM),
              child: AppText(
                context.translate(LanguageLabelKeys.similarProducts),
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
                products: state.data,
                onTap: () => AppNavigator.push(
                  context,
                  ProductScreen(
                    title: context.translate(LanguageLabelKeys.similarProducts),
                    products: state.data,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
