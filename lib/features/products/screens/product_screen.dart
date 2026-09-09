import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/utils/pagination_scroll_controller.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/features/category/widgets/sub_category_filter_bar.dart';
import 'package:customer/features/main/widgets/floating_cart_bar.dart';
import 'package:customer/features/products/cubit/filter_cubit.dart';
import 'package:customer/features/products/cubit/product_cubit.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/commons/widgets/grid_list_toggle.dart';
import 'package:customer/commons/widgets/product_listing_view.dart';
import 'package:customer/features/products/widgets/product_card_skeleton.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/core/constants/theme_constants.dart';

typedef _ProductState = PaginationState<ProductDataModel>;
typedef _ProductLoaded = PaginationLoaded<ProductDataModel>;
typedef _ProductError = PaginationError<ProductDataModel>;
typedef _ProductLoading = PaginationLoading<ProductDataModel>;
typedef _ProductInitial = PaginationInitial<ProductDataModel>;

class ProductScreen extends StatefulWidget {
  final String title;

  /// Pre-fetched list (recently-visited/similar-products already hold the
  /// full set) — renders statically with no API call when provided.
  final List<ProductDataModel>? products;
  final String? categoryId;
  final String? dataSource;
  final String? manualProductIds;
  final String? brandId;

  const ProductScreen({
    super.key,
    required this.title,
    this.products,
    this.categoryId,
    this.dataSource,
    this.manualProductIds,
    this.brandId,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final _pager = PaginationScrollController(
    onLoadMore: () => context.read<ProductCubit>().loadMore(),
  );
  bool _isGrid = true;

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  int _crossAxisCount(BuildContext context) => _isTablet(context) ? 5 : 3;

  bool get _isStatic => widget.products != null;

  FilterCubit? _filterCubit;

  @override
  void initState() {
    super.initState();
    if (!_isStatic) {
      context.read<ProductCubit>().loadProducts(
        categoryId: widget.categoryId ?? '',
        dataSource: widget.dataSource,
        manualProductIds: widget.manualProductIds,
        brandId: widget.brandId,
        isGrid: _isGrid,
      );
      _filterCubit = FilterCubit()
        ..loadFilters(
          categoryId: widget.categoryId,
          dataSource: widget.dataSource,
          manualProductIds: widget.manualProductIds,
        );
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    _filterCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);

    return AppScaffold(
      backgroundColor: bg,
      appBar: CustomAppBar(
        title: widget.title,
        actions: [
          GridListToggle(
            isGrid: _isGrid,
            onToggle: (val) {
              setState(() => _isGrid = val);
              if (!_isStatic) {
                context.read<ProductCubit>().setGridView(val);
                if (_pager.controller.hasClients) {
                  _pager.controller.jumpTo(0);
                }
              }
            },
          ),
          AppSpacing.w12,
        ],
      ),
      body: Stack(
        children: [
          _isStatic
              ? _buildStaticGrid(widget.products!)
              : BlocProvider.value(
                  value: _filterCubit!,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final cubit = context.read<ProductCubit>();
                      cubit.refresh();
                      await cubit.stream.firstWhere(
                        (s) => s is! _ProductLoading,
                      );
                    },
                    child: _buildLiveGrid(),
                  ),
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FloatingCartBar(
              onViewCart: () =>
                  AppNavigator.pushNamed(context, RouteNames.checkout),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticGrid(List<ProductDataModel> products) {
    if (products.isEmpty) {
      return Center(
        child: AppText(context.translate(LanguageLabelKeys.noProductsFound)),
      );
    }
    return ProductListingView(products: products, isGrid: _isGrid);
  }

  Widget _buildLiveGrid() {
    return BlocBuilder<ProductCubit, _ProductState>(
      builder: (context, state) {
        if (state is _ProductLoading || state is _ProductInitial) {
          return _isGrid
              ? ProductGridSkeleton(
                  crossAxisCount: _crossAxisCount(context),
                  edgePad: 32,
                  spacing: 10 * (_isTablet(context) ? 1.75 : 1.0),
                  mainAxisSpacing: 16 * (_isTablet(context) ? 1.75 : 1.0),
                )
              : const ProductListSkeleton();
        }
        if (state is _ProductError) {
          return EmptyStateWidget(
            imagePath: AssetsConstants.noSearchFound,
            title: state.message,
            subtitle: context.translate(LanguageLabelKeys.pullToRefresh),
            onRetry: () => context.read<ProductCubit>().loadProducts(
              categoryId: widget.categoryId ?? '',
              dataSource: widget.dataSource,
              manualProductIds: widget.manualProductIds,
              brandId: widget.brandId,
              isGrid: _isGrid,
            ),
          );
        }
        if (state is _ProductLoaded) {
          return Column(
            children: [
              SubCategoryFilterBar(state: state),
              Expanded(
                child: state.data.isEmpty
                    ? EmptyStateWidget(
                        imagePath: AssetsConstants.noSearchFound,
                        title: context.translate(
                          LanguageLabelKeys.noProductsFound,
                        ),
                        subtitle: context.translate(
                          LanguageLabelKeys.noProductsFoundSubtitle,
                        ),
                      )
                    : ProductListingView(
                        products: state.data,
                        isGrid: _isGrid,
                        controller: _pager.controller,
                        isFetchingMore: state.isFetchingMore,
                        padding: EdgeInsetsDirectional.fromSTEB(
                          ThemeConstants.paddingL,
                          ThemeConstants.paddingL,
                          ThemeConstants.paddingL,
                          ThemeConstants.paddingL +
                              (context.select(
                                    (CartCubit c) => c.state.totalItems > 0,
                                  )
                                  ? FloatingCartBar.barHeight
                                  : 0),
                        ),
                      ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
