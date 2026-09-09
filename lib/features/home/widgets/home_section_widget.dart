import 'package:customer/features/home/models/enums/block_type.dart';
import 'package:customer/features/home/models/enums/grid_layout_type.dart';
import 'package:customer/features/home/models/home_builder_model.dart';
import 'package:customer/features/home/models/enums/product_block_enums.dart';
import 'package:customer/features/home/models/enums/section_layout.dart';
import 'package:customer/features/home/widgets/home_banner_carousel.dart';
import 'package:customer/features/home/widgets/home_brand_block.dart';
import 'package:customer/features/home/widgets/home_category_block.dart';
import 'package:customer/features/home/widgets/home_grid_banner.dart';
import 'package:customer/features/home/widgets/home_product_block.dart';
import 'package:customer/features/home/widgets/home_text_section.dart';
import 'package:customer/features/home/widgets/home_title_image.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:flutter/material.dart';

class HomeSectionWidget extends StatelessWidget {
  final Sections section;
  final ValueChanged<Categories>? onCategoryTap;
  final ValueChanged<ProductDataModel>? onProductTap;
  final ValueChanged<Brands>? onBrandTap;
  final void Function(
    String title,
    String? dataSource,
    String? categoryId,
    String? manualProductIds,
  )?
  onViewMoreTap;

  const HomeSectionWidget({
    super.key,
    required this.section,
    this.onCategoryTap,
    this.onProductTap,
    this.onBrandTap,
    this.onViewMoreTap,
  });

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  // Server sends margin values authored for mobile — double them on tablet
  // so section spacing scales with the larger screen instead of looking
  // cramped relative to it.
  double _scaledMargin(BuildContext context, int? value) =>
      (value ?? 0).toDouble() * (_isTablet(context) ? 2 : 1);

  @override
  Widget build(BuildContext context) {
    final blocks = section.blocks;
    if (blocks == null || blocks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: _scaledMargin(context, section.marginTop),
        bottom: _scaledMargin(context, section.marginBottom),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: blocks.map((block) => _buildBlock(block)).toList(),
      ),
    );
  }

  Widget _buildBlock(Blocks block) {
    final radius = section.borderRadius ?? 0;
    Widget content = _blockContent(block);
    if (radius > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius.toDouble()),
        child: content,
      );
    }
    return content;
  }

  int _gridColumns(Blocks block, {int fallback = 2}) {
    final configColumns = block.config?.columns;
    if (configColumns != null && configColumns > 0) return configColumns;
    final match = RegExp(r'grid_(\d+)').firstMatch(block.layout ?? '');
    if (match != null) {
      final parsed = int.tryParse(match.group(1)!);
      if (parsed != null && parsed > 0) return parsed;
    }
    return fallback;
  }

  Widget _blockContent(Blocks block) {
    switch (BlockType.fromRaw(block.type)) {
      case BlockType.bannerSlider:
        if (block.items?.isNotEmpty == true) {
          return HomeBannerCarousel(
            items: block.items!,
            config: block.config,
            sectionBorderRadius: section.borderRadius ?? 0,
          );
        }

      case BlockType.categorySection:
        if (block.categories?.isNotEmpty == true) {
          return HomeCategoryBlock(
            categories: block.categories!,
            columns: _gridColumns(block, fallback: 4),
            gap: (block.config?.chipGap ?? 0).toDouble(),
            borderRadius: (block.config?.chipRadius ?? 0).toDouble(),
            layout: SectionLayout.fromRaw(block.layout),
            sectionTitle: block.config?.sectionTitle,
            variant: ProductVariant.fromRaw(block.config?.variant),
            backgroundImageUrl: block.config?.backgroundImageUrl,
            backgroundColor: block.config?.backgroundColor,
            textColor: block.config?.textColor,
            itemTextColor: block.config?.itemTextColor,
            bgImageAspect: block.config?.bgImageAspect,
            onTap: onCategoryTap,
          );
        }

      case BlockType.productSlider:
        if (block.products?.isNotEmpty == true) {
          return HomeProductBlock(
            products: block.products!,
            columns: block.config?.columns ?? 2,
            layout: ProductLayout.fromRaw(block.layout),
            variant: ProductVariant.fromRaw(block.config?.variant),
            backgroundImageUrl: block.config?.backgroundImageUrl,
            backgroundColor: block.config?.backgroundColor,
            textColor: block.config?.textColor,
            imageAspect: block.config?.imageAspect,
            sectionTitle: block.config?.sectionTitle,
            blockPadding: block.config?.blockPadding ?? 0,
            itemGap: block.config?.productGridGap ?? 0,
            itemRadius: block.config?.productCardRadius ?? 0,
            limit: block.config?.limit ?? 0,
            onTap: onProductTap,
            blockId: block.id ?? '',
            dataSource: block.config?.dataSource,
            categoryId: block.categoryId?.toString(),
            manualProductIds: block.manualProductIds,
            onViewMoreTap: onViewMoreTap,
            viewMorePreviewImages: block.viewMorePreviewImages,
          );
        }

      case BlockType.brandSection:
        if (block.brands?.isNotEmpty == true) {
          return HomeBrandBlock(
            brands: block.brands!,
            gap: (block.config?.brandGap ?? 0).toDouble(),
            layout: SectionLayout.fromRaw(block.layout),
            columns: _gridColumns(block, fallback: 4),
            sectionTitle: block.config?.sectionTitle,
            borderRadius: (block.config?.brandRadius ?? 0).toDouble(),
            showName: block.config?.showName,
            variant: ProductVariant.fromRaw(block.config?.variant),
            backgroundImageUrl: block.config?.backgroundImageUrl,
            backgroundColor: block.config?.backgroundColor,
            textColor: block.config?.textColor,
            itemTextColor: block.config?.itemTextColor,
            bgImageAspect: block.config?.bgImageAspect,
            onTap: onBrandTap,
          );
        }

      case BlockType.gridBanner:
        if (block.items?.isNotEmpty == true) {
          return HomeGridBanner(
            items: block.items!,
            columns: _gridColumns(block, fallback: 2),
            rows: block.config?.gridRows ?? 1,
            layoutType: GridLayoutType.fromRaw(block.config?.gridLayoutType),
            gap: block.config?.gridGap ?? 0,
            borderRadius: block.config?.tileRadius ?? 0,
            imageAspect: block.config?.imageAspect,
            variant: ProductVariant.fromRaw(block.config?.variant),
            backgroundImageUrl: block.config?.backgroundImageUrl,
            backgroundColor: block.config?.backgroundColor,
            textColor: block.config?.textColor,
            sectionTitle: block.config?.sectionTitle,
            bgImageAspect: block.config?.bgImageAspect,
            blockPadding: block.config?.blockPadding ?? 0,
          );
        }

      case BlockType.titleImage:
        return HomeTitleImage(block: block);

      case BlockType.textSection:
        return HomeTextSection(block: block);

      case BlockType.unknown:
        break;
    }

    return const SizedBox.shrink();
  }
}
