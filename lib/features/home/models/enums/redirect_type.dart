enum RedirectType {
  product,
  category,
  brand,
  none,
  unknown;

  static RedirectType fromRaw(String? raw) {
    switch (raw) {
      case 'product':
        return RedirectType.product;
      case 'category':
        return RedirectType.category;
      case 'brand':
        return RedirectType.brand;
      case 'none':
        return RedirectType.none;
      case null:
        return RedirectType.none;
      default:
        return RedirectType.unknown;
    }
  }
}
