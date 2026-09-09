import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/features/category/cubit/sub_category_cubit.dart';
import 'package:customer/features/category/models/category_model.dart';
import 'package:customer/features/category/widgets/sub_category_children_panel.dart';
import 'package:customer/features/category/widgets/sub_category_filter_bar.dart';
import 'package:customer/features/category/widgets/sub_category_product_panel.dart';
import 'package:customer/features/products/cubit/product_cubit.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/features/products/widgets/product_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/commons/widgets/app_text.dart';

typedef _ProductState = PaginationState<ProductDataModel>;

class SubCategoryContentPanel extends StatelessWidget {
  final ScrollController controller;
  final String? selectedCategoryId;
  final VoidCallback onRetry;
  final bool showSidebar;
  // Non-null only for the initial auto-selected category when it has children —
  // shows its direct subcategories here instead of the product grid.
  final Category? autoChildCategory;
  final ValueChanged<Category>? onSelectChildCategory;

  const SubCategoryContentPanel({
    super.key,
    required this.controller,
    required this.selectedCategoryId,
    required this.onRetry,
    this.showSidebar = true,
    this.autoChildCategory,
    this.onSelectChildCategory,
  });

  Widget _productSkeleton(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    return ProductGridSkeleton(
      crossAxisCount: showSidebar ? (isTablet ? 3 : 2) : (isTablet ? 5 : 3),
      spacing: 8 * (isTablet ? 1.75 : 1.0),
      mainAxisSpacing: 12 * (isTablet ? 1.75 : 1.0),
    );
  }

  // On open nothing is selected yet only because the sidebar is still
  // loading its first item (which auto-selects itself) — keep the skeleton
  // up through that gap instead of flashing the "select a category" prompt.
  // The prompt is still the right answer once the sidebar has settled with
  // nothing to auto-select: an error, or an empty list.
  Widget _initialPlaceholder(BuildContext context) {
    if (!showSidebar) return _productSkeleton(context);
    return BlocBuilder<SubCategoryCubit, PaginationState<Category>>(
      builder: (context, sidebarState) {
        final nothingToSelect =
            sidebarState is PaginationError<Category> ||
            (sidebarState is PaginationLoaded<Category> &&
                sidebarState.data.isEmpty);
        if (!nothingToSelect) return _productSkeleton(context);
        return Center(
          child: AppText(
            context.translate(LanguageLabelKeys.selectACategory),
            style: context.tt.bodySmall?.copyWith(
              fontSize: 13,
              color: context.cs.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (autoChildCategory != null) {
      return Expanded(
        child: BlocBuilder<SubCategoryChildrenCubit, PaginationState<Category>>(
          builder: (context, state) => SubCategoryChildrenPanel(
            state: state,
            controller: controller,
            onSelect: onSelectChildCategory ?? (_) {},
          ),
        ),
      );
    }
    return Expanded(
      child: Column(
        children: [
          BlocBuilder<ProductCubit, _ProductState>(
            builder: (context, state) => SubCategoryFilterBar(state: state),
          ),
          Expanded(
            child: BlocBuilder<ProductCubit, _ProductState>(
              builder: (context, state) {
                if (state is PaginationInitial<ProductDataModel>) {
                  return _initialPlaceholder(context);
                }
                if (state is PaginationLoading<ProductDataModel>) {
                  return _productSkeleton(context);
                }
                if (state is PaginationError<ProductDataModel>) {
                  return EmptyStateWidget(
                    imagePath: AssetsConstants.noSearchFound,
                    title: state.message,
                    subtitle: context.translate(LanguageLabelKeys.tapRetry),
                    onRetry: onRetry,
                  );
                }
                if (state is PaginationLoaded<ProductDataModel>) {
                  return SubCategoryProductPanel(
                    state: state,
                    controller: controller,
                    showSidebar: showSidebar,
                  );
                }
                return AppSpacing.shrink;
              },
            ),
          ),
        ],
      ),
    );
  }
}
