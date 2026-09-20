import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/utils/extensions/num_extensions.dart';
import 'dart:async';
import 'dart:io';

import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/commons/widgets/app_success_dialog.dart';
import 'package:customer/core/local_storage/auth_hive_box.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/routes/order_detail_args.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/features/address/cubit/address_cubit.dart';
import 'package:customer/features/address/models/address_model.dart';
import 'package:customer/features/address/widgets/address_actions.dart';
import 'package:customer/features/cart/cubit/cart_fetch_cubit.dart';
import 'package:customer/features/cart/cubit/cart_recommendations_cubit.dart';
import 'package:customer/features/cart/cubit/guest_cart_fetch_cubit.dart';
import 'package:customer/features/cart/models/cart_model.dart';
import 'package:customer/features/checkout/cubit/place_order_cubit.dart';
import 'package:customer/features/checkout/models/billing_address_model.dart';
import 'package:customer/features/checkout/widgets/billing_address_sheet.dart';
import 'package:customer/features/checkout/utils/checkout_totals.dart';
import 'package:customer/features/checkout/utils/checkout_variant_id.dart';
import 'package:customer/features/address/widgets/address_picker_sheet.dart';
import 'package:customer/features/checkout/widgets/checkout_bloc_listeners.dart';
import 'package:customer/features/checkout/widgets/checkout_guest_body.dart';
import 'package:customer/features/checkout/widgets/checkout_loaded_body.dart';
import 'package:customer/features/checkout/screens/checkout_payment_picker_screen.dart';
import 'package:customer/features/checkout/widgets/checkout_skeleton_loader.dart';
import 'package:customer/features/payment_method/cubit/payment_cubit.dart';
import 'package:customer/features/payment_method/cubit/payment_methods_cubit.dart';
import 'package:customer/features/payment_method/models/enums/order_payment_method.dart';
import 'package:customer/features/payment_method/models/payment_args.dart';
import 'package:customer/features/payment_method/models/payment_method_item.dart';
import 'package:customer/features/payment_method/screens/payment_methods_screen.dart';
import 'package:customer/features/payment_method/screens/webview_payment_screen.dart';
import 'package:customer/features/payment_method/widgets/paystack_launcher_mixin.dart';
import 'package:customer/features/payment_method/widgets/razorpay_launcher_mixin.dart';
import 'package:customer/features/payment_method/widgets/stripe_launcher_mixin.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/features/promo_code/cubit/promo_code_validate_cubit.dart';
import 'package:customer/features/promo_code/models/promo_code_model.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/utils/show_app_bottom_sheet.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with RazorpayLauncherMixin, StripeLauncherMixin, PaystackLauncherMixin {
  AddressData? _selectedAddress;
  PaymentMethodItem? _selectedPayment;
  PromoCodeData? _appliedPromo;
  String _orderNote = '';
  bool _useWallet = false;
  Timer? _guestSyncDebounce;

  bool _billingSameAsShipping = true;
  BillingAddressData? _billingAddress;

  // Gateway (stripe/razorpay/paystack/webview) is launched straight off
  // checkout once the order is created — no intermediate payment-methods
  // screen. PaymentCubit is provided at the route level (app_router.dart)
  // rather than here — a State's own `context` can't see a provider its
  // own build() introduces, and the launcher mixins read it via context.
  PaymentArgs? _currentPaymentArgs;

  @override
  PaymentArgs get launcherArgs => _currentPaymentArgs!;

  /// Prescription files the user attached, keyed by product variant id. Only
  /// medical products (product_type == 5) contribute entries here.
  final Map<String, File> _prescriptions = {};

  /// One scroll-target key per medical item's prescription tile, keyed by
  /// variant id — lets place-order jump to the first missing upload.
  final Map<String, GlobalKey> _prescriptionKeys = {};

  bool get _isLoggedIn => AuthHiveBox.instance.isLoggedIn;

  GlobalKey _prescriptionKeyFor(String variantId) =>
      _prescriptionKeys.putIfAbsent(variantId, () => GlobalKey());

  void _scrollToPrescription(String variantId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _prescriptionKeys[variantId]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    });
  }

  String _variantIdOf(ProductDataModel item) => resolveCheckoutVariantId(item);

  void _onPrescriptionPicked(String variantId, File file) {
    setState(() => _prescriptions[variantId] = file);
  }

  void _onPrescriptionRemoved(String variantId) {
    setState(() => _prescriptions.remove(variantId));
  }

  @override
  void dispose() {
    _guestSyncDebounce?.cancel();
    disposeRazorpay();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initRazorpay();
    if (_isLoggedIn) {
      // Don't fetch here without addressId — AddressCubit resolves the
      // default address asynchronously below, and _onAddressResolved fires
      // the real, address-scoped fetch once it lands. Firing an unscoped
      // fetch here races it and can leave the cart with no address_id.
      context.read<AddressCubit>().fetchInitial();
      context.read<PaymentMethodsCubit>().loadPaymentMethods();
    } else {
      final entries = context.read<CartCubit>().state.entries;
      context.read<GuestCartFetchCubit>().fetchGuestCart(
        variantIds: entries.keys.toList(),
        quantities: entries.values.map((e) => e.quantity.toString()).toList(),
      );
    }
    context.read<CartRecommendationsCubit>().fetchRecommendations(
      latitude: _addressLat,
      longitude: _addressLng,
    );
  }

  void _showAddressPicker() {
    showAppBottomSheet<void>(
      context,
      showDragHandle: false,
      padding: null,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AddressCubit>(),
        child: AddressPickerSheet(
          selectedId: _selectedAddress?.id,
          onSelect: (addr) {
            setState(() => _selectedAddress = addr);
            AppNavigator.pop(context);
            _refetchCartDistance();
            _revalidatePromoIfNeeded();
          },
          onAddNew: () {
            AppNavigator.pop(context);
            openAddressEditor(context);
          },
        ),
      ),
    );
  }

  Future<void> _showPaymentPicker({required bool codAllowed}) async {
    final result = await AppNavigator.push<PaymentMethodItem>(
      context,
      BlocProvider.value(
        value: context.read<PaymentMethodsCubit>(),
        child: CheckoutPaymentPickerScreen(
          selected: _selectedPayment,
          codAllowed: codAllowed,
        ),
      ),
    );
    if (result != null) {
      setState(() => _selectedPayment = result);
    }
  }

  String get _addressLat {
    final lat = _selectedAddress?.latitude;
    if (lat != null && lat.isNotEmpty && lat != 'null') return lat;
    return SettingsHiveBox.instance.userLatitude;
  }

  String get _addressLng {
    final lng = _selectedAddress?.longitude;
    if (lng != null && lng.isNotEmpty && lng != 'null') return lng;
    return SettingsHiveBox.instance.userLongitude;
  }

  void _refetchCartDistance() {
    if (!_isLoggedIn) return;
    context.read<CartFetchCubit>().fetchCart(
      latitude: _addressLat,
      longitude: _addressLng,
      addressId: _selectedAddress?.id,
    );
  }

  void _revalidatePromoIfNeeded() {
    final promo = _appliedPromo;
    if (promo == null || !mounted) return;
    final cartState = context.read<CartFetchCubit>().state;
    final subTotal = cartState is CartFetchLoaded
        ? (cartState.cart.data?.subTotal ?? 0).toString()
        : '0';
    context.read<PromoCodeValidateCubit>().validate(
      promoCode: promo.promoCode,
      total: subTotal,
      latitude: _addressLat,
      longitude: _addressLng,
    );
  }

  Future<void> _openBillingAddressSheet() async {
    final result = await showBillingAddressSheet(
      context,
      initial: _billingAddress,
    );
    if (result != null && mounted) {
      setState(() {
        _billingAddress = result;
        _billingSameAsShipping = false;
      });
    }
  }

  void _onBillingToggle(bool sameAsShipping) {
    if (!sameAsShipping) {
      // Unchecking requires a filled billing address — open the sheet
      // straight away instead of leaving the checkbox in a state with no
      // data behind it.
      _openBillingAddressSheet();
      return;
    }
    setState(() {
      _billingSameAsShipping = true;
      _billingAddress = null;
    });
  }

  void _removePromo() {
    setState(() => _appliedPromo = null);
    context.read<PromoCodeValidateCubit>().reset();
  }

  Future<void> _browseCodes(String subTotal) async {
    final result = await AppNavigator.pushNamed(
      context,
      RouteNames.promoCodes,
      arguments: <String, String?>{
        'amount': subTotal,
        'latitude': _addressLat,
        'longitude': _addressLng,
      },
    );
    if (result is PromoCodeData && mounted) {
      setState(() => _appliedPromo = result);
      final savedText = result.discount > 0
          ? context
                .translate(LanguageLabelKeys.youSavedAmount)
                .replaceAll(
                  '{amount}',
                  '${result.currency}${result.discount.formatPrice()}',
                )
          : '';
      showAppSuccessDialog(context, message: '${result.message}$savedText');
    }
  }

  void _onAddressResolved(AddressData address) {
    setState(() => _selectedAddress = address);
    _refetchCartDistance();
    _revalidatePromoIfNeeded();
  }

  /// The selected address was deleted and none remain — clear it so checkout
  /// no longer shows a stale address and re-prompts the user to pick one.
  void _onAddressCleared() {
    setState(() => _selectedAddress = null);
    _refetchCartDistance();
    _revalidatePromoIfNeeded();
  }

  void _onGuestCartChanged(CartState state) {
    final entries = state.entries;
    final guestCubit = context.read<GuestCartFetchCubit>();
    // Debounce: coalesce a burst of qty taps into one pricing fetch.
    _guestSyncDebounce?.cancel();
    _guestSyncDebounce = Timer(const Duration(milliseconds: 500), () {
      guestCubit.fetchGuestCart(
        variantIds: entries.keys.toList(),
        quantities: entries.values.map((e) => e.quantity.toString()).toList(),
        silent: true,
      );
    });
  }

  double _postPromoTotal(CartData cartData) => resolveCheckoutPostPromoTotal(
    cartData: cartData,
    appliedPromo: _appliedPromo,
  );

  void _placeOrder(CartData cartData) {
    if (_selectedAddress == null) {
      AppSnackBar.show(
        context: context,
        message: context.translate(
          LanguageLabelKeys.pleaseSelectDeliveryAddress,
        ),
        type: SnackBarType.error,
      );
      return;
    }

    final addressId = _selectedAddress!.id;
    if (addressId == null || addressId.isEmpty || addressId == 'null') {
      AppSnackBar.show(
        context: context,
        message: context.translate(LanguageLabelKeys.invalidAddress),
        type: SnackBarType.error,
      );
      return;
    }

    final hasSoldOutItem = (cartData.cart ?? []).any(
      (item) => item.isOutOfStock,
    );
    if (hasSoldOutItem) {
      AppSnackBar.show(
        context: context,
        message: context.translate(LanguageLabelKeys.removeOutOfStockItems),
        type: SnackBarType.error,
      );
      return;
    }

    if (cartData.isDeliverableAddress != 1) {
      AppSnackBar.show(
        context: context,
        message: context.translate(LanguageLabelKeys.zoneUnavailableSubtitle),
        type: SnackBarType.error,
      );
      return;
    }

    if (!_billingSameAsShipping && _billingAddress == null) {
      AppSnackBar.show(
        context: context,
        message: context.translate(LanguageLabelKeys.pleaseFillBillingAddress),
        type: SnackBarType.error,
      );
      _openBillingAddressSheet();
      return;
    }

    final walletBalance = cartData.userBalance ?? 0.0;
    final orderAmount = _postPromoTotal(cartData);
    final walletCoversFull = resolveCheckoutWalletCoversFull(
      cartData: cartData,
      useWallet: _useWallet,
      postPromoTotal: orderAmount,
    );

    if (!walletCoversFull && _selectedPayment == null) {
      AppSnackBar.show(
        context: context,
        message: context.translate(LanguageLabelKeys.pleaseSelectPaymentMethod),
        type: SnackBarType.error,
      );
      return;
    }

    // Prescription: mandatory for medical items flagged is_required_prescription;
    // optional ones are still forwarded when attached.
    final items = cartData.cart ?? [];
    final missingRequired = items.any(
      (item) =>
          item.requiresPrescription &&
          _prescriptions[_variantIdOf(item)] == null,
    );
    if (missingRequired) {
      AppSnackBar.show(
        context: context,
        message: context.translate(
          LanguageLabelKeys.pleaseUploadRequiredPrescription,
        ),
        type: SnackBarType.error,
      );
      final firstMissing = items.firstWhere(
        (item) =>
            item.requiresPrescription &&
            _prescriptions[_variantIdOf(item)] == null,
      );
      _scrollToPrescription(_variantIdOf(firstMissing));
      return;
    }

    final prescriptionPaths = <String, String>{};
    for (final item in items) {
      if (!item.isMedicalProduct) continue;
      final variantId = _variantIdOf(item);
      final file = _prescriptions[variantId];
      if (file != null && variantId.isNotEmpty) {
        prescriptionPaths[variantId] = file.path;
      }
    }

    final paymentMethod = walletCoversFull
        ? OrderPaymentMethod.wallet.apiValue
        : _selectedPayment!.apiValue;
    final walletUsed = _useWallet && walletBalance > 0 ? '1' : null;
    final walletAmountUsed = resolveCheckoutWalletAmountUsed(
      cartData: cartData,
      useWallet: _useWallet,
      postPromoTotal: orderAmount,
    );
    final walletBalanceStr = walletUsed != null
        ? walletAmountUsed.formatPrice(2)
        : null;

    context.read<PlaceOrderCubit>().placeOrder(
      addressId: addressId,
      paymentMethod: paymentMethod,
      promoCodeId: _appliedPromo?.promoCodeId.toString(),
      orderNote: _orderNote.isNotEmpty ? _orderNote : null,
      walletUsed: walletUsed,
      walletBalance: walletBalanceStr,
      prescriptions: prescriptionPaths.isNotEmpty ? prescriptionPaths : null,
      billingSameAsShipping: _billingSameAsShipping,
      billingName: _billingAddress?.name,
      billingMobile: _billingAddress?.fullMobile,
      billingAddress: _billingAddress?.address,
      billingCity: _billingAddress?.city,
      billingPincode: _billingAddress?.pincode,
      billingCountry: _billingAddress?.country,
      billingState: _billingAddress?.state,
      billingRegionId: _billingAddress?.regionId,
    );
  }

  Future<void> _onPlaceOrderSuccess(
    PlaceOrderSuccess state,
    CartData cartData,
  ) async {
    final orderAmount = _postPromoTotal(cartData);
    final walletCoversFull = resolveCheckoutWalletCoversFull(
      cartData: cartData,
      useWallet: _useWallet,
      postPromoTotal: orderAmount,
    );
    if (state.isCod || walletCoversFull) {
      _goToOrderSuccess(orderId: state.orderId, orderItemId: state.orderItemId);
      return;
    }

    final walletAmountUsed = resolveCheckoutWalletAmountUsed(
      cartData: cartData,
      useWallet: _useWallet,
      postPromoTotal: orderAmount,
    );
    final remainingAmount = orderAmount - walletAmountUsed;

    // Method already picked on checkout's own payment picker — fire the
    // gateway straight off this screen instead of routing through a
    // separate payment-methods screen just to auto-fire it there. The
    // gateway needs methodsData (stripe/razorpay/paystack keys) though —
    // wait for it if the settings/payment_methods call kicked off in
    // initState hasn't resolved yet, otherwise the gateway launches with a
    // null key and immediately fails as "not configured".
    final methodsCubit = context.read<PaymentMethodsCubit>();
    if (methodsCubit.state is! PaymentMethodsLoaded) {
      await methodsCubit.stream.firstWhere(
        (s) => s is PaymentMethodsLoaded || s is PaymentMethodsError,
      );
      if (!mounted) return;
    }

    _currentPaymentArgs = PaymentArgs(
      orderId: state.orderId,
      orderItemId: state.orderItemId,
      amount: remainingAmount,
      currency: cartData.currency ?? '',
      userEmail: AuthHiveBox.instance.userEmail,
    );
    context.read<PaymentCubit>().initiatePayment(
      orderId: state.orderId,
      orderItemId: state.orderItemId,
      method: _selectedPayment!,
    );
  }

  void _goToOrderSuccess({required String orderId, String orderItemId = ''}) {
    AppNavigator.pushReplacementNamed(
      context,
      RouteNames.orderSuccess,
      arguments: OrderSuccessArgs(orderId: orderId, orderItemId: orderItemId),
    );
  }

  Future<void> _onPaymentStateChanged(
    BuildContext context,
    PaymentState state,
  ) async {
    final methodsState = context.read<PaymentMethodsCubit>().state;
    final methodsData = methodsState is PaymentMethodsLoaded
        ? methodsState.data
        : null;

    if (state is PaymentWebViewReady) {
      await AppNavigator.push(
        context,
        BlocProvider.value(
          value: context.read<PaymentCubit>(),
          child: WebViewPaymentScreen(
            args: WebViewPaymentArgs(
              url: state.url,
              orderId: state.orderId,
              orderItemId: state.orderItemId,
              paymentType: state.paymentType,
              gateway: state.gateway,
              extra: state.extra,
              merchantOrderId: state.merchantOrderId,
              phonePeToken: state.phonePeToken,
            ),
          ),
        ),
      );
      // WebViewPaymentScreen already navigates to order success itself
      // (popUntil(main) + pushNamed) on success — nothing left to do here.
    } else if (state is PaymentSdkReady) {
      switch (state.gateway) {
        case PaymentGatewayType.razorpay:
          launchRazorpay(state, methodsData);
        case PaymentGatewayType.stripe:
          launchStripe(state, methodsData);
        case PaymentGatewayType.paystack:
          launchPaystack(state, methodsData);
        default:
          break;
      }
    } else if (state is PaymentSuccess) {
      _goToOrderSuccess(orderId: state.orderId, orderItemId: state.orderItemId);
    } else if (state is PaymentError) {
      AppSnackBar.show(
        context: context,
        message: state.message,
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentCubit, PaymentState>(
      listener: _onPaymentStateChanged,
      child: AppScaffold(
        applyBottomInset: false,
        appBar: CustomAppBar(
          title: context.translate(LanguageLabelKeys.checkout),
          showBackButton: true,
        ),
        body: CheckoutBlocListeners(
          isLoggedIn: _isLoggedIn,
          selectedAddress: _selectedAddress,
          onAddressResolved: _onAddressResolved,
          onAddressCleared: _onAddressCleared,
          onPromoValidated: (promo) => setState(() => _appliedPromo = promo),
          onPlaceOrderSuccess: _onPlaceOrderSuccess,
          onGuestCartChanged: _onGuestCartChanged,
          child: _isLoggedIn
              ? BlocBuilder<CartFetchCubit, CartFetchState>(
                  builder: (context, cartState) =>
                      _buildBody(context, cartState),
                )
              : BlocBuilder<GuestCartFetchCubit, GuestCartState>(
                  builder: (context, guestState) =>
                      _buildGuestBody(context, guestState),
                ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CartFetchState cartState) {
    if (cartState is CartFetchLoading || cartState is CartFetchInitial) {
      return const CheckoutSkeletonLoader();
    }
    if (cartState is CartFetchError) {
      return EmptyStateWidget(
        imagePath: AssetsConstants.noCartFound,
        title: cartState.message,
        subtitle: context.translate(LanguageLabelKeys.pullToRefresh),
        onRetry: _refetchCartDistance,
      );
    }
    if (cartState is CartFetchLoaded) {
      final cartData = cartState.cart.data;
      if (cartData == null || (cartData.cart?.isEmpty ?? true)) {
        return EmptyStateWidget(
          imagePath: AssetsConstants.noCartFound,
          title: context.translate(LanguageLabelKeys.cartEmpty),
          subtitle: context.translate(LanguageLabelKeys.cartEmptySubtitle),
        );
      }

      return CheckoutLoadedBody(
        cartData: cartData,
        currency: cartData.currency ?? '',
        addressLat: _addressLat,
        addressLng: _addressLng,
        appliedPromo: _appliedPromo,
        useWallet: _useWallet,
        selectedAddress: _selectedAddress,
        selectedPayment: _selectedPayment,
        onRemovePromo: _removePromo,
        onBrowseCodes: _browseCodes,
        onWalletToggle: (val) => setState(() => _useWallet = val),
        onNoteChanged: (note) => setState(() => _orderNote = note),
        onPlaceOrder: () => _placeOrder(cartData),
        onChooseAddress: _showAddressPicker,
        onChoosePayment: (codAllowed) =>
            _showPaymentPicker(codAllowed: codAllowed),
        billingSameAsShipping: _billingSameAsShipping,
        billingAddress: _billingAddress,
        onBillingToggle: _onBillingToggle,
        onEditBillingAddress: _openBillingAddressSheet,
        prescriptions: _prescriptions,
        onPrescriptionPicked: _onPrescriptionPicked,
        onPrescriptionRemoved: _onPrescriptionRemoved,
        prescriptionKeyOf: _prescriptionKeyFor,
        onUploadPrescriptionRequested: _scrollToPrescription,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildGuestBody(BuildContext context, GuestCartState guestState) {
    if (guestState is GuestCartInitial) {
      return EmptyStateWidget(
        imagePath: AssetsConstants.noCartFound,
        title: context.translate(LanguageLabelKeys.cartEmpty),
        subtitle: context.translate(LanguageLabelKeys.cartEmptySubtitle),
      );
    }
    if (guestState is GuestCartLoading) {
      return const CheckoutSkeletonLoader();
    }
    if (guestState is GuestCartError) {
      return EmptyStateWidget(
        imagePath: AssetsConstants.noCartFound,
        title: guestState.message,
        subtitle: context.translate(LanguageLabelKeys.pullToRefresh),
      );
    }
    if (guestState is GuestCartLoaded) {
      final cartData = guestState.cart.data;
      if (cartData == null || (cartData.cart?.isEmpty ?? true)) {
        return EmptyStateWidget(
          imagePath: AssetsConstants.noCartFound,
          title: context.translate(LanguageLabelKeys.cartEmpty),
          subtitle: context.translate(LanguageLabelKeys.cartEmptySubtitle),
        );
      }
      return CheckoutGuestBody(
        cartData: cartData,
        currency: cartData.currency ?? '',
        onLoginAndCheckout: () =>
            AppNavigator.pushNamed(context, RouteNames.login),
      );
    }
    return const SizedBox.shrink();
  }
}
