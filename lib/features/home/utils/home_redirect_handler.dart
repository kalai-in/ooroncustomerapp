import 'package:customer/commons/utils/url_launcher_helper.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/routes/category_redirect_args.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/features/home/models/enums/redirect_type.dart';
import 'package:customer/features/products/cubit/product_cubit.dart';
import 'package:customer/features/products/screens/product_screen.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shared tap-target resolution for home layout blocks (banner carousel,
/// grid banner, title image, text section) — a redirect_url wins over
/// redirect_type/id; product/category/brand each navigate to their own
/// screen, anything else (including [RedirectType.none]) is a no-op.
/// [hasChild] mirrors each caller's own `item.hasChild ?? true` /
/// `block.hasChild ?? true` fallback — pass the source model's field as-is.
/// [skipUrlWhenTypeNone] mirrors title-image/text-section's original order
/// (bail out on `RedirectType.none` before even checking the url), vs.
/// banner-carousel/grid-banner which open the url regardless of type.
void handleHomeRedirectTap(
  BuildContext context, {
  required String? redirectType,
  required int? redirectId,
  required String? redirectUrl,
  bool? hasChild,
  bool skipUrlWhenTypeNone = false,
}) {
  final type = RedirectType.fromRaw(redirectType);
  final id = redirectId;
  final url = redirectUrl;

  if (skipUrlWhenTypeNone && type == RedirectType.none) return;

  if (url != null && url.isNotEmpty) {
    openExternalUrl(url);
    return;
  }
  if (type == RedirectType.product && id != null) {
    AppNavigator.pushNamed(context, RouteNames.productDetail, arguments: id);
    return;
  }
  if (type == RedirectType.category && id != null) {
    AppNavigator.pushNamed(
      context,
      RouteNames.categories,
      arguments: CategoryRedirectArgs(
        categoryId: id.toString(),
        hasChild: hasChild ?? true,
      ),
    );
    return;
  }
  if (type == RedirectType.brand && id != null) {
    AppNavigator.push(
      context,
      BlocProvider(
        create: (_) => ProductCubit(),
        child: ProductScreen(
          title: context.translate(LanguageLabelKeys.brand),
          brandId: id.toString(),
        ),
      ),
    );
    return;
  }
}
