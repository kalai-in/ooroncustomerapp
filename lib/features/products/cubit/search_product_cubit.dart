import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/models/paginated_response.dart';
import 'package:customer/core/configs/app_config.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/services/analytics_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/api/hive_box_keys.dart';
import '../models/product_model.dart';
import '../models/product_sort_type.dart';
import '../repositories/product_repository.dart';

const int _kMaxRecentSearches = 10;

// ── Filter ───────────────────────────────────────────────────────────────────
class SearchFilter {
  final String query;
  final ProductSortType sort;

  const SearchFilter({
    required this.query,
    this.sort = ProductSortType.defaultSort,
  });

  SearchFilter copyWith({String? query, ProductSortType? sort}) =>
      SearchFilter(query: query ?? this.query, sort: sort ?? this.sort);
}

// ── Cubit ────────────────────────────────────────────────────────────────────
// Filter is query + sort. Access the active sort via `currentFilters.sort`
// (do not store it on the emitted state).
class SearchProductCubit
    extends FilteredPaginationCubit<ProductDataModel, SearchFilter> {
  final ProductRepository _repository;
  List<String> _recentSearches = [];

  // See ProductCubit for why grid page size differs from list.
  bool _isGrid = true;
  int get _limit => _isGrid ? AppConfig.gridPageLimit : AppConfig.pageLimit;

  SearchProductCubit({ProductRepository? repository})
    : _repository = repository ?? ProductRepository(),
      super(const SearchFilter(query: '')) {
    _recentSearches = _loadRecentSearches();
  }

  List<String> get recentSearches => _recentSearches;

  List<String> _loadRecentSearches() {
    final box = Hive.box(settingsBox);
    final stored = box.get(kRecentProductSearches);
    if (stored is List) {
      return stored.map((e) => e.toString()).toList();
    }
    return [];
  }

  void _saveRecentSearch(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    _recentSearches.removeWhere(
      (q) => q.toLowerCase() == normalized.toLowerCase(),
    );
    _recentSearches.insert(0, normalized);
    if (_recentSearches.length > _kMaxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _kMaxRecentSearches);
    }
    Hive.box(settingsBox).put(kRecentProductSearches, _recentSearches);
  }

  void removeRecentSearch(String query) {
    _recentSearches.remove(query);
    Hive.box(settingsBox).put(kRecentProductSearches, _recentSearches);
    if (state is PaginationInitial<ProductDataModel>) {
      emit(const PaginationInitial());
    }
  }

  void clearRecentSearches() {
    _recentSearches = [];
    Hive.box(settingsBox).delete(kRecentProductSearches);
    if (state is PaginationInitial<ProductDataModel>) {
      emit(const PaginationInitial());
    }
  }

  @override
  PaginationFetcher<ProductDataModel> buildFetcher(SearchFilter f) =>
      (offset) async {
        final result = await _repository.searchProducts(
          offset: offset,
          limit: _limit,
          search: f.query,
          sort: f.sort.apiValue,
        );
        return PaginatedResponse(
          data: result.data ?? [],
          total: result.total ?? 0,
        );
      };

  // Mirrors the previous per-page-length hasMore check (rather than a
  // total-based one).
  @override
  bool computeHasMore(
    PaginatedResponse<ProductDataModel> response,
    List<ProductDataModel> allData,
  ) => response.data.length >= _limit;

  // Empty query shows recent searches instead of hitting the API.
  @override
  Future<void> fetchInitial() async {
    if (currentFilters.query.isEmpty) {
      emit(const PaginationInitial());
      return;
    }
    await super.fetchInitial();
  }

  // Live-as-you-type search (debounced) — fetches results but does NOT save
  // to recent-search history, or every intermediate keystroke ("pi", "piz",
  // "pizz"...) would show up as its own history entry.
  Future<void> search(String query) =>
      applyFilters(currentFilters.copyWith(query: query.trim()));

  // Explicit submit (search action/enter key, or re-tapping a recent-search
  // chip) — this is the only path that writes to recent-search history.
  Future<void> submitSearch(String query) async {
    final normalized = query.trim();
    await search(normalized);
    if (normalized.isNotEmpty && state is PaginationLoaded<ProductDataModel>) {
      _saveRecentSearch(normalized);
      AnalyticsService.instance.logEvent(
        AppConstants.eventSearch,
        parameters: {AppConstants.paramSearchTerm: normalized},
      );
    }
  }

  // Re-fetches from the top with the other page size. No-op on the recent-
  // searches screen (empty query) since that path never hits the API.
  Future<void> setGridView(bool isGrid) {
    if (_isGrid == isGrid) return Future.value();
    _isGrid = isGrid;
    if (currentFilters.query.isEmpty) return Future.value();
    return applyFilters(currentFilters);
  }

  Future<void> applySort(ProductSortType sort) {
    if (currentFilters.sort == sort) return Future.value();
    return applyFilters(currentFilters.copyWith(sort: sort));
  }

  void clear() => applyFilters(
    const SearchFilter(query: '', sort: ProductSortType.defaultSort),
  );
}
