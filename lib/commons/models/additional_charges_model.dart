import 'package:customer/utils/json_parsers.dart';

class AdditionalCharges {
  String? name;
  double? amount;
  bool? isRefundable;

  AdditionalCharges({this.name, this.amount, this.isRefundable});

  AdditionalCharges.fromJson(Map<String, dynamic> json) {
    name = parseString(json['name']) ?? "";
    amount = parseDouble(json['amount']);
    isRefundable = parseBool(json['is_refundable']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['amount'] = amount;
    data['is_refundable'] = isRefundable;
    return data;
  }
}
