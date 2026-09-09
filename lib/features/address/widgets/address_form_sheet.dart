import 'package:customer/core/constants/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/commons/widgets/api_country_phone_field.dart';
import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:customer/core/local_storage/auth_hive_box.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/features/address/cubit/address_cubit.dart';
import 'package:customer/commons/cubit/countries_cubit.dart';
import 'package:customer/features/address/cubit/save_address_cubit.dart';
import 'package:customer/features/address/models/address_model.dart';
import 'package:customer/commons/models/countries_model.dart';
import 'package:customer/features/address/models/location_result.dart';
import 'package:customer/commons/animations/slide_animation.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'address_form/sheet_drag_handle.dart';
import 'address_form/sheet_header.dart';
import 'address_form/sheet_footer.dart';
import 'address_form/contact_details_section.dart';
import 'address_form/address_details_section.dart';
import 'address_form/address_type_section.dart';
import 'address_form/default_toggle_sheet.dart';
import 'address_form/save_button.dart';

class AddressFormSheet extends StatefulWidget {
  final AddressData? address;
  final LocationResult locationResult;
  final bool isEdit;
  final VoidCallback onSuccess;

  const AddressFormSheet({
    super.key,
    required this.locationResult,
    required this.isEdit,
    required this.onSuccess,
    this.address,
  });

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _altMobileCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _landmarkCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _countryCtrl;

  String _type = 'home';
  bool _isDefault = false;
  String _fullMobile = '';
  String _fullAltMobile = '';
  late String _mobileCountryCode;
  late String _altMobileCountryCode;
  CountriesData? _selectedMobileCountry;
  CountriesData? _selectedAltMobileCountry;
  bool _mobileCountryPrefilled = false;
  bool _altMobileCountryPrefilled = false;

  // Snapshotted once at init — whether these fields came pre-filled from the
  // saved address / map geocode, so later edits don't flip their lock state.
  late final bool _cityPrefilled;
  late final bool _pincodePrefilled;
  late final bool _statePrefilled;
  late final bool _countryPrefilled;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    final loc = widget.locationResult;
    final sessionName = AuthHiveBox.instance.userName;
    final sessionMobile = AuthHiveBox.instance.userMobile;
    _nameCtrl = TextEditingController(
      text: (a?.name ?? '').isNotEmpty ? a!.name! : sessionName,
    );
    _mobileCtrl = TextEditingController(
      text: (a?.mobile ?? '').isNotEmpty ? a!.mobile! : sessionMobile,
    );
    _fullMobile = _mobileCtrl.text;
    _altMobileCtrl = TextEditingController(text: a?.alternateMobile ?? '');
    _fullAltMobile = _altMobileCtrl.text;
    _addressCtrl = TextEditingController(
      text: (a?.address ?? '').isNotEmpty
          ? a!.address!
          : loc.road.isNotEmpty
          ? loc.road
          : loc.formattedAddress,
    );
    _landmarkCtrl = TextEditingController(text: a?.landmark ?? '');
    _areaCtrl = TextEditingController(
      text: (a?.area ?? '').isNotEmpty ? a!.area! : loc.area,
    );
    _pincodeCtrl = TextEditingController(
      text: (a?.pincode ?? '').isNotEmpty ? a!.pincode! : loc.pincode,
    );
    _cityCtrl = TextEditingController(
      text: (a?.city ?? '').isNotEmpty ? a!.city! : loc.city,
    );
    _stateCtrl = TextEditingController(
      text: (a?.state ?? '').isNotEmpty ? a!.state! : loc.state,
    );
    _countryCtrl = TextEditingController(
      text: (a?.country ?? '').isNotEmpty ? a!.country! : loc.country,
    );
    _cityPrefilled = _cityCtrl.text.trim().isNotEmpty;
    _pincodePrefilled = _pincodeCtrl.text.trim().isNotEmpty;
    _statePrefilled = _stateCtrl.text.trim().isNotEmpty;
    _countryPrefilled = _countryCtrl.text.trim().isNotEmpty;
    _type = a?.type ?? 'home';
    _isDefault = a?.isDefault == '1';
    const defaultDialCode = '';
    _mobileCountryCode = (a?.countryCode ?? '').isNotEmpty
        ? a!.countryCode!
        : defaultDialCode;
    _altMobileCountryCode = (a?.alternateCountryCode ?? '').isNotEmpty
        ? a!.alternateCountryCode!
        : defaultDialCode;

    final countriesState = context.read<CountriesCubit>().state;
    if (countriesState is CountriesLoaded) {
      _prefillCountries(countriesState.countries, useSetState: false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _altMobileCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    _areaCtrl.dispose();
    _pincodeCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  /// Called once from [initState] (list may already be cached) and again from
  /// the [CountriesCubit] listener once the api response arrives.
  void _prefillCountries(
    List<CountriesData> countries, {
    bool useSetState = true,
  }) {
    final mobileMatch = !_mobileCountryPrefilled
        ? (_mobileCountryCode.isNotEmpty
              ? findCountryByDialCode(countries, _mobileCountryCode)
              : findDefaultCountry(countries))
        : null;
    final altMatch = !_altMobileCountryPrefilled
        ? (_altMobileCountryCode.isNotEmpty
              ? findCountryByDialCode(countries, _altMobileCountryCode)
              : findDefaultCountry(countries))
        : null;
    if (mobileMatch == null && altMatch == null) return;

    void apply() {
      if (mobileMatch != null) {
        _mobileCountryPrefilled = true;
        _selectedMobileCountry = mobileMatch;
        _mobileCountryCode = formatDialCode(mobileMatch.dialCode);
      }
      if (altMatch != null) {
        _altMobileCountryPrefilled = true;
        _selectedAltMobileCountry = altMatch;
        _altMobileCountryCode = formatDialCode(altMatch.dialCode);
      }
    }

    if (useSetState) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final loc = widget.locationResult;
    SettingsHiveBox.instance.saveUserLocation(
      latitude: loc.latitude.toString(),
      longitude: loc.longitude.toString(),
    );
    final cubit = context.read<SaveAddressCubit>();
    if (widget.isEdit) {
      cubit.updateAddress(
        id: widget.address!.id!,
        name: _nameCtrl.text.trim(),
        mobile: _fullMobile.isNotEmpty ? _fullMobile : _mobileCtrl.text.trim(),
        countryCode: _mobileCountryCode,
        alternateMobile: _fullAltMobile.isNotEmpty
            ? _fullAltMobile
            : _altMobileCtrl.text.trim(),
        alternateCountryCode: _altMobileCtrl.text.trim().isNotEmpty
            ? _altMobileCountryCode
            : null,
        address: _addressCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        type: _type,
        latitude: loc.latitude.toString(),
        longitude: loc.longitude.toString(),
        isDefault: _isDefault,
      );
    } else {
      cubit.addAddress(
        name: _nameCtrl.text.trim(),
        mobile: _fullMobile.isNotEmpty ? _fullMobile : _mobileCtrl.text.trim(),
        countryCode: _mobileCountryCode,
        alternateMobile: _fullAltMobile.isNotEmpty
            ? _fullAltMobile
            : _altMobileCtrl.text.trim(),
        alternateCountryCode: _altMobileCtrl.text.trim().isNotEmpty
            ? _altMobileCountryCode
            : null,
        address: _addressCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        type: _type,
        latitude: loc.latitude.toString(),
        longitude: loc.longitude.toString(),
        isDefault: _isDefault,
      );
    }
  }

  void _onMobileCountryChanged(CountriesData country) => setState(() {
    _selectedMobileCountry = country;
    _mobileCountryCode = formatDialCode(country.dialCode);
  });

  void _onAltMobileCountryChanged(CountriesData country) => setState(() {
    _selectedAltMobileCountry = country;
    _altMobileCountryCode = formatDialCode(country.dialCode);
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SaveAddressCubit, SaveAddressState>(
          listener: (context, state) {
            if (state is SaveAddressSuccess) {
              final addressCubit = context.read<AddressCubit>();
              final saved = state.address;
              // Update the list locally from the response; refetch only if the
              // API didn't return the saved address.
              if (saved != null) {
                if (state.isEdit) {
                  addressCubit.updateLocally(saved);
                } else {
                  addressCubit.addLocally(saved);
                }
              } else {
                addressCubit.refresh();
              }
              AppNavigator.pop(context);
              widget.onSuccess();
            } else if (state is SaveAddressError) {
              AppSnackBar.show(
                context: context,
                message: state.message,
                type: SnackBarType.error,
              );
            }
          },
        ),
        BlocListener<CountriesCubit, CountriesState>(
          listener: (context, state) {
            if (state is CountriesLoaded) _prefillCountries(state.countries);
          },
        ),
      ],
      child: Container(
        margin: EdgeInsetsDirectional.only(
          bottom: context.keyboardInset,
        ),
        constraints: BoxConstraints(
          maxHeight: context.screenHeight * 0.92,
        ),
        decoration: AppDecorations.bottomSheet(color: context.cs.surface),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            const SheetDragHandle(),
            SheetHeader(isEdit: widget.isEdit),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingXL, ThemeConstants.paddingXS, ThemeConstants.paddingXL, ThemeConstants.paddingXL),
                  child: SlideAnimationList(
                    crossAxisAlignment: .start,
                    spacing: 20,
                    children: [
                      AddressDetailsSection(
                        addressCtrl: _addressCtrl,
                        landmarkCtrl: _landmarkCtrl,
                        areaCtrl: _areaCtrl,
                        cityCtrl: _cityCtrl,
                        pincodeCtrl: _pincodeCtrl,
                        stateCtrl: _stateCtrl,
                        countryCtrl: _countryCtrl,
                        cityPrefilled: _cityPrefilled,
                        pincodePrefilled: _pincodePrefilled,
                        statePrefilled: _statePrefilled,
                        countryPrefilled: _countryPrefilled,
                      ),
                      ContactDetailsSection(
                        nameCtrl: _nameCtrl,
                        mobileCtrl: _mobileCtrl,
                        altMobileCtrl: _altMobileCtrl,
                        selectedMobileCountry: _selectedMobileCountry,
                        selectedAltMobileCountry: _selectedAltMobileCountry,
                        onMobileCountryChanged: _onMobileCountryChanged,
                        onAltMobileCountryChanged: _onAltMobileCountryChanged,
                        onMobileChanged: (number) => _fullMobile = number,
                        onAltMobileChanged: (number) => _fullAltMobile = number,
                      ),
                      AddressTypeSection(
                        selected: _type,
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      DefaultToggleSheet(
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SheetFooter(
              child: SaveButton(isEdit: widget.isEdit, onSubmit: _submit),
            ),
          ],
        ),
      ),
    );
  }
}
