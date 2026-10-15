import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/api/api_exception.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/features/home/models/page_builder_model.dart';
import 'package:customer/features/home/repositories/page_builder_repository.dart';
import 'package:customer/core/localization/services/localization_service.dart';
import 'package:customer/core/localization/language_label_key.dart';

sealed class PageBuilderState {}

final class PageBuilderInitial extends PageBuilderState {}

final class PageBuilderLoading extends PageBuilderState {}

final class PageBuilderLoaded extends PageBuilderState {
  final PageBuilderModel pageLayout;
  final bool isLoadingMore;
  final bool hasMore;
  PageBuilderLoaded(
    this.pageLayout, {
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  PageBuilderLoaded copyWith({
    PageBuilderModel? pageLayout,
    bool? isLoadingMore,
    bool? hasMore,
  }) => PageBuilderLoaded(
    pageLayout ?? this.pageLayout,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
  );
}

final class PageBuilderError extends PageBuilderState {
  final String message;
  PageBuilderError(this.message);
}

class PageBuilderCubit extends Cubit<PageBuilderState> {
  final PageBuilderRepository _repository;

  PageBuilderCubit({PageBuilderRepository? repository})
    : _repository = repository ?? PageBuilderRepository(),
      super(PageBuilderInitial());

  int _generation = 0;
  String? _currentId;
  int _offset = 0;

  static const int _limit = AppConstants.homeSectionsPageLimit;

  Future<void> loadPageBuilder({required String id}) async {
    final generation = ++_generation;
    _currentId = id;
    _offset = 0;
    try {
      emit(PageBuilderLoading());
      final result = await _repository.getPageBuilder(
        id: id,
        offset: _offset,
        limit: _limit,
      );
      if (generation != _generation) return;
      final sectionCount = result.data?.page?.sections?.length ?? 0;
      _offset = sectionCount;
      final total = result.data?.totalSections;
      emit(
        PageBuilderLoaded(
          result,
          hasMore: total != null ? _offset < total : sectionCount >= _limit,
        ),
      );
    } on ApiException catch (e) {
      if (generation != _generation) return;
      emit(PageBuilderError(e.message));
    } catch (_) {
      if (generation != _generation) return;
      emit(
        PageBuilderError(
          LocalizationService.instance.translate(
            LanguageLabelKeys.somethingWentWrong,
          ),
        ),
      );
    }
  }

  Future<void> loadMoreSections() async {
    final current = state;
    if (current is! PageBuilderLoaded ||
        current.isLoadingMore ||
        !current.hasMore ||
        _currentId == null) {
      return;
    }
    final generation = _generation;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.getPageBuilder(
        id: _currentId!,
        offset: _offset,
        limit: _limit,
      );
      if (generation != _generation) return;
      final newSections = result.data?.page?.sections ?? [];
      final mergedSections = [
        ...?current.pageLayout.data?.page?.sections,
        ...newSections,
      ];
      current.pageLayout.data?.page?.sections = mergedSections;
      _offset += newSections.length;
      final total =
          result.data?.totalSections ?? current.pageLayout.data?.totalSections;
      emit(
        current.copyWith(
          pageLayout: current.pageLayout,
          isLoadingMore: false,
          hasMore: total != null
              ? _offset < total
              : newSections.length >= _limit,
        ),
      );
    } on ApiException catch (_) {
      if (generation != _generation) return;
      emit(current.copyWith(isLoadingMore: false));
    } catch (_) {
      if (generation != _generation) return;
      emit(current.copyWith(isLoadingMore: false));
    }
  }
}
