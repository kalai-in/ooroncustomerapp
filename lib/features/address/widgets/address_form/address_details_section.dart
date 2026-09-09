import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/commons/widgets/app_text_field.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';

/// Address, landmark, area and city/pincode/state/country fields.
class AddressDetailsSection extends StatelessWidget {
  final TextEditingController addressCtrl;
  final TextEditingController landmarkCtrl;
  final TextEditingController areaCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController pincodeCtrl;
  final TextEditingController stateCtrl;
  final TextEditingController countryCtrl;

  /// Snapshotted once by the parent at init — whether these fields already
  /// had a value (from the saved address / map geocode) before the user
  /// touched anything. Deciding this from live controller text instead would
  /// re-lock a field the moment the user finishes typing into it.
  final bool cityPrefilled;
  final bool pincodePrefilled;
  final bool statePrefilled;
  final bool countryPrefilled;

  const AddressDetailsSection({
    super.key,
    required this.addressCtrl,
    required this.landmarkCtrl,
    required this.areaCtrl,
    required this.cityCtrl,
    required this.pincodeCtrl,
    required this.stateCtrl,
    required this.countryCtrl,
    required this.cityPrefilled,
    required this.pincodePrefilled,
    required this.statePrefilled,
    required this.countryPrefilled,
  });

  @override
  Widget build(BuildContext context) {
    // Fields already filled from the map pick are hidden entirely — only
    // fields missing from the geocoding result stay open for manual entry.
    final showCity = !cityPrefilled;
    final showPincode = !pincodePrefilled;
    final showState = !statePrefilled;
    final showCountry = !countryPrefilled;

    final cityField = AppTextField(
      controller: cityCtrl,
      isRequired: true,
      labelText: context.translate(LanguageLabelKeys.city),
      hintText: context.translate(LanguageLabelKeys.enterCity),
      textCapitalization: TextCapitalization.words,
      validator: (v) => (v == null || v.trim().isEmpty)
          ? context.translate(LanguageLabelKeys.required)
          : null,
    );

    final pincodeField = AppTextField(
      controller: pincodeCtrl,
      isRequired: true,
      labelText: context.translate(LanguageLabelKeys.pincode),
      hintText: context.translate(LanguageLabelKeys.enterPincode),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) => (v == null || v.trim().isEmpty)
          ? context.translate(LanguageLabelKeys.required)
          : null,
    );

    final stateField = AppTextField(
      controller: stateCtrl,
      isRequired: true,
      labelText: context.translate(LanguageLabelKeys.stateLabel),
      hintText: context.translate(LanguageLabelKeys.enterState),
      textCapitalization: TextCapitalization.words,
      validator: (v) => (v == null || v.trim().isEmpty)
          ? context.translate(LanguageLabelKeys.required)
          : null,
    );

    final countryField = AppTextField(
      controller: countryCtrl,
      isRequired: true,
      labelText: context.translate(LanguageLabelKeys.country),
      hintText: context.translate(LanguageLabelKeys.enterCountry),
      textCapitalization: TextCapitalization.words,
      validator: (v) => (v == null || v.trim().isEmpty)
          ? context.translate(LanguageLabelKeys.required)
          : null,
    );

    return Column(
      spacing: 14,
      children: [
        AppTextField(
          controller: addressCtrl,
          isRequired: true,
          labelText: context.translate(LanguageLabelKeys.address),
          hintText: context.translate(LanguageLabelKeys.enterFullAddress),
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? context.translate(LanguageLabelKeys.addressRequired)
              : null,
        ),
        AppTextField(
          controller: landmarkCtrl,
          isRequired: true,
          labelText: context.translate(LanguageLabelKeys.landmark),
          hintText: context.translate(LanguageLabelKeys.nearbyLandmark),
          textCapitalization: TextCapitalization.sentences,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? context.translate(LanguageLabelKeys.landmarkRequired)
              : null,
        ),
        AppTextField(
          controller: areaCtrl,
          isRequired: true,
          labelText: context.translate(LanguageLabelKeys.areaLocality),
          hintText: context.translate(LanguageLabelKeys.enterAreaOrLocality),
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? context.translate(LanguageLabelKeys.areaRequired)
              : null,
        ),
        if (showCity || showPincode)
          Row(
            crossAxisAlignment: .start,
            spacing: 12,
            children: [
              if (showCity) Expanded(child: cityField),
              if (showPincode) Expanded(child: pincodeField),
            ],
          ),
        if (showState || showCountry)
          Row(
            crossAxisAlignment: .start,
            spacing: 12,
            children: [
              if (showState) Expanded(child: stateField),
              if (showCountry) Expanded(child: countryField),
            ],
          ),
      ],
    );
  }
}
