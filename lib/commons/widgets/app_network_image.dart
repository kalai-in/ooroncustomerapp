import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:flutter/material.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.errorIconSize = 24.0,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final double errorIconSize;
  final Widget? placeholder;
  final Widget? errorWidget;

  static ImageProvider provider(String url) => CachedNetworkImageProvider(url);

  static bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('HTTP') || uri.isScheme('HTTPS'));
  }

  static bool _isSvgUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.path.toLowerCase().endsWith('.svg');
  }

  // Hard ceiling on decode dimension (logical px) so an oversized source
  // image can never blow past this regardless of KB/MB file size on disk.
  static const double _maxCacheDimension = 1024;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty || !_isValidUrl(url)) {
      final empty = errorWidget ?? _placeholder(context);
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: empty)
          : empty;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);

        double? logicalWidth = width;
        if (logicalWidth == null && constraints.maxWidth.isFinite) {
          logicalWidth = constraints.maxWidth;
        }
        double? logicalHeight = height;
        if (logicalHeight == null && constraints.maxHeight.isFinite) {
          logicalHeight = constraints.maxHeight;
        }

        // Only force the hard cap onto BOTH dims when neither is known —
        // that's the unbounded-decode worst case. If one dim is known,
        // leave the other null so the codec keeps aspect ratio.
        final neitherKnown = logicalWidth == null && logicalHeight == null;

        final resolvedMemCacheWidth =
            memCacheWidth ??
            (logicalWidth != null
                ? (logicalWidth.clamp(0, _maxCacheDimension) * dpr).round()
                : (neitherKnown ? (_maxCacheDimension * dpr).round() : null));
        final resolvedMemCacheHeight =
            memCacheHeight ??
            (logicalHeight != null
                ? (logicalHeight.clamp(0, _maxCacheDimension) * dpr).round()
                : (neitherKnown ? (_maxCacheDimension * dpr).round() : null));

        final img = _isSvgUrl(url)
            ? SvgPicture.network(
                url,
                width: width,
                height: height,
                fit: fit,
                placeholderBuilder: (_) => placeholder ?? _placeholder(context),
                errorBuilder: (_, _, _) => errorWidget ?? _placeholder(context),
              )
            : CachedNetworkImage(
                imageUrl: url,
                width: width,
                height: height,
                fit: fit,
                memCacheWidth: resolvedMemCacheWidth,
                memCacheHeight: resolvedMemCacheHeight,
                placeholder: (_, _) => placeholder ?? _placeholder(context),
                errorWidget: (_, _, _) => errorWidget ?? _placeholder(context),
              );

        if (borderRadius != null) {
          return ClipRRect(borderRadius: borderRadius!, child: img);
        }
        return img;
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: 0.4,
        heightFactor: 0.4,
        child: AppSvgIcon(AssetsConstants.placeholder, fit: BoxFit.contain),
      ),
    );
  }
}
