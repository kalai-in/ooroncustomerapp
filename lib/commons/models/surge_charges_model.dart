import 'package:customer/utils/json_parsers.dart';

class SurgeCharges {
  String? label;
  double? charge;
  bool? isRefundable;

  SurgeCharges({this.label, this.charge, this.isRefundable});

  SurgeCharges.fromJson(Map<String, dynamic> json) {
    label = parseString(json['label']) ?? "";
    charge = parseDouble(json['charge']);
    isRefundable = parseBool(json['is_refundable']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = label;
    data['charge'] = charge;
    data['is_refundable'] = isRefundable;
    return data;
  }
}
