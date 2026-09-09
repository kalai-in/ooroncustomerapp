import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/features/products/cubit/recently_visited_cubit.dart';
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

class RecentlyVisitedSection extends StatelessWidget {
  /// Scopes this section's hero tags (e.g. `product_hero_<id>_rv`) to the
  /// hosting product detail page, so concurrently-mounted pages in the
  /// swipeable pager never collide on the same tag.
  final String heroSuffix;

  const RecentlyVisitedSection({super.key, this.heroSuffix = '_rv'});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentlyVisitedCubit, RecentlyVisitedState>(
      builder: (context, state) {
        if (state is! RecentlyVisitedLoaded || state.products.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayProducts = state.products.take(6).toList();
        final hasMore = state.total > 6;
        final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
        final crossAxisCount = isTablet ? 5 : 3;

        return Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, ThemeConstants.paddingL, 10, ThemeConstants.paddingM),
              child: AppText(
                context.translate(LanguageLabelKeys.recentlyVisited),
                style: context.tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.cs.onSurface,
                ),
              ),
            ),
            ProductCardGrid(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, ThemeConstants.paddingS),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16 * (isTablet ? 1.75 : 1.0),
              crossAxisSpacing: 10 * (isTablet ? 1.75 : 1.0),
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
                products: state.products,
                onTap: () => AppNavigator.push(
                  context,
                  ProductScreen(
                    title: context.translate(LanguageLabelKeys.recentlyVisited),
                    products: state.products,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
