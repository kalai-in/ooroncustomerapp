import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

/// Solid-color header sitting above the map (Blinkit/Zomato style) — big bold
/// "Your order #123 is on its way" with a "Reaching you soon" subline. Only
/// carries the back button; recenter now floats over the map itself.
class OrderTrackingTopBar extends StatelessWidget {
  final int? orderId;
  final VoidCallback onBack;

  const OrderTrackingTopBar({
    super.key,
    required this.orderId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final onPrimary = context.cs.onPrimary;
    return Container(
      width: double.infinity,
      color: context.cs.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingM, ThemeConstants.paddingS, ThemeConstants.paddingL, ThemeConstants.paddingL),
          child: Row(
            crossAxisAlignment: .center,
            spacing: 12,
            children: [
              _HeaderButton(
                onTap: onBack,
                icon: AssetsConstants.arrowLeftIcon,
                onPrimary: onPrimary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 2,
                  children: [
                    AppText(
                      '${context.translate(LanguageLabelKeys.yourOrder)} '
                      '${AppConstants.hashSymbol}$orderId '
                      '${context.translate(LanguageLabelKeys.isOnItsWay)}',
                      style: context.tt.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: onPrimary,
                      ),
                      maxLines: 2,
                      overflow: .ellipsis,
                    ),
                    AppText(
                      context.translate(LanguageLabelKeys.reachingYouSoon),
                      style: context.tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final VoidCallback onTap;
  final String icon;
  final Color onPrimary;

  const _HeaderButton({
    required this.onTap,
    required this.icon,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingS),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: AppSvgIcon(icon, size: 18, color: onPrimary),
        ),
      ),
    );
  }
}
