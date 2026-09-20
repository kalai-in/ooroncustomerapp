import 'package:customer/commons/cubit/zones_cubit.dart';
import 'package:customer/commons/models/zones_model.dart';
import 'package:customer/commons/widgets/app_radio_option_tile.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/commons/widgets/app_text_field.dart';
import 'package:customer/commons/widgets/loading_widget.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:customer/utils/show_app_bottom_sheet.dart';
import 'package:customer/commons/animations/slide_animation.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Zone count above which the sheet grows a search field — a handful of zones
/// reads fine as a plain list.
const int _searchThreshold = 8;

/// Opens the delivery-zone picker bottom sheet backed by the [ZonesCubit] of
/// the calling context and resolves with the zone the user selected (or null
/// on dismiss). Zone counterpart of `showCountryPickerSheet`.
Future<ZonesData?> showZonePickerSheet(
  BuildContext context, {
  ZonesData? selected,
}) {
  final zonesCubit = context.read<ZonesCubit>();
  return showAppBottomSheet<ZonesData>(
    context,
    title: context.translate(LanguageLabelKeys.deliveryZone),
    builder: (_) => BlocProvider.value(
      value: zonesCubit,
      child: _ZonePickerSheet(selected: selected),
    ),
  );
}

class _ZonePickerSheet extends StatefulWidget {
  final ZonesData? selected;
  const _ZonePickerSheet({this.selected});

  @override
  State<_ZonePickerSheet> createState() => _ZonePickerSheetState();
}

class _ZonePickerSheetState extends State<_ZonePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry(BuildContext context) {
    final cubit = context.read<ZonesCubit>();
    final countryId = cubit.countryId;
    if (countryId != null) cubit.fetchZones(countryId, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: context.screenHeight * 0.75,
      ),
      child: BlocBuilder<ZonesCubit, ZonesState>(
        builder: (context, state) => switch (state) {
          ZonesInitial() || ZonesLoading() => const Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingXXL),
            child: LoadingWidget(),
          ),
          ZonesError(:final message) => _ErrorView(
            message: message,
            onRetry: () => _retry(context),
          ),
          ZonesLoaded(:final zones) => _buildList(context, zones),
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ZonesData> zones) {
    if (zones.isEmpty) return const _EmptyView();

    final showSearch = zones.length > _searchThreshold;
    final filtered = _query.isEmpty
        ? zones
        : zones
              .where((z) => (z.name ?? '').toLowerCase().contains(_query))
              .toList();

    return Column(
      mainAxisSize: .min,
      children: [
        if (showSearch) ...[
          AppTextField(
            controller: _searchController,
            hintText: context.translate(LanguageLabelKeys.search),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: ThemeConstants.paddingL, end: ThemeConstants.paddingS),
              child: AppSvgIcon(
                AssetsConstants.searchIcon,
                size: ThemeConstants.iconS,
                color: context.cs.onSurfaceVariant,
                fit: BoxFit.scaleDown,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            // No `border` override — the default outline set is what makes the
            // field visible against the sheet's surface-coloured background.
            contentPadding: const EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingS),
          ),
          AppSpacing.h12,
        ],
        if (filtered.isEmpty)
          const _EmptyView()
        else
          Flexible(
            child: RadioGroup<int?>(
              groupValue: widget.selected?.id,
              onChanged: (id) {
                final zone = filtered.firstWhere(
                  (z) => z.id == id,
                  orElse: () => filtered.first,
                );
                AppNavigator.pop(context, zone);
              },
              child: SlideAnimationScope(
                builder: (context, animationController) => ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final zone = filtered[index];
                    return SlideAnimation(
                      position: index,
                      itemCount: filtered.length,
                      slideDirection: SlideDirection.fromBottom,
                      animationController: animationController,
                      child: AppRadioOptionTile<int?>(
                        value: zone.id,
                        title: zone.name ?? '',
                        selected: widget.selected?.id == zone.id,
                        // Selection reads from the radio and the tile border
                        // alone — icon and label keep the normal text colour.
                        highlightSelectedColor: false,
                        margin: const EdgeInsetsDirectional.only(bottom: 2),
                        leading: AppSvgIcon(
                          AssetsConstants.addressIcon,
                          size: ThemeConstants.iconS,
                          color: context.cs.onSurface,
                        ),
                        onTap: () => AppNavigator.pop(context, zone),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingL),
      child: AppText(
        context.translate(LanguageLabelKeys.noZonesFound),
        style: context.tt.bodySmall?.copyWith(
          color: context.cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingL),
      child: Column(
        mainAxisSize: .min,
        children: [
          AppSvgIcon(
            AssetsConstants.locationOffIcon,
            size: ThemeConstants.iconL,
            color: context.cs.error,
          ),
          AppSpacing.h8,
          AppText(
            message.isNotEmpty
                ? message
                : context.translate(LanguageLabelKeys.failedToLoadZones),
            textAlign: .center,
            style: context.tt.bodySmall?.copyWith(color: context.cs.error),
          ),
          AppSpacing.h8,
          TextButton.icon(
            onPressed: onRetry,
            icon: AppSvgIcon(
              AssetsConstants.refreshIcon,
              size: ThemeConstants.iconS,
              color: context.cs.primary,
            ),
            label: AppText(context.translate(LanguageLabelKeys.retry)),
          ),
        ],
      ),
    );
  }
}
