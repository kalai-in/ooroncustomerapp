import 'package:customer/core/api/api_exception.dart';
import 'package:customer/features/cart/repositories/cart_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/localization/services/localization_service.dart';
import 'package:customer/core/localization/language_label_key.dart';

sealed class GuestCartSyncState {}

final class GuestCartSyncInitial extends GuestCartSyncState {}

final class GuestCartSyncLoading extends GuestCartSyncState {}

final class GuestCartSyncSuccess extends GuestCartSyncState {
  final String message;
  GuestCartSyncSuccess(this.message);
}

final class GuestCartSyncError extends GuestCartSyncState {
  final String message;
  GuestCartSyncError(this.message);
}

class GuestCartSyncCubit extends Cubit<GuestCartSyncState> {
  final CartRepository _repository;

  GuestCartSyncCubit({CartRepository? repository})
    : _repository = repository ?? CartRepository(),
      super(GuestCartSyncInitial());

  /// Bulk-adds variant/qty pairs to the cart in one request. Used both for
  /// merging the local guest cart on login and for re-adding order items
  /// (e.g. reorder) — the backend resolves the cart by device/session, so
  /// the same call works whether or not the user is logged in.
  Future<void> bulkAddItems({
    required List<String> quickVariantIds,
    required List<String> quickQuantities,
    required List<String> ecommerceVariantIds,
    required List<String> ecommerceQuantities,
  }) async {
    if (quickVariantIds.isEmpty && ecommerceVariantIds.isEmpty) {
      emit(GuestCartSyncSuccess(''));
      return;
    }
    try {
      emit(GuestCartSyncLoading());
      final message = await _repository.bulkAddToCart(
        quickVariantIds: quickVariantIds,
        quickQuantities: quickQuantities,
        ecommerceVariantIds: ecommerceVariantIds,
        ecommerceQuantities: ecommerceQuantities,
      );
      emit(GuestCartSyncSuccess(message));
    } on ApiException catch (e) {
      emit(GuestCartSyncError(e.message));
    } catch (_) {
      emit(
        GuestCartSyncError(
          LocalizationService.instance.translate(
            LanguageLabelKeys.somethingWentWrong,
          ),
        ),
      );
    }
  }

  void reset() => emit(GuestCartSyncInitial());
}
