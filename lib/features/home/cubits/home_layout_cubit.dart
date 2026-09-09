import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/api/api_exception.dart';
import 'package:customer/features/home/models/home_builder_model.dart';
import 'package:customer/features/home/repositories/home_layout_repository.dart';
import 'package:customer/core/localization/services/localization_service.dart';
import 'package:customer/core/localization/language_label_key.dart';

sealed class HomeLayoutState {}

final class HomeLayoutInitial extends HomeLayoutState {}

final class HomeLayoutLoading extends HomeLayoutState {}

final class HomeLayoutLoaded extends HomeLayoutState {
  final HomeBuilderModel homeLayout;
  HomeLayoutLoaded(this.homeLayout);
}

final class HomeLayoutError extends HomeLayoutState {
  final String message;
  HomeLayoutError(this.message);
}

class HomeLayoutCubit extends Cubit<HomeLayoutState> {
  final HomeLayoutRepository _repository;

  HomeLayoutCubit({HomeLayoutRepository? repository})
    : _repository = repository ?? HomeLayoutRepository(),
      super(HomeLayoutInitial());

  int _generation = 0;

  Future<void> loadHomeLayout({String? categoryId}) async {
    final generation = ++_generation;
    try {
      emit(HomeLayoutLoading());
      final result = await _repository.getHomeLayout(categoryId: categoryId);
      // Discard stale response: a newer loadHomeLayout (rapid category-tab
      // or quick/ecommerce channel switch) started after this one and must
      // win, regardless of which network call actually resolves first.
      if (generation != _generation) return;
      emit(HomeLayoutLoaded(result));
    } on ApiException catch (e) {
      if (generation != _generation) return;
      emit(HomeLayoutError(e.message));
    } catch (_) {
      if (generation != _generation) return;
      emit(
        HomeLayoutError(
          LocalizationService.instance.translate(
            LanguageLabelKeys.somethingWentWrong,
          ),
        ),
      );
    }
  }
}
