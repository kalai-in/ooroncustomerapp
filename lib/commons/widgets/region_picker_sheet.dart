import 'package:customer/commons/cubit/regions_cubit.dart';
import 'package:customer/commons/models/regions_model.dart';
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

/// Region count above which the sheet grows a search field — a handful of
/// regions reads fine as a plain list.
const int _searchThreshold = 8;

/// Opens the state/region picker bottom sheet backed by the [RegionsCubit] of
/// the calling context and resolves with the region the user selected (or
/// null on dismiss). Region counterpart of `showZonePickerSheet`.
Future<RegionsData?> showRegionPickerSheet(
  BuildContext context, {
  RegionsData? selected,
}) {
  final regionsCubit = context.read<RegionsCubit>();
  return showAppBottomSheet<RegionsData>(
    context,
    title: context.translate(LanguageLabelKeys.stateLabel),
    builder: (_) => BlocProvider.value(
      value: regionsCubit,
      child: _RegionPickerSheet(selected: selected),
    ),
  );
}

class _RegionPickerSheet extends StatefulWidget {
  final RegionsData? selected;
  const _RegionPickerSheet({this.selected});

  @override
  State<_RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<_RegionPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry(BuildContext context) {
    final cubit = context.read<RegionsCubit>();
    final countryId = cubit.countryId;
    if (countryId != null) cubit.fetchRegions(countryId, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: context.screenHeight * 0.75,
      ),
      child: BlocBuilder<RegionsCubit, RegionsState>(
        builder: (context, state) => switch (state) {
          RegionsInitial() || RegionsLoading() => const Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingXXL),
            child: LoadingWidget(),
          ),
          RegionsError(:final message) => _ErrorView(
            message: message,
            onRetry: () => _retry(context),
          ),
          RegionsLoaded(:final regions) => _buildList(context, regions),
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<RegionsData> regions) {
    if (regions.isEmpty) return const _EmptyView();

    final showSearch = regions.length > _searchThreshold;
    final filtered = _query.isEmpty
        ? regions
        : regions
              .where((r) => (r.name ?? '').toLowerCase().contains(_query))
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
                final region = filtered.firstWhere(
                  (r) => r.id == id,
                  orElse: () => filtered.first,
                );
                AppNavigator.pop(context, region);
              },
              child: SlideAnimationScope(
                builder: (context, animationController) => ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final region = filtered[index];
                    return SlideAnimation(
                      position: index,
                      itemCount: filtered.length,
                      slideDirection: SlideDirection.fromBottom,
                      animationController: animationController,
                      child: AppRadioOptionTile<int?>(
                        value: region.id,
                        title: region.name ?? '',
                        selected: widget.selected?.id == region.id,
                        // Selection reads from the radio and the tile border
                        // alone — icon and label keep the normal text colour.
                        highlightSelectedColor: false,
                        margin: const EdgeInsetsDirectional.only(bottom: 2),
                        leading: AppSvgIcon(
                          AssetsConstants.addressIcon,
                          size: ThemeConstants.iconS,
                          color: context.cs.onSurface,
                        ),
                        onTap: () => AppNavigator.pop(context, region),
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
        context.translate(LanguageLabelKeys.noRegionsFound),
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
                : context.translate(LanguageLabelKeys.failedToLoadRegions),
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
