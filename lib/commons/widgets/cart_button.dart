import 'dart:async';
import 'package:customer/commons/utils/app_log.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';

import '../../commons/widgets/app_text.dart';

import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:customer/core/local_storage/auth_hive_box.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/features/cart/cubit/cart_action_cubit.dart';
import 'package:customer/core/localization/language_label_key.dart';

class CartButton extends StatefulWidget {
  final double width;
  final double height;
  final double fontSize;
  final double optionsFontSize;
  final int optionCount;
  final int initialCount;
  final String productId;
  final String variantId;
  final double price;
  final String imageUrl;
  final int totalAllowedQuantity;
  final VoidCallback onFirstAdd;
  final VoidCallback onLastRemove;
  final VoidCallback? onLimitReached;
  final BuildContext? snackBarContext;

  const CartButton({
    super.key,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.optionsFontSize,
    required this.optionCount,
    required this.initialCount,
    required this.productId,
    required this.variantId,
    required this.price,
    required this.onFirstAdd,
    required this.onLastRemove,
    this.totalAllowedQuantity = 0,
    this.imageUrl = '',
    this.onLimitReached,
    this.snackBarContext,
  });

  @override
  State<CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<CartButton>
    with SingleTickerProviderStateMixin {
  late int _count;
  bool _increasing = true;

  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  // Debounced server sync (logged-in only): coalesce a tap burst into one call.
  Timer? _syncDebounce;
  int? _baseQty; // server-confirmed qty captured at the start of a burst
  CartActionCubit? _actionCubit;
  // True while this button's own sync request is in flight — gates the
  // BlocListener below so only the button that actually fired the request
  // reacts to its result (the cubit is a single shared instance).
  bool _awaitingAction = false;
  // Base qty captured for the in-flight request, kept so a failed sync can
  // roll the optimistic local qty back to what the server still holds.
  int? _pendingRevertBase;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(_scaleCtrl);
  }

  @override
  void didUpdateWidget(CartButton old) {
    super.didUpdateWidget(old);
    if (old.initialCount != widget.initialCount) {
      setState(() => _count = widget.initialCount);
    }
  }

  @override
  void dispose() {
    // Persist any pending change before the widget goes away.
    if (_syncDebounce?.isActive ?? false) {
      _syncDebounce!.cancel();
      _actionCubit?.unregisterPendingFlush(_flushSync);
      _flushSync();
    }
    _scaleCtrl.dispose();
    super.dispose();
  }

  /// [baseQty] = the qty before this tap; captured once per burst.
  void _scheduleSync(int baseQty) {
    if (!AuthHiveBox.instance.isLoggedIn) return;
    _actionCubit = context.read<CartActionCubit>();
    _baseQty ??= baseQty;
    if (_syncDebounce == null) {
      // First tap of this burst — register so a channel switch can force
      // this request out under the current channel before its timer fires.
      _actionCubit!.registerPendingFlush(_flushSync);
    }
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 500), () {
      _actionCubit?.unregisterPendingFlush(_flushSync);
      _flushSync();
    });
  }

  /// Sends the net change accumulated during the burst as one request.
  Future<void> _flushSync() async {
    _syncDebounce?.cancel();
    _syncDebounce = null;
    final base = _baseQty;
    final action = _actionCubit;
    _baseQty = null;
    if (base == null || action == null) return;
    final delta = _count - base;
    if (delta == 0) return;
    _awaitingAction = true;
    _pendingRevertBase = base;
    if (delta > 0) {
      await action.addToCart(
        productId: widget.productId,
        productVariantId: widget.variantId,
        qty: _count,
      );
    } else {
      await action.removeFromCart(
        productId: widget.productId,
        productVariantId: widget.variantId,
        qty: -delta,
      );
    }
  }

  void _increment() {
    final limit = widget.totalAllowedQuantity;
    if (limit > 0 && _count >= limit) {
      widget.onLimitReached?.call();
      final snackContext = widget.snackBarContext ?? context;
      AppSnackBar.show(
        context: snackContext,
        message: context.translate(LanguageLabelKeys.maxAllowedQuantityReached),
        type: SnackBarType.warning,
      );
      return;
    }

    final maxCartItems = SettingsHiveBox.instance.maxCartItemsCount;
    final totalItems = context.read<CartCubit>().state.totalItems;
    if (maxCartItems > 0 && totalItems >= maxCartItems) {
      widget.onLimitReached?.call();
      final snackContext = widget.snackBarContext ?? context;
      AppSnackBar.show(
        context: snackContext,
        message: context.translate(LanguageLabelKeys.maxCartItemsReached),
        type: SnackBarType.warning,
      );
      return;
    }

    final wasZero = _count == 0;
    final baseQty = _count;
    HapticFeedback.lightImpact();
    setState(() {
      _increasing = true;
      _count++;
    });
    _scaleCtrl.forward(from: 0.0);
    if (wasZero) widget.onFirstAdd();
    try {
      context.read<CartCubit>().add(
        widget.variantId,
        widget.price,
        imageUrl: widget.imageUrl,
      );
    } catch (e, s) {
      logDebug('CartButton add (local): $e\n$s');
    }
    _scheduleSync(baseQty);
  }

  void _decrement() {
    if (_count <= 0) return;
    final willBeZero = _count == 1;
    final baseQty = _count;
    HapticFeedback.lightImpact();
    setState(() {
      _increasing = false;
      _count--;
    });
    _scaleCtrl.forward(from: 0.0);
    if (willBeZero) widget.onLastRemove();
    try {
      context.read<CartCubit>().remove(widget.variantId, widget.price);
    } catch (e, s) {
      logDebug('CartButton remove (local): $e\n$s');
    }
    _scheduleSync(baseQty);
  }

  @override
  Widget build(BuildContext context) {
    final isStepper = _count > 0;

    return BlocListener<CartActionCubit, CartActionState>(
      listenWhen: (_, curr) =>
          _awaitingAction &&
          (curr is CartActionSuccess || curr is CartActionError),
      listener: (ctx, state) {
        _awaitingAction = false;
        final revertBase = _pendingRevertBase;
        _pendingRevertBase = null;
        if (state is CartActionError) {
          // Only roll back if no newer tap burst has started since this
          // request was fired — otherwise we'd stomp on a fresher change.
          // Skip entirely for fromRemove: some backends respond with a
          // non-1 status when a remove call empties the cart, which isn't
          // a real failure — rolling back would re-add the item we just
          // correctly removed.
          if (!state.fromRemove &&
              revertBase != null &&
              _syncDebounce == null &&
              _baseQty == null &&
              _count != revertBase) {
            setState(() => _count = revertBase);
            try {
              ctx.read<CartCubit>().setQuantity(
                widget.variantId,
                widget.price,
                revertBase,
                imageUrl: widget.imageUrl,
              );
            } catch (e, s) {
              logDebug('CartButton revert (local): $e\n$s');
            }
          }
          if (!state.fromRemove) {
            final snackContext = widget.snackBarContext ?? ctx;
            AppSnackBar.show(
              context: snackContext,
              message: state.message,
              type: SnackBarType.error,
            );
          }
        }
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          width: widget.width,
          height: widget.height,
          decoration: AppDecorations.cartControl(
            cs: context.cs,
            filled: isStepper,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.r10,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, anim) {
                final isCounterChild = child.key == const ValueKey('counter');
                final slideBegin = Offset(0, isCounterChild ? 1.0 : -1.0);
                return SlideTransition(
                  position: Tween<Offset>(begin: slideBegin, end: Offset.zero)
                      .animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
              child: isStepper ? _stepperView() : _addView(),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle? get _addLabelStyle => context.tt.headlineMedium?.copyWith(
    color: context.cs.primary,
    fontSize: widget.fontSize,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );

  Widget _addLabelText() => AppText(
    context.translate(LanguageLabelKeys.add).toUpperCase(),
    style: _addLabelStyle,
  );

  Widget _addView() {
    final fg = context.cs.onPrimary;
    final opts = widget.optionCount;

    if (opts > 1) {
      return GestureDetector(
        key: const ValueKey('add'),
        onTap: widget.onFirstAdd,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            Expanded(child: Center(child: _addLabelText())),
            Container(
              color: context.cs.primary,
              padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
              child: Center(
                child: AppText(
                  '$opts ${context.translate(LanguageLabelKeys.options)}',
                  style: context.tt.labelLarge?.copyWith(
                    fontSize: widget.optionsFontSize,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      key: const ValueKey('add'),
      onTap: _increment,
      behavior: HitTestBehavior.opaque,
      child: Center(child: _addLabelText()),
    );
  }

  Widget _stepperTapArea({
    required double tapW,
    required VoidCallback onTap,
    required String icon,
    required Color fg,
    required double iconSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: tapW,
        height: widget.height,
        child: Center(
          child: AppSvgIcon(icon, color: fg, size: iconSize),
        ),
      ),
    );
  }

  Widget _stepperView() {
    final fg = context.cs.onPrimary;
    final fs = widget.fontSize;
    final tapW = (widget.width * 0.33).clamp(22.0, 42.0);
    final isMulti = widget.optionCount > 1;

    return Row(
      key: const ValueKey('counter'),
      mainAxisAlignment: .spaceBetween,
      children: [
        _stepperTapArea(
          tapW: tapW,
          onTap: isMulti ? widget.onFirstAdd : _decrement,
          icon: AssetsConstants.removeIcon,
          fg: fg,
          iconSize: fs + 3,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) {
            final slideBegin = Offset(0, _increasing ? 0.8 : -0.8);
            return SlideTransition(
              position: Tween<Offset>(begin: slideBegin, end: Offset.zero)
                  .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          child: AppText(
            '$_count',
            key: ValueKey(_count),
            style: context.tt.headlineMedium?.copyWith(
              color: fg,
              fontSize: fs + 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _stepperTapArea(
          tapW: tapW,
          onTap: isMulti ? widget.onFirstAdd : _increment,
          icon: AssetsConstants.addIcon,
          fg: fg,
          iconSize: fs + 3,
        ),
      ],
    );
  }
}
