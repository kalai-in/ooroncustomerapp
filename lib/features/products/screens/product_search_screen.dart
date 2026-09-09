import 'package:customer/core/constants/assets_constants.dart';
import 'dart:async';

import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/utils/pagination_scroll_controller.dart';
import 'package:customer/commons/widgets/app_search_filter_bar.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/commons/widgets/grid_list_toggle.dart';
import 'package:customer/commons/widgets/product_listing_view.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/features/main/widgets/floating_cart_bar.dart';
import 'package:customer/features/products/cubit/search_product_cubit.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/features/products/models/product_sort_type.dart';
import 'package:customer/features/products/widgets/product_card_skeleton.dart';
import 'package:customer/features/products/widgets/product_sort_sheet.dart';
import 'package:customer/features/products/widgets/recent_searches_view.dart';
import 'package:customer/features/products/widgets/voice_search_sheet.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/core/theme/app_spacing.dart';

typedef _SearchState = PaginationState<ProductDataModel>;
typedef _SearchLoaded = PaginationLoaded<ProductDataModel>;
typedef _SearchError = PaginationError<ProductDataModel>;
typedef _SearchLoading = PaginationLoading<ProductDataModel>;
typedef _SearchInitial = PaginationInitial<ProductDataModel>;

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  bool _isGrid = true;

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  int _crossAxisCount(BuildContext context) => _isTablet(context) ? 5 : 3;

  final TextEditingController _searchController = TextEditingController();
  late final _pager = PaginationScrollController(
    onLoadMore: () => context.read<SearchProductCubit>().fetchMore(),
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _pager.dispose();
    super.dispose();
  }

  void _openVoiceSearch() {
    showVoiceSearchSheet(
      context,
      onResult: (query) {
        _searchController.text = query;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: query.length),
        );
        _onQuerySubmitted(query);
      },
    );
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<SearchProductCubit>().search(query);
    });
    setState(() {});
  }

  void _onQuerySubmitted(String query) {
    _debounce?.cancel();
    context.read<SearchProductCubit>().submitSearch(query);
  }

  void _onRecentSearchTap(String query) {
    _debounce?.cancel();
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    context.read<SearchProductCubit>().submitSearch(query);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
    return AppScaffold(
      backgroundColor: bg,
      appBar: CustomAppBar(
        title: context.translate(LanguageLabelKeys.search),
        actions: [
          GridListToggle(
            isGrid: _isGrid,
            onToggle: (val) {
              setState(() => _isGrid = val);
              context.read<SearchProductCubit>().setGridView(val);
              if (_pager.controller.hasClients) {
                _pager.controller.jumpTo(0);
              }
            },
          ),
          AppSpacing.w12,
        ],
      ),
      body: Column(
        children: [
          BlocBuilder<SearchProductCubit, _SearchState>(
            buildWhen: (prev, curr) =>
                prev is _SearchLoaded || curr is _SearchLoaded,
            builder: (context, state) {
              final cubit = context.read<SearchProductCubit>();
              final sort = cubit.currentFilters.sort;
              final hasActiveSort = sort != ProductSortType.defaultSort;
              return AppSearchFilterBar(
                searchController: _searchController,
                onSearchChanged: _onQueryChanged,
                onSubmitted: _onQuerySubmitted,
                hintText: context.translate(
                  LanguageLabelKeys.searchProductsHint,
                ),
                filterIcon: AssetsConstants.filterSettingIcon,
                hasDateFilter: hasActiveSort,
                dateRangeLabel: context.translate(LanguageLabelKeys.sortBy),
                onDateRange: () => showProductSortSheet(
                  context,
                  sort,
                  onSelect: cubit.applySort,
                ),
                hasActiveFilters: hasActiveSort,
                onClearFilters: () =>
                    cubit.applySort(ProductSortType.defaultSort),
                onMicTap: _openVoiceSearch,
              );
            },
          ),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    final cubit = context.read<SearchProductCubit>();
                    if (cubit.state is! _SearchLoaded) return;
                    cubit.refresh();
                    await cubit.stream.firstWhere((s) => s is! _SearchLoading);
                  },
                  child: _buildBody(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<SearchProductCubit, _SearchState>(
      builder: (context, state) {
        if (state is _SearchInitial) {
          final recentSearches = context
              .read<SearchProductCubit>()
              .recentSearches;
          if (recentSearches.isNotEmpty) {
            return RecentSearchesView(
              recentSearches: recentSearches,
              onTap: _onRecentSearchTap,
              onRemove: (q) =>
                  context.read<SearchProductCubit>().removeRecentSearch(q),
              onClearAll: () =>
                  context.read<SearchProductCubit>().clearRecentSearches(),
            );
          }
          return EmptyStateWidget(
            imagePath: AssetsConstants.noSearchFound,
            title: context.translate(LanguageLabelKeys.startTypingToSearch),
            subtitle: context.translate(
              LanguageLabelKeys.startTypingToSearchSubtitle,
            ),
          );
        }
        if (state is _SearchLoading) {
          return _isGrid
              ? ProductGridSkeleton(
                  crossAxisCount: _crossAxisCount(context),
                  edgePad: 32,
                  spacing: 10 * (_isTablet(context) ? 1.75 : 1.0),
                  mainAxisSpacing: 16 * (_isTablet(context) ? 1.75 : 1.0),
                )
              : const ProductListSkeleton();
        }
        if (state is _SearchError) {
          return EmptyStateWidget(
            imagePath: AssetsConstants.noSearchFound,
            title: state.message,
            subtitle: context.translate(LanguageLabelKeys.pullToRefresh),
            onRetry: () => context.read<SearchProductCubit>().search(
              _searchController.text,
            ),
          );
        }
        if (state is _SearchLoaded) {
          if (state.data.isEmpty) {
            return EmptyStateWidget(
              imagePath: AssetsConstants.noSearchFound,
              title: context.translate(LanguageLabelKeys.noSearchResults),
              subtitle: context.translate(
                LanguageLabelKeys.noSearchResultsSubtitle,
              ),
            );
          }
          return ProductListingView(
            products: state.data,
            isGrid: _isGrid,
            controller: _pager.controller,
            isFetchingMore: state.isFetchingMore,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
