import 'package:customer/core/api/api_exception.dart';
import 'package:customer/features/cart/models/cart_model.dart';
import 'package:customer/features/cart/repositories/cart_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/localization/services/localization_service.dart';
import 'package:customer/core/localization/language_label_key.dart';

sealed class GuestCartState {}

final class GuestCartInitial extends GuestCartState {}

final class GuestCartLoading extends GuestCartState {}

final class GuestCartLoaded extends GuestCartState {
  final Cart cart;
  GuestCartLoaded(this.cart);
}

final class GuestCartError extends GuestCartState {
  final String message;
  GuestCartError(this.message);
}

class GuestCartFetchCubit extends Cubit<GuestCartState> {
  final CartRepository _repository;

  GuestCartFetchCubit({CartRepository? repository})
    : _repository = repository ?? CartRepository(),
      super(GuestCartInitial());

  /// [silent] = true keeps the current loaded UI visible while refetching
  /// (no Loading state), so qty changes don't flicker the screen.
  Future<void> fetchGuestCart({
    required List<String> variantIds,
    required List<String> quantities,
    bool silent = false,
  }) async {
    try {
      if (variantIds.isEmpty) {
        emit(GuestCartInitial());
        return;
      }
      if (!silent || state is! GuestCartLoaded) emit(GuestCartLoading());
      final result = await _repository.getGuestCart(
        variantIds: variantIds,
        quantities: quantities,
      );
      emit(GuestCartLoaded(result));
    } on ApiException catch (e) {
      emit(GuestCartError(e.message));
    } catch (_) {
      emit(
        GuestCartError(
          LocalizationService.instance.translate(
            LanguageLabelKeys.somethingWentWrong,
          ),
        ),
      );
    }
  }
}
