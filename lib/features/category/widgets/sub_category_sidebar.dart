import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/features/category/models/category_model.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

class SidebarLoader extends StatelessWidget {
  final Color bg;
  const SidebarLoader({super.key, required this.bg});

  @override
  Widget build(BuildContext context) {
    final shimmer = context.cs.surfaceContainerHigh;
    return Container(
      color: bg,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: ThemeConstants.paddingS,
            horizontal: ThemeConstants.paddingM,
          ),
          child: Column(
            spacing: ThemeConstants.spaceS,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: AppDecorations.box(color: shimmer, shape: .circle),
              ),
              Container(
                width: 48,
                height: 8,
                decoration: AppDecorations.box(
                  color: shimmer,
                  borderRadius: AppRadius.r4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = category.name?.isNotEmpty == true ? category.name! : '';

    final selectedBg = context.cs.surfaceContainer;
    final unselectedAvatarBg = context.cs.surfaceContainerHigh;
    final textColor = isSelected
        ? context.cs.onSurface
        : context.cs.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            color: isSelected ? selectedBg : Colors.transparent,
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: ThemeConstants.paddingS,
              horizontal: ThemeConstants.paddingXS,
            ),
            child: Column(
              spacing: ThemeConstants.spaceS,
              children: [
                AnimatedSlide(
                  offset: isSelected ? const Offset(0, -0.1) : Offset.zero,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  child: Container(
                    width: 56,
                    height: 56,
                    clipBehavior: Clip.hardEdge,
                    decoration: AppDecorations.box(
                      shape: .circle,
                      color: isSelected
                          ? context.cs.primary.withValues(alpha: 0.08)
                          : unselectedAvatarBg,
                      border: isSelected
                          ? Border.all(
                              color: context.cs.primary.withValues(alpha: 0.4),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: isSelected ? Curves.elasticOut : Curves.easeOut,
                        width: isSelected ? 58 : 28,
                        height: isSelected ? 58 : 28,
                        child: AppNetworkImage(url: category.imageUrl ?? ''),
                      ),
                    ),
                  ),
                ),
                AppText(
                  name,
                  style: context.tt.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                    height: 1.3,
                  ),
                  textAlign: .center,
                  maxLines: 2,
                  overflow: .ellipsis,
                ),
              ],
            ),
          ),
          if (isSelected)
            PositionedDirectional(
              end: 0,
              top: 2,
              bottom: 2,
              child: Container(
                width: 3.5,
                decoration: AppDecorations.box(
                  color: context.cs.primary,
                  borderRadius: AppRadius.left30,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
