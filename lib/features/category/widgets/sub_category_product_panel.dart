import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/commons/widgets/loading_widget.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/features/products/widgets/product_card.dart';
import 'package:customer/features/products/widgets/product_card_grid.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:flutter/material.dart';

class SubCategoryProductPanel extends StatelessWidget {
  final PaginationLoaded<ProductDataModel> state;
  final ScrollController controller;
  final bool showSidebar;

  const SubCategoryProductPanel({
    super.key,
    required this.state,
    required this.controller,
    this.showSidebar = true,
  });

  @override
  Widget build(BuildContext context) {
    if (state.data.isEmpty) {
      return EmptyStateWidget(
        imagePath: AssetsConstants.noSearchFound,
        title: context.translate(LanguageLabelKeys.noProductsFound),
        subtitle: context.translate(LanguageLabelKeys.noProductsInCategory),
      );
    }

    final itemCount = state.data.length;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    final crossAxisCount = showSidebar
        ? (isTablet ? 3 : 2)
        : (isTablet ? 5 : 3);

    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverToBoxAdapter(
          child: ProductCardGrid(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingS, ThemeConstants.paddingXS, ThemeConstants.paddingS, ThemeConstants.paddingS),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8 * (isTablet ? 1.75 : 1.0),
            mainAxisSpacing: 12 * (isTablet ? 1.75 : 1.0),
            itemCount: itemCount,
            itemBuilder: (context, index, cardWidth) => ProductCard(
              product: state.data[index],
              siblingProducts: state.data,
              index: index,
              cardWidth: cardWidth,
              onAddTap: () {},
            ),
          ),
        ),
        if (state.isFetchingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingXL),
              child: LoadingWidget(),
            ),
          )
        else
          const SliverToBoxAdapter(child: AppSpacing.h16),
      ],
    );
  }
}
