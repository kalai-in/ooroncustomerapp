import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/local_storage/guest_cart_hive_box.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/features/cart/cubit/guest_cart_sync_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuestCartSyncHelper {
  GuestCartSyncHelper._();

  static ({List<String> ids, List<String> qtys}) _extractLists(
    Map<String, Map<String, dynamic>> entries,
  ) {
    final ids = <String>[];
    final qtys = <String>[];
    for (final e in entries.values) {
      final id = e['variantId'] as String? ?? '';
      if (id.isEmpty) continue;
      ids.add(id);
      qtys.add((e['quantity'] as int? ?? 0).toString());
    }
    return (ids: ids, qtys: qtys);
  }

  static Future<void> syncAndNavigate(BuildContext context) async {
    final quick = _extractLists(
      GuestCartHiveBox.instance.loadEntries(AppConstants.quick),
    );
    final ecommerce = _extractLists(
      GuestCartHiveBox.instance.loadEntries(AppConstants.ecommerce),
    );

    if (quick.ids.isNotEmpty || ecommerce.ids.isNotEmpty) {
      final syncCubit = context.read<GuestCartSyncCubit>();
      try {
        await syncCubit.bulkAddItems(
          quickVariantIds: quick.ids,
          quickQuantities: quick.qtys,
          ecommerceVariantIds: ecommerce.ids,
          ecommerceQuantities: ecommerce.qtys,
        );
      } catch (_) {}
      if (!context.mounted) return;
      // bulkAddItems swallows failures into GuestCartSyncError rather than
      // throwing, so the try/catch above can't detect them — check the
      // resulting state instead. Only wipe the local guest cart once the
      // server confirms the merge; clearing on a failed sync would silently
      // lose the user's cart items.
      if (syncCubit.state is GuestCartSyncSuccess) {
        context.read<CartCubit>().clearAllGuestData();
      }
      context.read<CartCubit>().loadFromApi();
    }

    if (!context.mounted) return;
    AppNavigator.pushNamedAndRemoveUntil(
      context,
      SettingsHiveBox.instance.hasLocation
          ? RouteNames.main
          : RouteNames.locationRequired,
    );
  }
}
