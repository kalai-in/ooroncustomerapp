import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/constants/theme_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  // Search support
  final bool isSearching;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final VoidCallback? onSearchStart;
  final VoidCallback? onSearchCancel;
  // Extra bottom row (e.g. status chips)
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isSearching = false,
    this.searchController,
    this.onSearchChanged,
    this.searchHint,
    this.onSearchStart,
    this.onSearchCancel,
    this.bottom,
  });

  bool get _hasSearch => onSearchStart != null;

  @override
  Size get preferredSize => Size.fromHeight(
    (subtitle != null ? kToolbarHeight + 20 : kToolbarHeight) +
        (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final titleColor = foregroundColor ?? context.cs.onSurface;

    return AppBar(
      backgroundColor: backgroundColor ?? context.cs.surface,
      foregroundColor: titleColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: false, //!isSearching,
      titleSpacing: _hasSearch && isSearching
          ? 16
          : NavigationToolbar.kMiddleSpacing,
      toolbarHeight: subtitle != null ? kToolbarHeight + 20 : kToolbarHeight,
      automaticallyImplyLeading: showBackButton,
      title: subtitle != null
          ? Column(
              crossAxisAlignment: .start,
              mainAxisAlignment: .center,
              children: [
                AppText(
                  title ?? '',
                  style: context.tt.titleLarge?.copyWith(color: titleColor),
                ),
                AppText(
                  subtitle!,
                  style: context.tt.bodySmall?.copyWith(
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
              ],
            )
          : _hasSearch
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.92,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: isSearching
                  ? _AppBarSearchField(
                      key: const ValueKey('search'),
                      controller: searchController!,
                      hint: searchHint ?? context.translate(LanguageLabelKeys.search),
                      onChanged: onSearchChanged ?? (_) {},
                    )
                  : AppText(
                      title ?? '',
                      key: const ValueKey('title'),
                      style: context.tt.titleLarge?.copyWith(
                        color: titleColor,
                        letterSpacing: 0.2,
                      ),
                    ),
            )
          : title != null
          ? AppText(
              title!,
              style: context.tt.titleLarge?.copyWith(color: titleColor),
            )
          : null,
      leading: showBackButton
          ? IconButton(
              icon: Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: AppSvgIcon(
                  AssetsConstants.arrowLeftIcon,
                  size: 24,
                  color: titleColor,
                ),
              ),
              onPressed: onBackPressed ?? () => AppNavigator.pop(context),
            )
          : null,
      actions: [
        if (_hasSearch)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSearching
                ? IconButton(
                    key: const ValueKey('close'),
                    icon: AppSvgIcon(
                      AssetsConstants.closeIcon,
                      size: 18,
                      color: context.cs.onSurfaceVariant,
                    ),
                    onPressed: onSearchCancel,
                    color: context.cs.onSurfaceVariant,
                  )
                : IconButton(
                    key: const ValueKey('searchBtn'),
                    icon: AppSvgIcon(
                      AssetsConstants.searchIcon,
                      size: 18,
                      color: context.cs.onSurfaceVariant,
                    ),
                    onPressed: onSearchStart,
                    color: context.cs.onSurfaceVariant,
                  ),
          ),
        ...?actions,
      ],
      bottom: bottom,
    );
  }
}

class _AppBarSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _AppBarSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Container(
          height: 40,
          decoration: AppDecorations.box(
            color: context.cs.onSurface.withValues(alpha: 0.07),
            borderRadius: AppRadius.r10,
          ),
          child: Row(
            children: [
              AppSpacing.w12,
              AppSvgIcon(
                AssetsConstants.searchIcon,
                size: 18,
                color: context.cs.onSurfaceVariant,
              ),
              AppSpacing.w8,
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  style: context.tt.bodyMedium?.copyWith(
                    color: context.cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: context.tt.bodyMedium?.copyWith(
                      color: context.cs.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsetsDirectional.zero,
                  ),
                ),
              ),
              if (value.text.trim().isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingS),
                    child: AppSvgIcon(
                      AssetsConstants.closeCircleIcon,
                      size: 18,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                )
              else
                AppSpacing.w12,
            ],
          ),
        );
      },
    );
  }
}
