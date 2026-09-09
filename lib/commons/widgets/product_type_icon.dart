import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:flutter/material.dart';

/// 0=none | 1=veg | 2=non-veg | 3=chemical | 4=eggetarian | 5=medical
class ProductTypeIcon extends StatelessWidget {
  final int? productType;
  final double size;

  const ProductTypeIcon({super.key, this.productType, this.size = 18});

  @override
  Widget build(BuildContext context) {
    switch (productType) {
      case 1:
        return AppSvgIcon(AssetsConstants.vegIcon, size: size);
      case 2:
        return AppSvgIcon(AssetsConstants.nonVegIcon, size: size);
      case 3:
        return AppSvgIcon(AssetsConstants.chemicalIcon, size: size);
      case 4:
        return AppSvgIcon(AssetsConstants.eggetarianIcon, size: size);
      case 5:
        return AppSvgIcon(AssetsConstants.medicalIcon, size: size);
      default:
        return const SizedBox.shrink();
    }
  }
}
