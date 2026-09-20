import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/features/cart/cubit/cart_cubit.dart';
import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/core/constants/theme_constants.dart';

class FloatingCartBar extends StatefulWidget {
  final VoidCallback? onViewCart;

  const FloatingCartBar({super.key, this.onViewCart});

  /// Bar height incl. its own bottom padding — screens whose scrollable
  /// content sits under this bar reserve this much extra bottom space so
  /// the last row isn't hidden behind it.
  static const double barHeight = 62;

  @override
  State<FloatingCartBar> createState() => _FloatingCartBarState();
}

class _FloatingCartBarState extends State<FloatingCartBar>
    with TickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  // Morph: collapsed = just the image circle (just-added bubble), expanded = full
  // pill with "View cart" + arrow. Plays forward on 0→n and reverse on n→0,
  // and the bar only slides down after the reverse morph finishes collapsing.
  late final AnimationController _morphCtrl;
  late final Animation<double> _morphAnim;

  int _lastTotalItems = 0;
  bool _barVisible = false;

  static const double _collapsedSize = 52;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _morphCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _morphAnim = CurvedAnimation(
      parent: _morphCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // BlocConsumer's listener only fires on subsequent emissions, not the state
    // already in the cubit when this widget mounts — sync initial visuals here
    // so a pre-existing cart shows the bar fully expanded, not hidden/collapsed.
    final initialTotal = context.read<CartCubit>().state.totalItems;
    _lastTotalItems = initialTotal;
    _barVisible = initialTotal > 0;
    _morphCtrl.value = initialTotal > 0 ? 1 : 0;
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _morphCtrl.dispose();
    super.dispose();
  }

  static const _slideDuration = Duration(milliseconds: 380);

  void _handleCartChange(int total) {
    if (_lastTotalItems == 0 && total > 0) {
      // First item just added — mirrors the remove path: slide the bar up
      // collapsed first, then once it has settled into position, morph open.
      _morphCtrl.value = 0;
      setState(() => _barVisible = true);
      Future.delayed(_slideDuration, () {
        if (mounted && _lastTotalItems > 0) _morphCtrl.forward();
      });
    } else if (_lastTotalItems > 0 && total == 0) {
      // Last item removed — morph back to a circle, then slide the bar down.
      _morphCtrl.reverse().whenComplete(() {
        if (mounted) setState(() => _barVisible = false);
      });
    } else if (total > 0) {
      _shakeCtrl.forward(from: 0.0);
    }
    _lastTotalItems = total;
  }

  double _expandedWidth(int previewCount) {
    if (previewCount <= 1) return 180;
    if (previewCount == 2) return 200;
    return 220;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartCubit, CartState>(
      listener: (context, state) => _handleCartChange(state.totalItems),
      builder: (context, state) {
        return AnimatedSlide(
          offset: _barVisible ? Offset.zero : const Offset(0, 1.5),
          duration: const Duration(milliseconds: 380),
          curve: _barVisible ? Curves.easeOutBack : Curves.easeInCubic,
          child: AnimatedOpacity(
            opacity: _barVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingM, 0, ThemeConstants.paddingM, ThemeConstants.paddingS),
              child: Center(
                child: GestureDetector(
                  onTap: widget.onViewCart,
                  child: AnimatedBuilder(
                    animation: _morphAnim,
                    builder: (context, child) {
                      final t = _morphAnim.value;
                      final expandedWidth = _expandedWidth(
                        state.previewImages.length,
                      );
                      final width =
                          _collapsedSize + (expandedWidth - _collapsedSize) * t;
                      return Container(
                        width: width,
                        height: _collapsedSize,
                        clipBehavior: Clip.hardEdge,
                        padding: const EdgeInsetsDirectional.only(
                          start: ThemeConstants.paddingS,
                          end: ThemeConstants.paddingS,
                        ),
                        decoration: AppDecorations.box(
                          color: context.cs.primary,
                          borderRadius: AppRadius.pill,
                          boxShadow: [
                            BoxShadow(
                              color: context.cs.primary.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: OverflowBox(
                            minWidth: 0,
                            maxWidth: expandedWidth - 16,
                            alignment: AlignmentDirectional.centerStart,
                            child: SizedBox(
                              width: expandedWidth - 16,
                              height: 36,
                              child: Row(
                                children: [
                                  // ── Overlapping product images ──────────
                                  AnimatedBuilder(
                                    animation: _shakeAnim,
                                    builder: (context, child) =>
                                        Transform.rotate(
                                          angle: _shakeAnim.value,
                                          child: child,
                                        ),
                                    child: _OverlappingImages(
                                      images: state.previewImages,
                                    ),
                                  ),

                                  AppSpacing.w10,

                                  // ── View cart + item count ──────────────
                                  Expanded(
                                    child: Opacity(
                                      opacity: t,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: AlignmentDirectional.centerStart,
                                        child: Column(
                                        mainAxisAlignment: .center,
                                        crossAxisAlignment: .start,
                                        spacing: ThemeConstants.spaceXS,
                                        children: [
                                          AppText(
                                            context.translate(
                                              LanguageLabelKeys.viewCart,
                                            ),
                                            style: context.tt.titleSmall
                                                ?.copyWith(
                                                  color: context.cs.onPrimary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1,
                                                ),
                                          ),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            transitionBuilder: (child, anim) =>
                                                FadeTransition(
                                                  opacity: anim,
                                                  child: child,
                                                ),
                                            child: AppText(
                                              '${state.totalItems} ${context.translate(state.totalItems == 1 ? LanguageLabelKeys.item : LanguageLabelKeys.items)}',
                                              key: ValueKey(state.totalItems),
                                              style: context.tt.bodySmall
                                                  ?.copyWith(
                                                    color: context.cs.onPrimary
                                                        .withValues(
                                                          alpha: 0.75,
                                                        ),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ── Right arrow circle ───────────────────
                                  Opacity(
                                    opacity: t,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: AppDecorations.box(
                                        color: context.cs.scrim.withValues(
                                          alpha: 0.20,
                                        ),
                                        shape: .circle,
                                      ),
                                      child: Transform.flip(
                                        flipX:
                                            Directionality.of(context) ==
                                            TextDirection.rtl,
                                        child: AppSvgIcon(
                                          AssetsConstants.arrowRightIcon,
                                          color: context.cs.onPrimary,
                                          size: ThemeConstants.iconS,
                                          fit: BoxFit.scaleDown,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverlappingImages extends StatelessWidget {
  final List<String> images;
  const _OverlappingImages({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return AppSpacing.w4;

    const double size = 36;
    const double overlap = 20;
    final count = images.length.clamp(1, 3);
    final totalWidth = size + (count - 1) * (size - overlap);

    // No reversal: oldest at left (back), latest at right (top/frontmost)
    final displayImages = images.take(count).toList();

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          // i=0 → start (back), i=count-1 → end (top z-order)
          return PositionedDirectional(
            start: i * (size - overlap),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: child,
              ),
              child: Container(
                key: ValueKey(displayImages[i]),
                width: size,
                height: size,
                decoration: AppDecorations.box(
                  shape: .circle,
                  color: context.cs.onPrimary,
                  border: Border.all(color: context.cs.onPrimary, width: 2.5),
                ),
                child: ClipOval(child: AppNetworkImage(url: displayImages[i])),
              ),
            ),
          );
        }),
      ),
    );
  }
}
