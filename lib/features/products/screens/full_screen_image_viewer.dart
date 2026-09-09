import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:flutter/material.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/core/constants/theme_constants.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late ScrollController _thumbnailController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbnailController = ScrollController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  void _scrollToThumbnail(int index) {
    final thumbnailWidth = 80.0;
    final offset =
        (index * (thumbnailWidth + 8)) -
        (context.screenWidth / 2 - thumbnailWidth / 2);
    _thumbnailController.animateTo(
      offset.clamp(0.0, _thumbnailController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: context.cs.surface,
      appBar: CustomAppBar(
        title: '${_currentIndex + 1} / ${widget.images.length}',
        showBackButton: false,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingS),
            child: CircleAvatar(
              backgroundColor: context.cs.onSurface,
              child: IconButton(
                icon: AppSvgIcon(
                  AssetsConstants.closeIcon,
                  color: context.cs.surface,
                ),
                onPressed: () => AppNavigator.pop(context),
                iconSize: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _scrollToThumbnail(index);
              },
              itemCount: widget.images.length,
              itemBuilder: (_, i) => Center(
                child: AppNetworkImage(
                  url: widget.images[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (widget.images.length > 1) ...[
            AppSpacing.h12,
            SizedBox(
              height: 80,
              child: ListView.builder(
                controller: _thumbnailController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: ThemeConstants.paddingM),
                itemCount: widget.images.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: ThemeConstants.paddingS),
                  child: GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 80,
                      decoration: AppDecorations.box(
                        border: Border.all(
                          color: _currentIndex == i
                              ? context.cs.primary
                              : context.cs.outlineVariant,
                          width: _currentIndex == i ? 2 : 1,
                        ),
                        borderRadius: AppRadius.r8,
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.r6,
                        child: AppNetworkImage(
                          url: widget.images[i],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AppSpacing.h12,
          ],
        ],
      ),
    );
  }
}
