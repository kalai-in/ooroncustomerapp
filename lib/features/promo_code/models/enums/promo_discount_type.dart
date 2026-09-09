enum PromoDiscountType {
  flat,
  freeDelivery,
  unknown;

  static PromoDiscountType fromRaw(String? raw) {
    switch (raw) {
      case 'flat':
        return PromoDiscountType.flat;
      case 'free_delivery':
        return PromoDiscountType.freeDelivery;
      default:
        return PromoDiscountType.unknown;
    }
  }
}
