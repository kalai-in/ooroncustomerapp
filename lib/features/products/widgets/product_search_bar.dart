import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/commons/widgets/app_text_field.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:flutter/material.dart';

class ProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final bool hasActiveSort;

  const ProductSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilterTap,
    this.hasActiveSort = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, 10, ThemeConstants.paddingL, ThemeConstants.paddingM),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: AppTextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onFieldSubmitted: onSubmitted,
              style: context.tt.bodyMedium,
              isDense: true,
              hintText: context.translate(LanguageLabelKeys.searchProductsHint),
              hintStyle: context.tt.bodyMedium?.copyWith(
                color: context.cs.onSurfaceVariant,
              ),
              prefixIcon: AppSvgIcon(
                AssetsConstants.searchIcon,
                size: 24,
                color: context.cs.onSurfaceVariant,
                fit: BoxFit.scaleDown,
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: AppSvgIcon(
                        AssetsConstants.closeIcon,
                        size: 18,
                        color: context.cs.onSurfaceVariant,
                      ),
                      onPressed: onClear,
                    )
                  : null,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: ThemeConstants.paddingM,
                vertical: ThemeConstants.paddingM,
              ),
            ),
          ),
          Tooltip(
            message: context.translate(LanguageLabelKeys.sortBy),
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: AppRadius.r10,
              child: Container(
                width: 44,
                height: 44,
                decoration: AppDecorations.outlinedCard(
                  color: hasActiveSort
                      ? context.cs.primaryContainer
                      : context.cs.surface,
                  borderColor: hasActiveSort
                      ? context.cs.primary
                      : context.cs.outline,
                ),
                child: AppSvgIcon(
                  AssetsConstants.filterSettingIcon,
                  size: 20,
                  color: hasActiveSort
                      ? context.cs.primary
                      : context.cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
