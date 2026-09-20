import 'dart:math' as math;

import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/commons/widgets/wave_text.dart';
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
        spacing: ThemeConstants.paddingXS,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: ThemeConstants.paddingL, bottom: ThemeConstants.paddingM),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                WaveText(
                  context.translate(LanguageLabelKeys.recentSearches),
                  style: context.tt.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: AppText(context.translate(LanguageLabelKeys.clearAll)),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: ThemeConstants.spaceS,
            runSpacing: ThemeConstants.spaceS,
            children: recentSearches
                .asMap()
                .entries
                .map(
                  (e) => _RecentSearchChip(
                    query: e.value,
                    index: e.key,
                    onTap: () => onTap(e.value),
                    onRemove: () => onRemove(e.value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentSearchChip extends StatefulWidget {
  final String query;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchChip({
    required this.query,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_RecentSearchChip> createState() => _RecentSearchChipState();
}

// Continuous gentle breathing pulse: each chip softly scales up/down
// forever, phase staggered by index so they don't all move in lockstep.
class _RecentSearchChipState extends State<_RecentSearchChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _phase;

  @override
  void initState() {
    super.initState();
    _phase = (widget.index % 4) * 0.25;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = (_controller.value + _phase) * 2 * math.pi;
        final scale = 1.0 + math.sin(angle) * 0.03;
        return Transform.scale(scale: scale, child: child);
      },
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.r20,
        child: Container(
          padding: const EdgeInsetsDirectional.only(
            start: ThemeConstants.paddingM,
            end: ThemeConstants.paddingXS,
            top: ThemeConstants.paddingXS,
            bottom: ThemeConstants.paddingXS,
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
                size: ThemeConstants.iconXS,
                color: context.cs.onSurfaceVariant,
              ),
              AppSpacing.w6,
              AppText(
                widget.query,
                style: context.tt.bodySmall?.copyWith(
                  fontSize: 13,
                  color: context.cs.onSurface,
                ),
              ),
              AppSpacing.w4,
              InkWell(
                onTap: widget.onRemove,
                borderRadius: AppRadius.r20,
                child: AppSvgIcon(
                  AssetsConstants.closeIcon,
                  size: ThemeConstants.iconXS,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
