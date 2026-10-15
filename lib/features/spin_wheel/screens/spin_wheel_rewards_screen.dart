import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/commons/cubit/connectivity_cubit.dart';
import 'package:customer/commons/widgets/app_no_internet_widget.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/commons/widgets/paginated_list_footer.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/utils/pagination_scroll_controller.dart';
import 'package:customer/features/spin_wheel/cubit/spin_wheel_config_cubit.dart';
import 'package:customer/features/spin_wheel/cubit/spin_wheel_rewards_cubit.dart';
import 'package:customer/features/spin_wheel/models/spin_reward_filter_type.dart';
import 'package:customer/features/spin_wheel/widgets/spin_wheel_reward_filter_sheet.dart';
import 'package:customer/features/spin_wheel/widgets/spin_wheel_reward_skeleton_loader.dart';
import 'package:customer/features/spin_wheel/widgets/spin_wheel_reward_tile.dart';
import 'package:customer/features/spin_wheel/widgets/spin_wheel_rewards_summary_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/features/spin_wheel/models/spin_wheel_model.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/core/constants/theme_constants.dart';

typedef SpinRewardsPaginationState = PaginationState<SpinReward>;
typedef SpinRewardsLoaded = PaginationLoaded<SpinReward>;
typedef SpinRewardsError = PaginationError<SpinReward>;
typedef SpinRewardsLoading = PaginationLoading<SpinReward>;

/// "My Rewards" screen: paginated history of past spins ([SpinWheelRewardTile]
/// rows) behind a wallet-total summary card and a type filter (All / Wallet /
/// Promo Code / Free Delivery). Also reloads the `spin_wheel` config
/// ([SpinWheelConfigCubit]) alongside the rewards list ([SpinWheelRewardsCubit])
/// so the summary header's "Play Now" / countdown state stays in sync.
class SpinWheelRewardsScreen extends StatefulWidget {
  const SpinWheelRewardsScreen({super.key});

  @override
  State<SpinWheelRewardsScreen> createState() => _SpinWheelRewardsScreenState();
}

class _SpinWheelRewardsScreenState extends State<SpinWheelRewardsScreen> {
  late final _pager = PaginationScrollController(
    onLoadMore: () => context.read<SpinWheelRewardsCubit>().fetchMore(),
  );
  SpinRewardFilterType _selectedFilter = SpinRewardFilterType.all;

  @override
  void initState() {
    super.initState();
    context.read<SpinWheelRewardsCubit>().fetchInitial();
    context.read<SpinWheelConfigCubit>().load();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showSpinWheelRewardFilterSheet(
      context,
      _selectedFilter,
      onSelect: (type) {
        if (type == _selectedFilter) return;
        setState(() => _selectedFilter = type);
        context.read<SpinWheelRewardsCubit>().applyFilters(type);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          context.read<SpinWheelRewardsCubit>().fetchInitial();
          context.read<SpinWheelConfigCubit>().load();
        }
      },
      builder: (context, connectivityState) {
        return AppScaffold(
          appBar: CustomAppBar(
            title: context.translate(LanguageLabelKeys.myRewards),
            scrollController: _pager.controller,
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: _selectedFilter != SpinRewardFilterType.all,
                  child: AppSvgIcon(
                    AssetsConstants.filterIcon,
                    size: ThemeConstants.iconL,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
                onPressed: _showFilterSheet,
              ),
              AppSpacing.w4,
            ],
          ),
          // Offline replaces the body only, so the app bar's back button
          // keeps working.
          body: connectivityState is ConnectivityDisconnected
              ? const AppNoInternetView()
              : RefreshIndicator(
                  onRefresh: () async {
                    await context.read<SpinWheelRewardsCubit>().refresh();
                    if (!context.mounted) return;
                    context.read<SpinWheelConfigCubit>().load();
                  },
                  color: context.cs.primary,
                  child:
                      BlocBuilder<
                        SpinWheelRewardsCubit,
                        SpinRewardsPaginationState
                      >(
                        builder: (context, state) {
                          if (state is SpinRewardsLoading) {
                            return const SpinWheelRewardSkeletonLoader();
                          }
                          if (state is SpinRewardsError) {
                            return EmptyStateWidget(
                              imagePath: AssetsConstants.noSearchFound,
                              title: state.message,
                              subtitle: context.translate(
                                LanguageLabelKeys.pullToRefresh,
                              ),
                              onRetry: () => context
                                  .read<SpinWheelRewardsCubit>()
                                  .refresh(),
                            );
                          }
                          if (state is SpinRewardsLoaded) {
                            return _buildRewardsList(context, state);
                          }
                          return AppSpacing.shrink;
                        },
                      ),
                ),
        );
      },
    );
  }

  Widget _buildRewardsList(BuildContext context, SpinRewardsLoaded state) {
    final summary = context.read<SpinWheelRewardsCubit>().summary;

    if (state.data.isEmpty) {
      return EmptyStateWidget(
        imagePath: AssetsConstants.noSearchFound,
        title: context.translate(LanguageLabelKeys.noRewardsFound),
        subtitle: context.translate(LanguageLabelKeys.noRewardsAvailable),
      );
    }

    return _pager.attach(
      ListView.builder(
        controller: _pager.controller,
        physics: AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(
          ThemeConstants.paddingL,
          ThemeConstants.paddingM,
          ThemeConstants.paddingL,
          ThemeConstants.paddingL,
        ),
        itemCount: state.data.length + 1 + (state.isFetchingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ValueListenableBuilder(
              valueListenable: summary,
              builder: (context, summaryData, _) {
                if (summaryData == null) return const SizedBox.shrink();
                return BlocBuilder<SpinWheelConfigCubit, SpinWheelConfigState>(
                  builder: (context, configState) {
                    final spinInfo = configState is SpinWheelConfigLoaded
                        ? configState.data.spins
                        : null;
                    return SpinWheelRewardsSummaryHeader(
                      summary: summaryData,
                      spinInfo: spinInfo,
                    );
                  },
                );
              },
            );
          }
          final itemIndex = index - 1;
          if (itemIndex == state.data.length) {
            return PaginatedListFooter(
              isLoadingMore: state.isFetchingMore,
              hasMore: state.hasMore,
              skeletonBuilder: (_) => const SpinWheelRewardSkeletonLoader(
                itemCount: 1,
                shrinkWrap: true,
              ),
            );
          }
          return SpinWheelRewardTile(reward: state.data[itemIndex]);
        },
      ),
    );
  }
}
