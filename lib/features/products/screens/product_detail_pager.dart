import 'dart:ui';

import 'package:customer/features/cart/cubit/cart_recommendations_cubit.dart';
import 'package:customer/features/products/cubit/add_recently_visited_product_cubit.dart';
import 'package:customer/features/products/cubit/product_detail_cubit.dart';
import 'package:customer/features/products/cubit/rating_images_cubit.dart';
import 'package:customer/features/products/cubit/ratings_list_cubit.dart';
import 'package:customer/features/products/cubit/recently_visited_cubit.dart';
import 'package:customer/features/products/cubit/similar_product_cubit.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/features/products/screens/product_detail_screen.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Hosts the product detail screen(s) opened from a list. With a sibling
/// [productList] (length > 1) it renders a horizontally swipeable
/// PageView with a ~15% peek of neighbouring products at rest, like a
/// stack of cards. A single-product entry point (no list, or list of 1 —
/// e.g. deep links/notifications) falls back to one plain full page.
class ProductDetailPager extends StatefulWidget {
  final int productId;
  final String? initialImageUrl;
  final String heroSuffix;
  final List<ProductDataModel>? productList;
  final int initialIndex;

  const ProductDetailPager({
    super.key,
    required this.productId,
    this.initialImageUrl,
    this.heroSuffix = '',
    this.productList,
    this.initialIndex = 0,
  });

  @override
  State<ProductDetailPager> createState() => _ProductDetailPagerState();
}

class _ProductDetailPagerState extends State<ProductDetailPager> {
  static const double _viewportFraction = 0.92;

  late final List<ProductDataModel> _products;
  late PageController _pageController;

  /// PageView keeps neighbouring pages mounted at once, and every page's
  /// main image hero tag must match its own real card (see [_buildPage]).
  /// If two mounted pages both carried a real, matching tag at pop time,
  /// Flutter would fly *both* Heroes back simultaneously. So only the
  /// currently-active (visible) page gets the real tag — every other
  /// mounted-but-offscreen page gets an inert one instead.
  late int _activeIndex;

  /// Whether the active page is fully scrolled-up to true full screen.
  /// While true, the PageController is swapped to viewportFraction 1 so
  /// expanding ever reaches a real edge-to-edge width with no residual
  /// side gap — the peek fraction only applies while collapsed.
  bool _activeIsExpanded = false;

  /// Upsell isn't per-product (no such endpoint) — same cart-wide block
  /// used at checkout — so one cubit, fetched once, is shared by every
  /// page instead of refetching per swiped-to product.
  final CartRecommendationsCubit _recommendationsCubit =
      CartRecommendationsCubit();

  @override
  void initState() {
    super.initState();
    _recommendationsCubit.fetchRecommendations();
    final list = widget.productList;
    _products = (list != null && list.isNotEmpty)
        ? list
        : [
            ProductDataModel(
              id: widget.productId,
              images: widget.initialImageUrl != null
                  ? [Images(imageUrl: widget.initialImageUrl)]
                  : null,
            ),
          ];
    _activeIndex = widget.initialIndex.clamp(0, _products.length - 1);
    _pageController = PageController(
      viewportFraction: _products.length > 1 ? _viewportFraction : 1,
      initialPage: _activeIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _recommendationsCubit.close();
    super.dispose();
  }

  void _setActiveExpanded(bool expanded) {
    if (_activeIsExpanded == expanded || _products.length <= 1) return;
    // Deferred a frame: this can be called from PageView's own
    // onPageChanged callback, and disposing the controller that's still
    // mid-notify (driving that very callback) would throw.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _activeIsExpanded == expanded) return;
      final oldController = _pageController;
      setState(() {
        _activeIsExpanded = expanded;
        _pageController = PageController(
          viewportFraction: expanded ? 1 : _viewportFraction,
          initialPage: _activeIndex,
        );
      });
      oldController.dispose();
    });
  }

  Widget _buildPage(BuildContext context, int index) {
    final product = _products[index];
    // Only the active page's main image hero tag matches its real card —
    // see the [_activeIndex] doc above for why. Inactive pages get an
    // inert tag so Flutter never tries to fly their Hero too.
    final isActive = index == _activeIndex;
    final mainHeroSuffix = isActive
        ? widget.heroSuffix
        : '${widget.heroSuffix}_offscreen$index';
    // Every page's ProductDetailScreen also renders its own Similar/
    // Recently-Visited sections (hero tags like `product_hero_<id>_sp`) —
    // two concurrently-mounted pages can list the same "similar" product,
    // so those nested section tags always get a page-scoped suffix to
    // dodge duplicate-Hero-tag crashes, independent of active/inactive.
    final subSectionHeroSuffix = '${widget.heroSuffix}_pg$index';
    final page = MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ProductDetailCubit()),
        BlocProvider(create: (_) => SimilarProductCubit()),
        BlocProvider(create: (_) => RecentlyVisitedCubit()),
        BlocProvider(create: (_) => AddRecentlyVisitedProductCubit()),
        BlocProvider(create: (_) => RatingsListCubit()),
        BlocProvider(create: (_) => RatingImagesCubit()),
        BlocProvider.value(value: _recommendationsCubit),
      ],
      child: ProductDetailScreen(
        productId: product.id ?? widget.productId,
        initialImageUrl: index == widget.initialIndex
            ? widget.initialImageUrl
            : (product.images?.isNotEmpty == true
                  ? product.images!.first.imageUrl
                  : null),
        heroSuffix: mainHeroSuffix,
        subSectionHeroSuffix: subSectionHeroSuffix,
        onFullyExpanded: isActive ? () => _setActiveExpanded(true) : null,
        onCollapsed: isActive ? () => _setActiveExpanded(false) : null,
        targetVariantId: product.variantId,
      ),
    );

    return page;
  }

  @override
  Widget build(BuildContext context) {
    if (_products.length <= 1) {
      return _buildPage(context, 0);
    }
    return ClipRect(
      // Matches the per-page dark scrim (see ProductDetailScreen) so any
      // visible gap (e.g. PageView's own end-padding at the first/last
      // page, which has no real neighbour to peek into) reads as part of
      // the same dark backdrop instead of a stray white flash. Middle
      // pages still get symmetric prev+next peek via padEnds' default
      // (true) — only the missing-neighbour edges needed this. Uses the
      // same frosted blur + tint as each page's own scrim (rather than a
      // flat opaque color) so the screen underneath actually shows
      // through dimmed/blurred, like a dialog backdrop — a solid color
      // here would otherwise paint over it before any page's own
      // BackdropFilter gets a chance to blur it.
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ColoredBox(
          color: context.cs.scrim.withValues(alpha: 0.55),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _products.length,
            // Swipe between products only while collapsed/peeking — once the
            // active page is fullscreen, horizontal drag shouldn't fight its
            // own content's gestures (e.g. image carousel, variant chips).
            physics: _activeIsExpanded
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _activeIndex = index);
              // A freshly-swiped-to page always starts collapsed.
              _setActiveExpanded(false);
            },
            itemBuilder: _buildPage,
          ),
        ),
      ),
    );
  }
}
