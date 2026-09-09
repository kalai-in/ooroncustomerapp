import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/features/cart/cubit/guest_cart_fetch_cubit.dart';
import 'package:customer/features/cart/models/cart_model.dart';
import 'package:customer/features/checkout/widgets/checkout_bill_section.dart';
import 'package:customer/features/checkout/widgets/checkout_cart_items_section.dart';
import 'package:customer/features/checkout/widgets/checkout_place_order_bar.dart';
import 'package:customer/features/checkout/widgets/checkout_recommendations_section.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The logged-out checkout body — read-only cart + bill preview, ending in a
/// "log in to checkout" prompt instead of the real place-order flow.
class CheckoutGuestBody extends StatelessWidget {
  const CheckoutGuestBody({
    super.key,
    required this.cartData,
    required this.currency,
    required this.onLoginAndCheckout,
  });

  final CartData cartData;
  final String currency;
  final VoidCallback onLoginAndCheckout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: context.cs.primary,
            onRefresh: () {
              final entries = context.read<CartCubit>().state.entries;
              return context.read<GuestCartFetchCubit>().fetchGuestCart(
                variantIds: entries.keys.toList(),
                quantities: entries.values
                    .map((e) => e.quantity.toString())
                    .toList(),
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingM, ThemeConstants.paddingL, 0),
              children: [
                CheckoutCartItemsSection(
                  cartData: cartData,
                  currency: currency,
                ),
                AppSpacing.h12,
                const CheckoutRecommendationsSection(),
                CheckoutBillDetailsSection(
                  cartData: cartData,
                  currency: currency,
                  appliedPromo: null,
                ),
                AppSpacing.h100,
              ],
            ),
          ),
        ),
        CheckoutPlaceOrderBar(
          cartData: cartData,
          currency: currency,
          isLoading: false,
          isLoggedIn: false,
          selectedAddress: null,
          selectedPayment: null,
          onPlaceOrder: () {},
          onChooseAddress: () {},
          onChoosePayment: () {},
          onLoginAndCheckout: onLoginAndCheckout,
        ),
      ],
    );
  }
}
