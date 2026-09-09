import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/products/cubit/product_cubit.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/features/products/models/product_sort_type.dart';
import 'package:customer/features/products/widgets/product_filter_sheet.dart';
import 'package:customer/features/products/widgets/product_sort_sheet.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

class SubCategoryFilterBar extends StatelessWidget {
  final PaginationState<ProductDataModel> state;
  const SubCategoryFilterBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is! PaginationLoaded<ProductDataModel>) {
      return const SizedBox.shrink();
    }
    final loaded = state as PaginationLoaded<ProductDataModel>;
    final filters = context.read<ProductCubit>().currentFilters;

    final borderColor = context.cs.outlineVariant;
    final textColor = context.cs.onSurface;
    final activeColor = context.cs.primary;

    final chips = [
      (
        AssetsConstants.filterSettingIcon,
        context.translate(LanguageLabelKeys.filters),
        filters.hasActiveFilters,
        () => showProductFilterSheet(context, loaded),
      ),
      (
        AssetsConstants.sortIcon,
        context.translate(filters.sort.labelKey()),
        filters.sort != ProductSortType.defaultSort,
        () => showProductSortSheet(context, filters.sort),
      ),
    ];

    return Container(
      height: 48,
      decoration: AppDecorations.box(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: ThemeConstants.paddingM,
          vertical: ThemeConstants.paddingS,
        ),
        itemCount: chips.length,
        separatorBuilder: (_, _) => AppSpacing.w8,
        itemBuilder: (context, i) {
          final (icon, label, active, onTap) = chips[i];
          final chipColor = active ? activeColor : textColor;
          return InkWell(
            onTap: onTap,
            borderRadius: AppRadius.r6,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 10,
                vertical: ThemeConstants.paddingXS,
              ),
              decoration: AppDecorations.box(
                borderRadius: AppRadius.r6,
                border: Border.all(color: active ? activeColor : borderColor),
              ),
              child: Row(
                mainAxisSize: .min,
                children: [
                  AppSvgIcon(icon, size: 14, color: chipColor),
                  AppSpacing.w4,
                  AppText(
                    label,
                    style: context.tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: chipColor,
                    ),
                  ),
                  AppSpacing.w3,
                  AppSvgIcon(
                    AssetsConstants.arrowDownIcon,
                    size: 16,
                    color: chipColor,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
