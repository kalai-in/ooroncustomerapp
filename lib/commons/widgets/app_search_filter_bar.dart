import 'package:customer/commons/widgets/app_icon_filter_button.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:flutter/material.dart';
import '../../utils/extensions/context_extensions.dart';
import '../../utils/extensions/localization_extensions.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/core/constants/theme_constants.dart';

class AppSearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onDateRange;
  final VoidCallback onClearFilters;
  final bool hasDateFilter;
  final String? dateRangeLabel;
  final bool hasActiveFilters;
  final String? hintText;
  final EdgeInsetsDirectional? padding;
  final String filterIcon;
  final VoidCallback? onMicTap;
  final bool isListening;

  const AppSearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.onSubmitted,
    required this.onDateRange,
    required this.onClearFilters,
    this.hasDateFilter = false,
    this.dateRangeLabel,
    this.hasActiveFilters = false,
    this.hintText = 'Search by order ID or customer…',
    this.padding,
    this.filterIcon = AssetsConstants.dateIcon,
    this.onMicTap,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    final borders = AppDecorations.inputBorderSet(context.cs);
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: padding ?? const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingM, ThemeConstants.paddingL, ThemeConstants.paddingM),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: searchController,
              onChanged: onSearchChanged,
              onFieldSubmitted: onSubmitted,
              style: context.tt.bodyMedium,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: context.tt.bodyMedium?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
                prefixIcon: AppSvgIcon(
                  AssetsConstants.searchIcon,
                  size: 18,
                  color: context.cs.onSurfaceVariant,
                  fit: BoxFit.scaleDown,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: AppSvgIcon(
                          AssetsConstants.closeIcon,
                          size: 18,
                          color: context.cs.onSurfaceVariant,
                        ),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : onMicTap != null
                    ? Row(
                        mainAxisSize: .min,
                        children: [
                          SizedBox(
                            height: 22,
                            child: VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: context.cs.outlineVariant,
                            ),
                          ),
                          IconButton(
                            icon: AppSvgIcon(
                              AssetsConstants.microphoneIcon,
                              size: 20,
                              color: isListening
                                  ? context.cs.primary
                                  : context.cs.onSurfaceVariant,
                            ),
                            onPressed: onMicTap,
                          ),
                        ],
                      )
                    : null,
                filled: true,
                fillColor: context.cs.surface,
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: ThemeConstants.paddingM,
                  vertical: 10,
                ),
                border: borders.border,
                enabledBorder: borders.enabledBorder,
                focusedBorder: borders.focusedBorder,
              ),
            ),
          ),
          AppSpacing.w8,
          AppIconFilterButton(
            icon: filterIcon,
            isActive: hasDateFilter,
            onTap: onDateRange,
            tooltip:
                dateRangeLabel ??
                context.translate(LanguageLabelKeys.filterByDate),
          ),
          if (hasActiveFilters) ...[
            AppSpacing.w6,
            AppIconFilterButton(
              icon: AssetsConstants.closeIcon,
              isActive: false,
              onTap: onClearFilters,
              tooltip: context.translate(LanguageLabelKeys.clearFiltersTooltip),
            ),
          ],
        ],
      ),
    );
  }
}
