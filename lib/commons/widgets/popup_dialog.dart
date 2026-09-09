import 'package:customer/commons/models/app_settings_model.dart';
import 'package:customer/commons/utils/url_launcher_helper.dart';
import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/core/routes/product_detail_args.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:flutter/material.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/constants/theme_constants.dart';

class PopupDialog extends StatelessWidget {
  final AppSettingsData settings;

  const PopupDialog({super.key, required this.settings});

  static bool _shownThisSession = false;

  static void maybeShow(BuildContext context) {
    final settings = SettingsHiveBox.instance.getAppSettings();
    if (settings == null) return;
    if (settings.popupEnabled != '1') return;

    final alwaysShow = settings.popupAlwaysShowHome == '1';
    if (!alwaysShow && _shownThisSession) return;

    _shownThisSession = true;
    showDialog(
      context: context,
      barrierColor: context.cs.scrim.withValues(alpha: 0.54),
      builder: (_) => PopupDialog(settings: settings),
    );
  }

  void _handleTap(BuildContext context) {
    AppNavigator.pop(context);
    final type = settings.popupType ?? '';
    final typeId = settings.popupTypeId ?? '';
    final url = settings.popupUrl ?? '';

    if (type == 'product') {
      final id = int.tryParse(typeId);
      if (id != null) {
        AppNavigator.pushNamed(
          context,
          RouteNames.productDetail,
          arguments: ProductDetailArgs(productId: id),
        );
      }
    } else if (type == 'category') {
      AppNavigator.pushNamed(context, RouteNames.categories);
    } else if (type == 'popup_url' && url.isNotEmpty) {
      openExternalUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = context.screenWidth;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: ThemeConstants.spaceXXXL, vertical: ThemeConstants.paddingXXL),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Image
          GestureDetector(
            onTap: () => _handleTap(context),
            child: ClipRRect(
              borderRadius: AppRadius.r16,
              child: SizedBox(
                width: sw,
                child: AppNetworkImage(
                  url: settings.popupImage ?? '',
                  fit: BoxFit.cover,
                  placeholder: Container(
                    height: 260,
                    color: context.cs.surfaceContainerHighest,
                  ),
                  errorWidget: const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // Close button — top-end corner overlapping image
          PositionedDirectional(
            top: -14,
            end: -14,
            child: GestureDetector(
              onTap: () => AppNavigator.pop(context),
              child: Container(
                width: 30,
                height: 30,
                decoration: AppDecorations.box(
                  color: context.cs.primary,
                  shape: .circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.cs.scrim.withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: AppSvgIcon(
                  AssetsConstants.closeIcon,
                  color: context.cs.onInverseSurface,
                  size: 24,
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
