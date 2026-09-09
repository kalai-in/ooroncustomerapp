import 'package:customer/utils/json_parsers.dart';

class OrderAddressModel {
  String? name;
  String? address;
  String? mobile;
  String? alternateMobile;
  String? latitude;
  String? longitude;

  OrderAddressModel({
    this.name,
    this.address,
    this.mobile,
    this.alternateMobile,
    this.latitude,
    this.longitude,
  });

  OrderAddressModel.fromJson(Map<String, dynamic> json) {
    name = parseString(json['name']);
    address = parseString(json['address']);
    mobile = parseString(json['mobile']);
    alternateMobile = parseString(json['alternate_mobile']);
    latitude = parseString(json['latitude']);
    longitude = parseString(json['longitude']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['address'] = address;
    data['mobile'] = mobile;
    data['alternate_mobile'] = alternateMobile;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}
