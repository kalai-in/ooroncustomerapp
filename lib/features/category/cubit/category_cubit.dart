import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/models/paginated_response.dart';
import 'package:customer/core/configs/app_config.dart';
import 'package:customer/features/category/models/category_model.dart';
import 'package:customer/features/category/repositories/category_repository.dart';

class CategoryCubit extends BasePaginationCubit<Category> {
  final CategoryRepository _repo;

  CategoryCubit({CategoryRepository? repository})
    : _repo = repository ?? CategoryRepository();

  @override
  PaginationFetcher<Category> get fetcher =>
      (offset) =>
          _repo.getCategories(offset: offset, limit: AppConfig.pageLimit);

  // Category API may not return a reliable total — use page-count check instead.
  @override
  bool computeHasMore(
    PaginatedResponse<Category> response,
    List<Category> allData,
  ) => response.data.length >= AppConfig.pageLimit;

  void loadCategories() => fetchInitial();
  Future<void> loadMore() => fetchMore();
}
