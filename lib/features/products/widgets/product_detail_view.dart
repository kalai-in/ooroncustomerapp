import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/commons/widgets/product_type_icon.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/features/products/cubit/product_detail_cubit.dart';
import 'package:customer/features/products/cubit/ratings_list_cubit.dart';
import 'package:customer/features/products/models/product_rating_model.dart';
import 'package:customer/features/products/models/product_detail_model.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/features/products/widgets/product_detail_app_bar_widgets.dart';
import 'package:customer/features/products/widgets/product_detail_info_section.dart';
import 'package:customer/features/products/widgets/product_detail_rating_section.dart';
import 'package:customer/features/products/widgets/product_detail_upsell_section.dart';
import 'package:customer/features/products/widgets/recently_visited_section.dart';
import 'package:customer/features/products/widgets/similar_products_section.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/constants/theme_constants.dart';

class ProductDetailView extends StatefulWidget {
  final ProductDetailDataModel product;
  final int productId;
  final String heroSuffix;

  /// Suffix used only for this page's own Similar/Recently-Visited section
  /// cards — kept separate from [heroSuffix] so scoping it per-page (to
  /// dodge duplicate-tag crashes across concurrently-mounted pager pages)
  /// never breaks the main image hero's match against the tapped card.
  final String subSectionHeroSuffix;
  final int selectedVariantIndex;
  final Map<int, int> selectedAxisValues;
  final PageController imageController;
  final ScrollController scrollController;
  final int imagePage;
  final bool isCollapsed;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<int> onImagePageChanged;

  /// Attached to the Upsell section so the bottom bar's "first add to
  /// cart" handler can scroll straight to it via [Scrollable.ensureVisible].
  final GlobalKey? upsellSectionKey;

  const ProductDetailView({
    super.key,
    required this.product,
    required this.productId,
    this.heroSuffix = '',
    this.subSectionHeroSuffix = '',
    required this.selectedVariantIndex,
    required this.selectedAxisValues,
    required this.imageController,
    required this.scrollController,
    required this.imagePage,
    required this.isCollapsed,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onImagePageChanged,
    this.upsellSectionKey,
  });

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  bool _showKeyFeatures = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _toggleKeyFeatures() {
    setState(() => _showKeyFeatures = !_showKeyFeatures);
    if (_showKeyFeatures) {
      _slideCtrl.forward();
    } else {
      _slideCtrl.reverse();
    }
  }

  bool _isVariantCombinationAvailable(
    int attributeId,
    int attributeValueId,
    Map<int, int> currentSelection,
  ) {
    final variants = widget.product.variants ?? [];
    if (variants.isEmpty) return true;

    final testSelection = Map<int, int>.from(currentSelection);
    testSelection[attributeId] = attributeValueId;

    for (final variant in variants) {
      bool matches = true;
      for (final entry in testSelection.entries) {
        final hasAttribute = (variant.attributes ?? []).any(
          (attr) =>
              attr.attributeId == entry.key &&
              attr.attributeValueId == entry.value,
        );
        if (!hasAttribute) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.screenHeight;
    final variants = widget.product.variants ?? [];
    final safeIndex = widget.selectedVariantIndex.clamp(
      0,
      variants.isEmpty ? 0 : variants.length - 1,
    );

    final displayShortDesc = widget.product.shortDescription ?? '';
    final displayDesc = widget.product.description ?? '';

    final activeVariant = variants.isNotEmpty ? variants[safeIndex] : null;
    final displayName =
        (activeVariant?.name?.isNotEmpty == true
            ? activeVariant!.name
            : widget.product.name) ??
        '';
    final variantImages =
        activeVariant?.images
            ?.map((i) => i.imageUrl ?? '')
            .where((u) => u.isNotEmpty)
            .toList() ??
        [];
    final allImages = variantImages.isNotEmpty
        ? variantImages
        : (widget.product.imageUrl?.isNotEmpty == true
              ? [widget.product.imageUrl!]
              : <String>[]);

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        // ── App bar + image ────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          expandedHeight: sh * 0.38,
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 0,
          backgroundColor: widget.isCollapsed
              ? context.cs.surface
              : Colors.transparent,
          foregroundColor: context.cs.onSurface,
          elevation: widget.isCollapsed ? 0.5 : 0,
          shadowColor: context.theme.shadowColor.withValues(alpha: 0.12),
          surfaceTintColor: Colors.transparent,
          title: AnimatedOpacity(
            opacity: widget.isCollapsed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AppText(
              displayName,
              maxLines: 1,
              overflow: .ellipsis,
              style: context.tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.cs.onSurface,
              ),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingS),
            child: ProductDetailCircleBtn(
              icon: widget.isExpanded
                  ? AssetsConstants.arrowDownIcon
                  : AssetsConstants.arrowUpIcon,
              onTap: widget.onToggleExpand,
              isActive: widget.isCollapsed,
            ),
          ),
          actions: [
            ProductDetailShareBtn(
              product: widget.product,
              isActive: widget.isCollapsed,
            ),
            AppSpacing.w4,
            ProductDetailFavBtn(
              product: widget.product,
              isActive: widget.isCollapsed,
            ),
            AppSpacing.w8,
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Hero(
              tag: 'product_hero_${widget.productId}${widget.heroSuffix}',
              child: Container(
                color: context.cs.surfaceContainerHigh,
                child: Stack(
                  children: [
                    allImages.isNotEmpty
                        ? GestureDetector(
                            onTap: () => AppNavigator.pushNamed(
                              context,
                              RouteNames.fullScreenImageViewer,
                              arguments: (allImages, widget.imagePage),
                            ),
                            child: PageView.builder(
                              controller: widget.imageController,
                              itemCount: allImages.length,
                              onPageChanged: widget.onImagePageChanged,
                              itemBuilder: (_, i) => AppNetworkImage(
                                url: allImages[i],
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : const AppNetworkImage(url: ''),
                    PositionedDirectional(
                      bottom: 0,
                      start: 0,
                      top: 0,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          width: 160,
                          decoration: AppDecorations.box(
                            color: context.cs.scrim.withValues(alpha: 0.75),
                          ),
                          padding: const EdgeInsetsDirectional.all(14),
                          child: Column(
                            crossAxisAlignment: .start,
                            mainAxisAlignment: .end,
                            children: [
                              AppText(
                                context.translate(
                                  LanguageLabelKeys.keyFeatures,
                                ),
                                style: context.tt.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              AppSpacing.h10,
                              if (widget.product.categoryName?.isNotEmpty ==
                                  true) ...[
                                AppText(
                                  context.translate(LanguageLabelKeys.category),
                                  style: context.tt.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                AppText(
                                  widget.product.categoryName!,
                                  style: context.tt.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                                AppSpacing.h8,
                              ],
                              if (widget.product.brandName?.isNotEmpty ==
                                  true) ...[
                                AppText(
                                  context.translate(LanguageLabelKeys.brand),
                                  style: context.tt.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                AppText(
                                  widget.product.brandName!,
                                  style: context.tt.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                                AppSpacing.h8,
                              ],
                              if (widget.product.madeIn?.isNotEmpty ==
                                  true) ...[
                                AppText(
                                  context.translate(LanguageLabelKeys.madeIn),
                                  style: context.tt.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                AppText(
                                  widget.product.madeIn!,
                                  style: context.tt.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                                AppSpacing.h8,
                              ],
                              if (widget.product.storeName?.isNotEmpty ==
                                  true) ...[
                                AppText(
                                  context.translate(LanguageLabelKeys.soldBy),
                                  style: context.tt.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                AppText(
                                  widget.product.storeName!,
                                  style: context.tt.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _slideAnim,
                      builder: (context, child) {
                        final arrowInset = 160 + (_slideAnim.value.dx * 160);
                        return PositionedDirectional(
                          start: arrowInset,
                          bottom: 50,
                          height: 40,
                          width: 24,
                          child: child!,
                        );
                      },
                      child: GestureDetector(
                        onTap: _toggleKeyFeatures,
                        child: Container(
                          decoration: AppDecorations.box(
                            color: context.cs.scrim.withValues(alpha: 0.8),
                            borderRadius: const BorderRadiusDirectional.only(
                              topEnd: Radius.circular(4),
                              bottomEnd: Radius.circular(4),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Transform.flip(
                            flipX:
                                Directionality.of(context) ==
                                TextDirection.rtl,
                            child: AppSvgIcon(
                              _showKeyFeatures
                                  ? AssetsConstants.arrowLeftIcon
                                  : AssetsConstants.arrowRightIcon,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (allImages.length > 1)
                      Positioned(
                        bottom: 14,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: .center,
                          children: List.generate(allImages.length, (i) {
                            final active = i == widget.imagePage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: active ? 16 : 6,
                              height: 6,
                              margin: const EdgeInsetsDirectional.symmetric(
                                horizontal: 2,
                              ),
                              decoration: AppDecorations.box(
                                color: active
                                    ? context.cs.primary
                                    : context.cs.outlineVariant,
                                borderRadius: AppRadius.r4,
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: ColoredBox(
            color: context.cs.surface,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                // ── Name + meta ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingM),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        crossAxisAlignment: .start,
                        spacing: widget.product.productType != 0 ? 6 : 0,
                        children: [
                          widget.product.productType != 0
                              ? ProductTypeIcon(
                                  productType: widget.product.productType,
                                  size: 18,
                                )
                              : const SizedBox.shrink(),
                          Expanded(
                            child: AppText(
                              displayName,
                              style: context.tt.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.cs.onSurface,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (displayShortDesc.isNotEmpty) ...[
                        AppSpacing.h6,
                        AppText(
                          displayShortDesc,
                          style: context.tt.bodySmall?.copyWith(
                            color: context.cs.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: .ellipsis,
                        ),
                      ],
                      AppSpacing.h8,
                      BlocBuilder<
                        RatingsListCubit,
                        PaginationState<ProductRatingList>
                      >(
                        builder: (context, rState) {
                          final loaded =
                              rState is PaginationLoaded<ProductRatingList>;
                          final summary = context
                              .read<RatingsListCubit>()
                              .summary;
                          final avg = loaded
                              ? double.tryParse(summary.averageRating ?? '0') ??
                                    0.0
                              : 0.0;
                          final total = loaded
                              ? (int.tryParse(summary.oneStarRating ?? '0') ??
                                        0) +
                                    (int.tryParse(
                                          summary.twoStarRating ?? '0',
                                        ) ??
                                        0) +
                                    (int.tryParse(
                                          summary.threeStarRating ?? '0',
                                        ) ??
                                        0) +
                                    (int.tryParse(
                                          summary.fourStarRating ?? '0',
                                        ) ??
                                        0) +
                                    (int.tryParse(
                                          summary.fiveStarRating ?? '0',
                                        ) ??
                                        0)
                              : 0;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (total > 0) ...[
                                Container(
                                  padding:
                                      const EdgeInsetsDirectional.symmetric(
                                        horizontal: ThemeConstants.paddingS,
                                        vertical: ThemeConstants.paddingXS,
                                      ),
                                  decoration: AppDecorations.box(
                                    color: context.cs.onSecondaryContainer,
                                    borderRadius: AppRadius.r4,
                                  ),
                                  child: Row(
                                    mainAxisSize: .min,
                                    spacing: 3,
                                    children: [
                                      AppText(
                                        avg.toStringAsFixed(1),
                                        style: context.tt.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: context.cs.onInverseSurface,
                                        ),
                                      ),
                                      AppSvgIcon(
                                        AssetsConstants.rateIcon,
                                        size: 11,
                                        color: context.cs.onInverseSurface,
                                      ),
                                    ],
                                  ),
                                ),
                                AppText(
                                  '$total ${context.translate(LanguageLabelKeys.ratings)}',
                                  style: context.tt.bodySmall?.copyWith(
                                    color: context.cs.onSurfaceVariant,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 12,
                                  color: context.cs.outlineVariant,
                                ),
                              ],
                              if (widget.product.timeToDeliver?.isNotEmpty ==
                                  true)
                                Row(
                                  mainAxisSize: .min,
                                  spacing: 3,
                                  children: [
                                    AppSvgIcon(
                                      AssetsConstants.timeIcon,
                                      size: 13,
                                      color: context.cs.primary,
                                    ),
                                    AppText(
                                      widget.product.timeToDeliver!,
                                      style: context.tt.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: context.cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                      if (widget.product.productType == 5 &&
                          (widget.product.prescriptionNote?.isNotEmpty ==
                              true)) ...[
                        AppSpacing.h10,
                        _PrescriptionBanner(
                          note: widget.product.prescriptionNote!,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Variant axes ─────────────────────────────────────────────
                if ((widget.product.variantAxes ?? []).isNotEmpty) ...[
                  _ThinDivider(),
                  ...((widget.product.variantAxes ?? []).map((axis) {
                    final selectedValueId =
                        widget.selectedAxisValues[axis.attributeId];
                    return Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        ThemeConstants.paddingL,
                        5,
                        0,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          AppText(
                            axis.attributeName ?? '',
                            style: context.tt.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.cs.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          AppSpacing.h8,
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: (axis.values ?? []).map((val) {
                                final isSel =
                                    selectedValueId == val.attributeValueId;
                                final isAvailable =
                                    _isVariantCombinationAvailable(
                                      axis.attributeId!,
                                      val.attributeValueId!,
                                      widget.selectedAxisValues,
                                    );
                                return Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: ThemeConstants.paddingS,
                                  ),
                                  child: GestureDetector(
                                    onTap: isAvailable
                                        ? () => context
                                              .read<ProductDetailCubit>()
                                              .selectAxisValue(
                                                axis.attributeId!,
                                                val.attributeValueId!,
                                              )
                                        : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                      decoration: AppDecorations.box(
                                        color: isSel
                                            ? context.cs.primary.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.transparent,
                                        borderRadius: AppRadius.r8,
                                        border: Border.all(
                                          color: isSel
                                              ? context.cs.primary
                                              : isAvailable
                                              ? context.cs.outlineVariant
                                              : context.cs.outlineVariant
                                                    .withValues(alpha: 0.3),
                                          width: isSel ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: AppText(
                                        val.attributeValue ?? '',
                                        style: context.tt.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w400,
                                          color: isSel
                                              ? context.cs.primary
                                              : isAvailable
                                              ? context.cs.onSurface
                                              : context.cs.onSurfaceVariant
                                                    .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          AppSpacing.h6,
                        ],
                      ),
                    );
                  })),
                ],

                // ── Policies ──────────────────────────────────────────────────
                _ThinDivider(),
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: ThemeConstants.paddingL,
                    vertical: ThemeConstants.paddingXS,
                  ),
                  child: ProductDetailPoliciesSection(product: widget.product),
                ),
                _ThinDivider(),

                // ── Product Details / long description ──────────────────────────────────
                if (displayDesc.isNotEmpty && displayDesc != 'null') ...[
                  _ExpandableSection(
                    title: context.translate(LanguageLabelKeys.productInfo),
                    child: HtmlWidget(
                      displayDesc,
                      textStyle: context.tt.bodyMedium?.copyWith(
                        color: context.cs.onSurfaceVariant,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],

                // ── Custom sections ───────────────────────────────────────────
                if ((activeVariant?.customSections ?? []).isNotEmpty)
                  ...((activeVariant!.customSections!)
                      .where((s) => s.fields?.isNotEmpty == true)
                      .map((section) {
                        final textFields = (section.fields ?? [])
                            .where(
                              (f) =>
                                  f.fieldType != 'image' &&
                                  f.value?.isNotEmpty == true &&
                                  f.value != 'null',
                            )
                            .toList();
                        final imageFields = (section.fields ?? [])
                            .where(
                              (f) =>
                                  f.fieldType == 'image' &&
                                  f.value?.isNotEmpty == true &&
                                  f.value != 'null',
                            )
                            .toList();
                        if (textFields.isEmpty && imageFields.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          children: [
                            if (textFields.isNotEmpty)
                              _ExpandableSection(
                                title: section.sectionName ?? '',
                                child: Column(
                                  children: List.generate(textFields.length, (
                                    i,
                                  ) {
                                    final field = textFields[i];
                                    final isEven = i.isEven;
                                    return Container(
                                      decoration: AppDecorations.box(
                                        color: isEven
                                            ? context.cs.surfaceContainerLow
                                            : context.cs.surfaceContainerLow
                                                  .withValues(alpha: 0.3),
                                        border: Border.all(
                                          color: context.cs.surfaceContainerLow,
                                        ),
                                      ),
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                            horizontal: ThemeConstants.paddingS,
                                            vertical: ThemeConstants.paddingS,
                                          ),
                                      child: Row(
                                        crossAxisAlignment: .start,
                                        children: [
                                          SizedBox(
                                            width: 140,
                                            child: AppText(
                                              field.fieldLabel ?? '',
                                              style: context.tt.bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: context.cs.onSurface,
                                                    height: 1.5,
                                                  ),
                                            ),
                                          ),
                                          Expanded(
                                            child: AppText(
                                              field.value!,
                                              style: context.tt.bodySmall
                                                  ?.copyWith(
                                                    color: context
                                                        .cs
                                                        .onSurfaceVariant,
                                                    height: 1.5,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            if (imageFields.isNotEmpty) ...[
                              _ThinDivider(),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  ThemeConstants.paddingL,
                                  14,
                                  ThemeConstants.paddingL,
                                  ThemeConstants.paddingXS,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: AppText(
                                    section.sectionName ?? '',
                                    style: context.tt.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: context.cs.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              ...imageFields.map(
                                (field) => Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    ThemeConstants.paddingL,
                                    ThemeConstants.paddingM,
                                    ThemeConstants.paddingL,
                                    ThemeConstants.paddingM,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      if (field.fieldLabel?.isNotEmpty ==
                                          true) ...[
                                        AppText(
                                          field.fieldLabel!,
                                          style: context.tt.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: context.cs.onSurfaceVariant,
                                          ),
                                        ),
                                        AppSpacing.h8,
                                      ],
                                      ClipRRect(
                                        borderRadius: AppRadius.r8,
                                        child: AppNetworkImage(
                                          url: field.value!,
                                          height: context.screenHeight * 0.21,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      })),

                // ── Ratings ───────────────────────────────────────────────────
                ProductDetailRatingSection(
                  productRating: widget.product.productRating,
                ),

                // ── Upsell, similar & recently visited ──────────────────────────
                _ThinDivider(),
                ProductDetailUpsellSection(
                  sectionKey: widget.upsellSectionKey,
                  heroSuffix: '${widget.subSectionHeroSuffix}_upsell',
                ),
                _ThinDivider(),
                SimilarProductsSection(
                  heroSuffix: '${widget.subSectionHeroSuffix}_sp',
                ),
                _ThinDivider(),
                RecentlyVisitedSection(
                  heroSuffix: '${widget.subSectionHeroSuffix}_rv',
                ),
                // ProductDetailBottomBar floats over content (AppScaffold's
                // applyBottomInset: false here), and FloatingCartBar floats
                // above that bar in turn (52px pill + 10px own bottom
                // padding) — reserve clearance for both so the last section
                // (and its "View more" button) never sits underneath either.
                const SizedBox(height: 100 + 85),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Local widgets ───────────────────────────────────────────────────────────

class _ThinDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.cs.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;

  const _ExpandableSection({required this.title, required this.child});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingS, ThemeConstants.paddingL, ThemeConstants.paddingS),
      clipBehavior: Clip.antiAlias,
      decoration: AppDecorations.box(
        color: context.cs.surfaceContainerLowest,
        borderRadius: AppRadius.r12,
        border: Border.all(
          color: context.cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      widget.title,
                      style: context.tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.cs.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: AppSvgIcon(
                      AssetsConstants.arrowDownIcon,
                      size: 22,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: .start,
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: context.cs.outlineVariant.withValues(alpha: 0.4),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, ThemeConstants.paddingM),
                  child: widget.child,
                ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionBanner extends StatelessWidget {
  final String note;
  const _PrescriptionBanner({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: ThemeConstants.paddingM,
        vertical: 10,
      ),
      decoration: AppDecorations.box(
        color: context.cs.inversePrimary.withValues(alpha: 0.08),
        borderRadius: AppRadius.r8,
        border: Border.all(
          color: context.cs.inversePrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          AppSvgIcon(
            AssetsConstants.infoCircleIcon,
            size: 15,
            color: context.cs.inversePrimary,
          ),
          Expanded(
            child: AppText(
              note,
              style: context.tt.bodySmall?.copyWith(
                color: context.cs.inversePrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
