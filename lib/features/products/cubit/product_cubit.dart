import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/models/paginated_response.dart';
import 'package:customer/core/configs/app_config.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/features/products/models/product_sort_type.dart';
import '../repositories/product_repository.dart';

// ── Filter ──────────────────────────────────────────────────────────────────
class ProductFilter {
  final String categoryId;
  final String? dataSource;
  final String? manualProductIds;
  // Fixed scope (e.g. "products of this brand") — always sent alongside the
  // filter sheet's own brandIds selection, and preserved across sort/filter
  // changes and clearFilters(), unlike brandIds which the user controls.
  final String? brandId;
  final ProductSortType sort;
  final double? minPrice;
  final double? maxPrice;
  final Set<String> brandIds;
  final Set<String> attributeValueIds;

  const ProductFilter({
    required this.categoryId,
    this.dataSource,
    this.manualProductIds,
    this.brandId,
    this.sort = ProductSortType.defaultSort,
    this.minPrice,
    this.maxPrice,
    this.brandIds = const {},
    this.attributeValueIds = const {},
  });

  bool get hasActiveFilters =>
      brandIds.isNotEmpty ||
      attributeValueIds.isNotEmpty ||
      minPrice != null ||
      maxPrice != null;

  ProductFilter copyWithSort(ProductSortType sort) => ProductFilter(
    categoryId: categoryId,
    dataSource: dataSource,
    manualProductIds: manualProductIds,
    brandId: brandId,
    sort: sort,
    minPrice: minPrice,
    maxPrice: maxPrice,
    brandIds: brandIds,
    attributeValueIds: attributeValueIds,
  );

  ProductFilter copyWithFilters({
    double? minPrice,
    double? maxPrice,
    Set<String>? brandIds,
    Set<String>? attributeValueIds,
  }) => ProductFilter(
    categoryId: categoryId,
    dataSource: dataSource,
    manualProductIds: manualProductIds,
    brandId: brandId,
    sort: sort,
    minPrice: minPrice,
    maxPrice: maxPrice,
    brandIds: brandIds ?? const {},
    attributeValueIds: attributeValueIds ?? const {},
  );

  ProductFilter clearFilters() => ProductFilter(
    categoryId: categoryId,
    dataSource: dataSource,
    manualProductIds: manualProductIds,
    brandId: brandId,
  );
}

// ── Cubit ────────────────────────────────────────────────────────────────────
class ProductCubit
    extends FilteredPaginationCubit<ProductDataModel, ProductFilter> {
  final ProductRepository _repository;

  // Response-derived filter metadata (brand list / price bounds) — not part
  // of the current selection, so it lives outside PaginationLoaded<T>.
  List<ProductFilterBrand> _brands = [];
  double _totalMinPrice = 0;
  double _totalMaxPrice = 0;

  List<ProductFilterBrand> get brands => _brands;
  double get totalMinPrice => _totalMinPrice;
  double get totalMaxPrice => _totalMaxPrice;

  // Grid shows more tiles per screen than list rows, so it fetches a larger
  // page. Kept on the cubit (not ProductFilter) since toggling it re-fetches
  // via the same filters rather than counting as a filter change.
  bool _isGrid = true;
  int get _limit => _isGrid ? AppConfig.gridPageLimit : AppConfig.pageLimit;

  ProductCubit({ProductRepository? repository})
    : _repository = repository ?? ProductRepository(),
      super(const ProductFilter(categoryId: ''));

  @override
  bool computeHasMore(
    PaginatedResponse<ProductDataModel> response,
    List<ProductDataModel> allData,
  ) => response.data.length >= _limit;

  @override
  PaginationFetcher<ProductDataModel> buildFetcher(ProductFilter f) =>
      (offset) async {
        final result = await _repository.getProducts(
          offset: offset,
          limit: _limit,
          categoryId: f.categoryId,
          dataSource: f.dataSource,
          manualProductIds: f.manualProductIds,
          sort: f.sort.apiValue,
          minPrice: f.minPrice,
          maxPrice: f.maxPrice,
          brandIds: {if (f.brandId != null) f.brandId!, ...f.brandIds}.toList(),
          attributeValueIds: f.attributeValueIds.toList(),
        );
        _brands = result.brands ?? [];
        _totalMinPrice = result.totalMinPrice ?? 0;
        _totalMaxPrice = result.totalMaxPrice ?? 0;
        return PaginatedResponse(
          data: result.data ?? [],
          total: result.total ?? 0,
        );
      };

  Future<void> loadProducts({
    String categoryId = '',
    String? dataSource,
    String? manualProductIds,
    String? brandId,
    bool isGrid = true,
  }) {
    _isGrid = isGrid;
    return applyFilters(
      ProductFilter(
        categoryId: categoryId,
        dataSource: dataSource,
        manualProductIds: manualProductIds,
        brandId: brandId,
      ),
    );
  }

  Future<void> loadMore() => fetchMore();

  // Re-fetches from the top with the other page size. Loses the current
  // scroll position/accumulated pages by design — the two views paginate
  // independently.
  Future<void> setGridView(bool isGrid) {
    if (_isGrid == isGrid) return Future.value();
    _isGrid = isGrid;
    return applyFilters(currentFilters);
  }

  Future<void> applySort(ProductSortType sort) =>
      applyFilters(currentFilters.copyWithSort(sort));

  Future<void> applyProductFilters({
    double? minPrice,
    double? maxPrice,
    Set<String>? brandIds,
    Set<String>? attributeValueIds,
  }) => applyFilters(
    currentFilters.copyWithFilters(
      minPrice: minPrice,
      maxPrice: maxPrice,
      brandIds: brandIds,
      attributeValueIds: attributeValueIds,
    ),
  );

  Future<void> clearFilters() => applyFilters(currentFilters.clearFilters());
}
