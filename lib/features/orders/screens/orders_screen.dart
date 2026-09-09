import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/utils/pagination_scroll_controller.dart';
import 'package:customer/commons/widgets/app_icon_filter_button.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/commons/widgets/app_radio_option_tile.dart';
import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/commons/widgets/paginated_list_footer.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/features/orders/widgets/order_list_skeleton_loader.dart';
import 'package:customer/core/routes/order_detail_args.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/cart/cubit/guest_cart_sync_cubit.dart';
import 'package:customer/features/orders/cubit/completed_ecommerce_order_cubit.dart';
import 'package:customer/features/orders/cubit/completed_order_cubit.dart';
import 'package:customer/features/orders/cubit/ongoing_ecommerce_order_cubit.dart';
import 'package:customer/features/orders/cubit/ongoing_order_cubit.dart';
import 'package:customer/features/orders/models/ecommerce_order_model.dart';
import 'package:customer/features/orders/models/order_model.dart';
import 'package:customer/features/orders/widgets/ecommerce_order_card.dart';
import 'package:customer/features/orders/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/commons/animations/slide_animation.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/utils/show_app_bottom_sheet.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/constants/theme_constants.dart';

/// Re-adds every item from [order] to the cart in one request via the
/// app-wide [GuestCartSyncCubit] (provided in main.dart) — works for both
/// guest and logged-in users since the bulk-add endpoint resolves the cart
/// by device/session, not strictly by auth token.
void _handleReorder(BuildContext context, OrderData order) {
  final quickIds = <String>[];
  final quickQty = <String>[];
  final ecommerceIds = <String>[];
  final ecommerceQty = <String>[];

  for (final item in order.items ?? <OrderItems>[]) {
    final variantId = (item.productVariantId ?? item.variantId)?.toString();
    final qty = item.quantity;
    if (variantId == null || variantId.isEmpty || qty == null || qty <= 0) {
      continue;
    }
    if (order.channel == AppConstants.quick) {
      quickIds.add(variantId);
      quickQty.add(qty.toString());
    } else {
      ecommerceIds.add(variantId);
      ecommerceQty.add(qty.toString());
    }
  }

  if (quickIds.isEmpty && ecommerceIds.isEmpty) return;

  context.read<GuestCartSyncCubit>().bulkAddItems(
    quickVariantIds: quickIds,
    quickQuantities: quickQty,
    ecommerceVariantIds: ecommerceIds,
    ecommerceQuantities: ecommerceQty,
  );
}

/// Re-adds a single ecommerce order item to the cart.
void _handleReorderEcommerceItem(
  BuildContext context,
  EcommerceOrderDataModel item,
) {
  final variantId = (item.productVariantId ?? item.variantId)?.toString();
  final qty = item.quantity;
  if (variantId == null || variantId.isEmpty || qty == null || qty <= 0) return;

  context.read<GuestCartSyncCubit>().bulkAddItems(
    quickVariantIds: const [],
    quickQuantities: const [],
    ecommerceVariantIds: [variantId],
    ecommerceQuantities: [qty.toString()],
  );
}

/// Reorder button visibility follows the store's globally active channel
/// (set via the home-screen quick/ecommerce toggle), not the tab currently
/// viewed — so it only appears on the listing matching the live channel.
bool get _showQuickReorder =>
    SettingsHiveBox.instance.channel == AppConstants.quick;
bool get _showEcommerceReorder =>
    SettingsHiveBox.instance.channel == AppConstants.ecommerce;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OngoingOrderCubit _ongoingCubit = OngoingOrderCubit();
  final CompletedOrderCubit _completedCubit = CompletedOrderCubit();
  final OngoingEcommerceOrderCubit _ongoingEcommerceCubit =
      OngoingEcommerceOrderCubit();
  final CompletedEcommerceOrderCubit _completedEcommerceCubit =
      CompletedEcommerceOrderCubit();
  String _channel = SettingsHiveBox.instance.channel;
  DateTimeRange? _dateRange;

  bool get _isEcommerce => _channel == AppConstants.ecommerce;

  String? get _startDateParam => _dateRange == null
      ? null
      : DateFormat('yyyy-MM-dd').format(_dateRange!.start);
  String? get _endDateParam => _dateRange == null
      ? null
      : DateFormat('yyyy-MM-dd').format(_dateRange!.end);

  @override
  void initState() {
    super.initState();
    _reloadCurrentChannel();
  }

  @override
  void dispose() {
    _ongoingCubit.close();
    _completedCubit.close();
    _ongoingEcommerceCubit.close();
    _completedEcommerceCubit.close();
    super.dispose();
  }

  void _onFilterSelected(String channel) {
    if (channel == _channel) return;
    setState(() => _channel = channel);
    _reloadCurrentChannel();
  }

  void _reloadCurrentChannel() {
    if (_isEcommerce) {
      _ongoingEcommerceCubit.applyFilters(
        EcommerceOrderFilter(
          startDate: _startDateParam,
          endDate: _endDateParam,
        ),
      );
      _completedEcommerceCubit.applyFilters(
        EcommerceOrderFilter(
          startDate: _startDateParam,
          endDate: _endDateParam,
        ),
      );
    } else {
      _ongoingCubit.applyFilters(
        OrderFilter(
          channel: _channel,
          startDate: _startDateParam,
          endDate: _endDateParam,
        ),
      );
      _completedCubit.applyFilters(
        OrderFilter(
          channel: _channel,
          startDate: _startDateParam,
          endDate: _endDateParam,
        ),
      );
    }
  }

  Future<void> _pickDateRange(BuildContext? context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context!,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _dateRange,
      builder: (context, child) {
        // Recompute every rebuild off the dialog's own live context so a
        // mid-dialog system theme change (light<->dark) updates the
        // statusbar icon immediately instead of only after reopening.
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final overlayStyle = isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: Theme(
            data: theme.copyWith(
              appBarTheme: theme.appBarTheme.copyWith(
                systemOverlayStyle: overlayStyle,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _dateRange = picked);
    _reloadCurrentChannel();
  }

  void _clearDateRange() {
    if (_dateRange == null) return;
    setState(() => _dateRange = null);
    _reloadCurrentChannel();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GuestCartSyncCubit, GuestCartSyncState>(
      listener: (context, state) {
        if (state is GuestCartSyncSuccess) {
          AppNavigator.pushNamed(context, RouteNames.checkout);
        } else if (state is GuestCartSyncError) {
          AppSnackBar.show(
            context: context,
            message: state.message,
            type: SnackBarType.error,
          );
        }
      },
      child: DefaultTabController(
        length: 2,
        child: AppScaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(
            title: context.translate(LanguageLabelKeys.myOrders),
            showBackButton: true,
            actions: [
              AppIconFilterButtonGroup(
                icon: AssetsConstants.dateIcon,
                isActive: _dateRange != null,
                tooltip: context.translate(LanguageLabelKeys.filterByDate),
                onTap: () => _pickDateRange(context),
                secondaryIcon: _dateRange != null
                    ? AssetsConstants.closeIcon
                    : null,
                onSecondaryTap: _dateRange != null ? _clearDateRange : null,
                secondaryTooltip: context.translate(
                  LanguageLabelKeys.clearFilter,
                ),
              ),
              _OrderChannelFilter(
                selected: _channel,
                onSelected: _onFilterSelected,
              ),
            ],
            bottom: const _PillTabBar(),
          ),
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: _isEcommerce
                ? [
                    MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: _ongoingEcommerceCubit),
                        BlocProvider.value(value: _completedEcommerceCubit),
                      ],
                      child: const _OngoingEcommerceOrderList(),
                    ),
                    MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: _ongoingEcommerceCubit),
                        BlocProvider.value(value: _completedEcommerceCubit),
                      ],
                      child: const _CompletedEcommerceOrderList(),
                    ),
                  ]
                : [
                    MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: _ongoingCubit),
                        BlocProvider.value(value: _completedCubit),
                      ],
                      child: const _OngoingOrderList(),
                    ),
                    MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: _ongoingCubit),
                        BlocProvider.value(value: _completedCubit),
                      ],
                      child: const _CompletedOrderList(),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _OrderChannelFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _OrderChannelFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AppSvgIcon(
        AssetsConstants.filterIcon,
        size: 22,
        color: context.cs.onSurfaceVariant,
      ),
      onPressed: () => _showFilterSheet(context),
    );
  }

  Future<void> _showFilterSheet(BuildContext context) {
    return showAppBottomSheet<void>(
      context,
      title: context.translate(LanguageLabelKeys.filterOrders),
      padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingXL, ThemeConstants.paddingM, ThemeConstants.paddingXL, ThemeConstants.paddingXXL),
      builder: (_) =>
          _OrderChannelFilterSheet(selected: selected, onSelected: onSelected),
    );
  }
}

class _OrderChannelFilterSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _OrderChannelFilterSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = <String, String>{
      AppConstants.quick: context.translate(LanguageLabelKeys.filterQuick),
      AppConstants.ecommerce: context.translate(
        LanguageLabelKeys.filterEcommerce,
      ),
    };
    final entries = options.entries.toList();

    return RadioGroup<String>(
      groupValue: selected,
      onChanged: (channel) {
        if (channel == null) return;
        AppNavigator.pop(context);
        onSelected(channel);
      },
      child: SlideAnimationList(
        children: [
          for (final entry in entries)
            AppRadioOptionTile<String>(
              value: entry.key,
              title: entry.value,
              selected: entry.key == selected,
              margin: const EdgeInsetsDirectional.only(bottom: 2),
              onTap: () {
                AppNavigator.pop(context);
                onSelected(entry.key);
              },
            ),
        ],
      ),
    );
  }
}

class _PillTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _PillTabBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final containerBg = context.cs.surfaceContainer;
    final unselectedColor = context.cs.onSurfaceVariant;
    final primary = context.cs.primary;

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingS, ThemeConstants.paddingL, ThemeConstants.paddingM),
      padding: const EdgeInsetsDirectional.all(5),
      decoration: AppDecorations.box(
        color: containerBg,
        borderRadius: AppRadius.r20,
      ),
      child: TabBar(
        indicator: AppDecorations.box(
          borderRadius: AppRadius.r16,
          gradient: LinearGradient(
            colors: [primary, primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsetsDirectional.zero,
        dividerColor: Colors.transparent,
        labelColor: context.cs.onPrimary,
        unselectedLabelColor: unselectedColor,
        labelStyle: context.tt.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: context.tt.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        splashBorderRadius: AppRadius.r16,
        tabs: [
          Tab(height: 44, text: context.translate(LanguageLabelKeys.ongoing)),
          Tab(height: 44, text: context.translate(LanguageLabelKeys.completed)),
        ],
      ),
    );
  }
}

/// Loading/error/empty/paginated-list shell shared by all 4 order-listing
/// tabs (quick + ecommerce, ongoing + completed) — they only differ in which
/// cubit feeds them and how each item card is built.
class _PaginatedOrderList<T> extends StatefulWidget {
  final BasePaginationCubit<T> cubit;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyTitle;
  final String emptySubtitle;

  const _PaginatedOrderList({
    super.key,
    required this.cubit,
    required this.itemBuilder,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  State<_PaginatedOrderList<T>> createState() =>
      _PaginatedOrderListState<T>();
}

class _PaginatedOrderListState<T> extends State<_PaginatedOrderList<T>> {
  late final _pager = PaginationScrollController(
    onLoadMore: () => widget.cubit.fetchMore(),
  );

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BasePaginationCubit<T>, PaginationState<T>>(
      bloc: widget.cubit,
      builder: (context, state) {
        if (state is PaginationLoading<T>) {
          return const OrderListSkeletonLoader();
        }

        if (state is PaginationError<T>) {
          return EmptyStateWidget(
            imagePath: AssetsConstants.noOrderFound,
            title: state.message,
            subtitle: context.translate(LanguageLabelKeys.pullToRefresh),
            onRetry: () => widget.cubit.refresh(),
          );
        }

        if (state is PaginationLoaded<T>) {
          if (state.data.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => widget.cubit.refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyStateWidget(
                    imagePath: AssetsConstants.noOrderFound,
                    title: widget.emptyTitle,
                    subtitle: widget.emptySubtitle,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.cubit.refresh(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _pager.controller,
              padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingS, ThemeConstants.paddingL, ThemeConstants.paddingL),
              itemCount: state.data.length + (state.isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.data.length) {
                  return PaginatedListFooter(
                    isLoadingMore: state.isFetchingMore,
                    hasMore: state.hasMore,
                  );
                }
                return widget.itemBuilder(context, state.data[index]);
              },
            ),
          );
        }

        return AppSpacing.shrink;
      },
    );
  }
}

// ── Ongoing ──────────────────────────────────────────────────────────────────

class _OngoingOrderList extends StatelessWidget {
  const _OngoingOrderList();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OngoingOrderCubit>();
    final completedCubit = context.read<CompletedOrderCubit>();
    return _PaginatedOrderList<OrderData>(
      cubit: cubit,
      emptyTitle: context.translate(LanguageLabelKeys.noOngoingOrders),
      emptySubtitle: context.translate(LanguageLabelKeys.noOrdersYet),
      itemBuilder: (context, order) => OrderCard(
        order: order,
        onTap: () async {
          final result = await AppNavigator.pushNamed(
            context,
            RouteNames.orderDetail,
            arguments: OrderDetailArgs(
              orderId: order.id?.toString() ?? '',
              isOngoing: true,
            ),
          );
          if (result is OrderData && context.mounted) {
            cubit.removeOrder(result.id?.toString() ?? '');
            completedCubit.addOrder(result);
          }
        },
        onTrack: () => AppNavigator.pushNamed(
          context,
          RouteNames.orderTracking,
          arguments: order,
        ),
        onReorder: _showQuickReorder
            ? () => _handleReorder(context, order)
            : null,
      ),
    );
  }
}

// ── Completed ────────────────────────────────────────────────────────────────

class _CompletedOrderList extends StatelessWidget {
  const _CompletedOrderList();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CompletedOrderCubit>();
    return _PaginatedOrderList<OrderData>(
      cubit: cubit,
      emptyTitle: context.translate(LanguageLabelKeys.noCompletedOrders),
      emptySubtitle: context.translate(LanguageLabelKeys.noOrdersYet),
      itemBuilder: (context, order) => OrderCard(
        order: order,
        onTap: () async {
          final result = await AppNavigator.pushNamed(
            context,
            RouteNames.orderDetail,
            arguments: OrderDetailArgs(orderId: order.id?.toString() ?? ''),
          );
          // Already in this list — patch (return) rather than add.
          if (result is OrderData && context.mounted) {
            cubit.patchOrder(result);
          }
        },
        onReorder: _showQuickReorder
            ? () => _handleReorder(context, order)
            : null,
      ),
    );
  }
}

// ── Ecommerce: Ongoing ──────────────────────────────────────────────────────

class _OngoingEcommerceOrderList extends StatelessWidget {
  const _OngoingEcommerceOrderList();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OngoingEcommerceOrderCubit>();
    final completedCubit = context.read<CompletedEcommerceOrderCubit>();
    return _PaginatedOrderList<EcommerceOrderDataModel>(
      cubit: cubit,
      emptyTitle: context.translate(LanguageLabelKeys.noOngoingOrders),
      emptySubtitle: context.translate(LanguageLabelKeys.noOrdersYet),
      itemBuilder: (context, item) => EcommerceOrderCard(
        order: item,
        onTap: () async {
          final result = await AppNavigator.pushNamed(
            context,
            RouteNames.ecommerceOrderDetail,
            arguments: EcommerceOrderDetailArgs(
              orderItemId: item.id?.toString() ?? '',
              isOngoing: true,
            ),
          );
          if (result is EcommerceOrderDataModel && context.mounted) {
            cubit.removeOrder(result.id);
            completedCubit.addOrder(result);
          }
        },
        onReorder: _showEcommerceReorder
            ? () => _handleReorderEcommerceItem(context, item)
            : null,
      ),
    );
  }
}

// ── Ecommerce: Completed ────────────────────────────────────────────────────

class _CompletedEcommerceOrderList extends StatelessWidget {
  const _CompletedEcommerceOrderList();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CompletedEcommerceOrderCubit>();
    return _PaginatedOrderList<EcommerceOrderDataModel>(
      cubit: cubit,
      emptyTitle: context.translate(LanguageLabelKeys.noCompletedOrders),
      emptySubtitle: context.translate(LanguageLabelKeys.noOrdersYet),
      itemBuilder: (context, item) => EcommerceOrderCard(
        order: item,
        onTap: () async {
          final result = await AppNavigator.pushNamed(
            context,
            RouteNames.ecommerceOrderDetail,
            arguments: EcommerceOrderDetailArgs(
              orderItemId: item.id?.toString() ?? '',
            ),
          );
          // Already in this list — patch (return) rather than add.
          if (result is EcommerceOrderDataModel && context.mounted) {
            cubit.patchOrder(result);
          }
        },
        onReorder: _showEcommerceReorder
            ? () => _handleReorderEcommerceItem(context, item)
            : null,
      ),
    );
  }
}
