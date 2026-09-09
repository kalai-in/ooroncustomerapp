import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

class RecentSearchesView extends StatelessWidget {
  final List<String> recentSearches;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  const RecentSearchesView({
    super.key,
    required this.recentSearches,
    required this.onTap,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(start: ThemeConstants.paddingL, end: ThemeConstants.paddingL),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              AppText(
                context.translate(LanguageLabelKeys.recentSearches),
                style: context.tt.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.cs.onSurface,
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                child: AppText(context.translate(LanguageLabelKeys.clearAll)),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches
                .map(
                  (query) => _RecentSearchChip(
                    query: query,
                    onTap: () => onTap(query),
                    onRemove: () => onRemove(query),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentSearchChip extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchChip({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.r20,
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: ThemeConstants.paddingM,
          end: 6,
          top: 6,
          bottom: 6,
        ),
        decoration: AppDecorations.box(
          color: context.cs.surfaceContainer,
          borderRadius: AppRadius.r20,
          border: Border.all(color: context.cs.outline),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            AppSvgIcon(
              AssetsConstants.historyIcon,
              size: 16,
              color: context.cs.onSurfaceVariant,
            ),
            AppSpacing.w6,
            AppText(
              query,
              style: context.tt.bodySmall?.copyWith(
                fontSize: 13,
                color: context.cs.onSurface,
              ),
            ),
            AppSpacing.w4,
            InkWell(
              onTap: onRemove,
              borderRadius: AppRadius.r20,
              child: AppSvgIcon(
                AssetsConstants.closeIcon,
                size: 16,
                color: context.cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
