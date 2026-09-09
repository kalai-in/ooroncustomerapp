class AppSettings {
  int? status;
  String? message;
  AppSettingsData? data;

  AppSettings({this.status, this.message, this.data});

  AppSettings.fromJson(Map<String, dynamic> json) {
    status = json['status'] ?? 0;
    message = json['message'] ?? "";
    data = json['data'] is Map<String, dynamic>
        ? AppSettingsData.fromJson(json['data'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class AppSettingsData {
  String? appName;
  String? supportNumber;
  String? supportEmail;
  String? currentVersion;
  String? isVersionSystemOn;
  String? storeAddress;
  String? mapLatitude;
  String? mapLongitude;
  String? currency;
  String? decimalPoint;
  String? systemTimezone;
  String? maxCartItemsCount;
  String? appModeCustomer;
  String? privacyPolicyDeliveryBoy;
  String? termsConditionsDeliveryBoy;
  String? privacyPolicySeller;
  String? termsConditionsSeller;
  String? aboutUs;
  String? contactUs;
  String? appModeCustomerRemark;
  String? appModeCustomerStart;
  String? appModeCustomerEnd;
  String? popupEnabled;
  String? popupAlwaysShowHome;
  String? popupType;
  String? popupTypeId;
  String? popupUrl;
  String? popupImage;
  String? requiredForceUpdate;
  String? iosIsVersionSystemOn;
  String? iosRequiredForceUpdate;
  String? iosCurrentVersion;
  String? commonMetaKeywords;
  String? commonMetaDescription;
  String? showColorPickerInWebsite;
  String? favicon;
  String? webLogo;
  String? loading;
  String? androidAppUrl;
  String? iosAppUrl;
  String? estimateDeliveryDays;
  String? phoneLogin;
  String? googleLogin;
  String? appleLogin;
  String? emailLogin;
  String? customSmsGatewayOtpBased;
  String? firebaseAuthentication;
  String? phoneAuthPassword;
  String? mapProvider;
  String? deepLinkScheme;
  String? demoMode;
  String? darkModeColor;
  String? lightModeColor;
  String? deliveryBoyDarkModeColor;
  String? deliveryBoyLightModeColor;
  String? customerDarkModeColor;
  String? customerLightModeColor;
  String? broadcastDriver;
  BroadcastConfig? broadcastConfig;
  String? clarityProjectIdCustomer;
  String? clarityStatusCustomer;
  String? passwordMinLength;
  String? passwordMaxLength;
  String? passwordRequireUppercase;
  String? passwordRequireLowercase;
  String? passwordRequireNumber;
  String? passwordRequireSpecial;

  AppSettingsData({
    this.appName,
    this.supportNumber,
    this.supportEmail,
    this.currentVersion,
    this.isVersionSystemOn,
    this.storeAddress,
    this.mapLatitude,
    this.mapLongitude,
    this.currency,
    this.decimalPoint,
    this.systemTimezone,
    this.maxCartItemsCount,
    this.appModeCustomer,
    this.privacyPolicyDeliveryBoy,
    this.termsConditionsDeliveryBoy,
    this.privacyPolicySeller,
    this.termsConditionsSeller,
    this.aboutUs,
    this.contactUs,
    this.appModeCustomerRemark,
    this.appModeCustomerStart,
    this.appModeCustomerEnd,
    this.popupEnabled,
    this.popupAlwaysShowHome,
    this.popupType,
    this.popupTypeId,
    this.popupUrl,
    this.popupImage,
    this.requiredForceUpdate,
    this.iosIsVersionSystemOn,
    this.iosRequiredForceUpdate,
    this.iosCurrentVersion,
    this.commonMetaKeywords,
    this.commonMetaDescription,
    this.showColorPickerInWebsite,
    this.favicon,
    this.webLogo,
    this.loading,
    this.androidAppUrl,
    this.iosAppUrl,
    this.estimateDeliveryDays,
    this.phoneLogin,
    this.googleLogin,
    this.appleLogin,
    this.emailLogin,
    this.customSmsGatewayOtpBased,
    this.firebaseAuthentication,
    this.phoneAuthPassword,
    this.mapProvider,
    this.deepLinkScheme,
    this.demoMode,
    this.darkModeColor,
    this.lightModeColor,
    this.deliveryBoyDarkModeColor,
    this.deliveryBoyLightModeColor,
    this.customerDarkModeColor,
    this.customerLightModeColor,
    this.broadcastDriver,
    this.broadcastConfig,
    this.clarityProjectIdCustomer,
    this.clarityStatusCustomer,
    this.passwordMinLength,
    this.passwordMaxLength,
    this.passwordRequireUppercase,
    this.passwordRequireLowercase,
    this.passwordRequireNumber,
    this.passwordRequireSpecial,
  });

  AppSettingsData.fromJson(Map<String, dynamic> json) {
    appName = json['app_name']?.toString() ?? "";
    supportNumber = json['support_number']?.toString() ?? "";
    supportEmail = json['support_email']?.toString() ?? "";
    currentVersion = json['current_version']?.toString() ?? "";
    isVersionSystemOn = json['is_version_system_on']?.toString() ?? "";
    storeAddress = json['store_address']?.toString() ?? "";
    mapLatitude = json['map_latitude']?.toString() ?? "";
    mapLongitude = json['map_longitude']?.toString() ?? "";
    currency = json['currency']?.toString() ?? "";
    decimalPoint = json['decimal_point']?.toString() ?? "";
    systemTimezone = json['system_timezone']?.toString() ?? "";
    maxCartItemsCount = json['max_cart_items_count']?.toString() ?? "";
    appModeCustomer = json['app_mode_customer']?.toString() ?? "";
    privacyPolicyDeliveryBoy =
        json['privacy_policy_delivery_boy']?.toString() ?? "";
    termsConditionsDeliveryBoy =
        json['terms_conditions_delivery_boy']?.toString() ?? "";
    privacyPolicySeller = json['privacy_policy_seller']?.toString() ?? "";
    termsConditionsSeller = json['terms_conditions_seller']?.toString() ?? "";
    aboutUs = json['about_us']?.toString() ?? "";
    contactUs = json['contact_us']?.toString() ?? "";
    appModeCustomerRemark = json['app_mode_customer_remark']?.toString() ?? "";
    appModeCustomerStart = json['app_mode_customer_start']?.toString();
    appModeCustomerEnd = json['app_mode_customer_end']?.toString();
    popupEnabled = json['popup_enabled']?.toString() ?? "";
    popupAlwaysShowHome = json['popup_always_show_home']?.toString() ?? "";
    popupType = json['popup_type']?.toString() ?? "";
    popupTypeId = json['popup_type_id']?.toString() ?? "";
    popupUrl = json['popup_url']?.toString() ?? "";
    popupImage = json['popup_image']?.toString() ?? "";
    requiredForceUpdate = json['required_force_update']?.toString() ?? "";
    iosIsVersionSystemOn = json['ios_is_version_system_on']?.toString() ?? "";
    iosRequiredForceUpdate =
        json['ios_required_force_update']?.toString() ?? "";
    iosCurrentVersion = json['ios_current_version']?.toString() ?? "";
    commonMetaKeywords = json['common_meta_keywords']?.toString() ?? "";
    commonMetaDescription = json['common_meta_description']?.toString() ?? "";
    showColorPickerInWebsite =
        json['show_color_picker_in_website']?.toString() ?? "";
    favicon = json['favicon']?.toString() ?? "";
    webLogo = json['web_logo']?.toString() ?? "";
    loading = json['loading']?.toString() ?? "";
    androidAppUrl = json['playstore_url']?.toString() ?? "";
    iosAppUrl = json['appstore_url']?.toString() ?? "";
    estimateDeliveryDays = json['delivery_estimate_days']?.toString() ?? "";
    phoneLogin = json['phone_login']?.toString() ?? "";
    googleLogin = json['google_login']?.toString() ?? "";
    appleLogin = json['apple_login']?.toString() ?? "";
    emailLogin = json['email_login']?.toString() ?? "";
    customSmsGatewayOtpBased =
        json['custom_sms_gateway_otp_based']?.toString() ?? "";
    firebaseAuthentication = json['firebase_authentication']?.toString() ?? "";
    phoneAuthPassword = json['phone_auth_password']?.toString() ?? "";
    print("map_provider:${json['map_provider']?.toString()}");
    mapProvider = json['map_provider']?.toString();
    deepLinkScheme = json['deeplink_schema']?.toString();
    demoMode = json['demo_mode']?.toString();
    darkModeColor = json['dark_mode_color']?.toString();
    lightModeColor = json['light_mode_color']?.toString();
    deliveryBoyDarkModeColor = json['delivery_boy_dark_mode_color']?.toString();
    deliveryBoyLightModeColor = json['delivery_boy_light_mode_color']
        ?.toString();
    customerDarkModeColor = json['customer_dark_mode_color']?.toString();
    customerLightModeColor = json['customer_light_mode_color']?.toString();
    broadcastDriver = json['broadcast_driver']?.toString();
    broadcastConfig = json['broadcast_config'] is Map<String, dynamic>
        ? BroadcastConfig.fromJson(
            json['broadcast_config'] as Map<String, dynamic>,
          )
        : null;
    clarityProjectIdCustomer =
        json['clarity_project_id_customer']?.toString() ?? "";
    clarityStatusCustomer =
        json['clarity_status_customer']?.toString() ?? "0";
    passwordMinLength = json['password_min_length']?.toString() ?? "5";
    passwordMaxLength = json['password_max_length']?.toString() ?? "0";
    passwordRequireUppercase =
        json['password_require_uppercase']?.toString() ?? "0";
    passwordRequireLowercase =
        json['password_require_lowercase']?.toString() ?? "0";
    passwordRequireNumber = json['password_require_number']?.toString() ?? "0";
    passwordRequireSpecial =
        json['password_require_special']?.toString() ?? "0";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['app_name'] = appName;
    data['support_number'] = supportNumber;
    data['support_email'] = supportEmail;
    data['current_version'] = currentVersion;
    data['is_version_system_on'] = isVersionSystemOn;
    data['store_address'] = storeAddress;
    data['map_latitude'] = mapLatitude;
    data['map_longitude'] = mapLongitude;
    data['currency'] = currency;
    data['decimal_point'] = decimalPoint;
    data['system_timezone'] = systemTimezone;
    data['max_cart_items_count'] = maxCartItemsCount;
    data['app_mode_customer'] = appModeCustomer;
    data['privacy_policy_delivery_boy'] = privacyPolicyDeliveryBoy;
    data['terms_conditions_delivery_boy'] = termsConditionsDeliveryBoy;
    data['privacy_policy_seller'] = privacyPolicySeller;
    data['terms_conditions_seller'] = termsConditionsSeller;
    data['about_us'] = aboutUs;
    data['contact_us'] = contactUs;
    data['app_mode_customer_remark'] = appModeCustomerRemark;
    data['app_mode_customer_start'] = appModeCustomerStart;
    data['app_mode_customer_end'] = appModeCustomerEnd;
    data['popup_enabled'] = popupEnabled;
    data['popup_always_show_home'] = popupAlwaysShowHome;
    data['popup_type'] = popupType;
    data['popup_type_id'] = popupTypeId;
    data['popup_url'] = popupUrl;
    data['popup_image'] = popupImage;
    data['required_force_update'] = requiredForceUpdate;
    data['ios_is_version_system_on'] = iosIsVersionSystemOn;
    data['ios_required_force_update'] = iosRequiredForceUpdate;
    data['ios_current_version'] = iosCurrentVersion;
    data['common_meta_keywords'] = commonMetaKeywords;
    data['common_meta_description'] = commonMetaDescription;
    data['show_color_picker_in_website'] = showColorPickerInWebsite;
    data['favicon'] = favicon;
    data['web_logo'] = webLogo;
    data['loading'] = loading;
    data['playstore_url'] = androidAppUrl;
    data['appstore_url'] = iosAppUrl;
    data['estimate_delivery_days'] = estimateDeliveryDays;
    data['phone_login'] = phoneLogin;
    data['google_login'] = googleLogin;
    data['apple_login'] = appleLogin;
    data['email_login'] = emailLogin;
    data['custom_sms_gateway_otp_based'] = customSmsGatewayOtpBased;
    data['firebase_authentication'] = firebaseAuthentication;
    data['phone_auth_password'] = phoneAuthPassword;
    data['map_provider'] = mapProvider;
    data['deeplink_schema'] = deepLinkScheme;
    data['demo_mode'] = demoMode;
    data['dark_mode_color'] = darkModeColor;
    data['light_mode_color'] = lightModeColor;
    data['delivery_boy_dark_mode_color'] = deliveryBoyDarkModeColor;
    data['delivery_boy_light_mode_color'] = deliveryBoyLightModeColor;
    data['customer_dark_mode_color'] = customerDarkModeColor;
    data['customer_light_mode_color'] = customerLightModeColor;
    data['broadcast_driver'] = broadcastDriver;
    if (broadcastConfig != null) {
      data['broadcast_config'] = broadcastConfig!.toJson();
    }

    data['clarity_project_id_customer'] = clarityProjectIdCustomer;
    data['clarity_status_customer'] = clarityStatusCustomer;
    data['password_min_length'] = passwordMinLength;
    data['password_max_length'] = passwordMaxLength;
    data['password_require_uppercase'] = passwordRequireUppercase;
    data['password_require_lowercase'] = passwordRequireLowercase;
    data['password_require_number'] = passwordRequireNumber;
    data['password_require_special'] = passwordRequireSpecial;
    return data;
  }
}

class BroadcastConfig {
  final String? key;
  final String? cluster; // pusher
  final String? host; // reverb
  final String? port; // reverb
  final String? scheme; // reverb

  BroadcastConfig({this.key, this.cluster, this.host, this.port, this.scheme});

  factory BroadcastConfig.fromJson(Map<String, dynamic> json) {
    return BroadcastConfig(
      key: json['key'] as String?,
      cluster: json['cluster'] as String?,
      host: json['host'] as String?,
      port: json['port']?.toString(),
      scheme: json['scheme'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['cluster'] = cluster;
    data['host'] = host;
    data['port'] = port;
    data['scheme'] = scheme;
    return data;
  }
}
