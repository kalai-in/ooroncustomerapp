import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/orders/cubit/ecommerce_order_detail_cubit.dart';
import 'package:customer/features/orders/cubit/invoice_download_cubit.dart';
import 'package:customer/features/orders/cubit/order_status_update_cubit.dart';
import 'package:customer/features/orders/widgets/ecommerce_order_detail_cards.dart';
import 'package:customer/features/orders/widgets/order_detail_cards.dart'
    show OrderDetailOtpCard;
import 'package:customer/features/orders/widgets/order_detail_shared_widgets.dart';
import 'package:customer/features/orders/widgets/order_detail_skeleton_loader.dart';
import 'package:customer/features/orders/widgets/order_help_button.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/extensions/string_extensions.dart';
import 'package:customer/utils/order_status_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/core/constants/theme_constants.dart';

class EcommerceOrderDetailScreen extends StatelessWidget {
  final String orderItemId;

  /// Gates OTP visibility — true only when opened from the Ongoing tab.
  final bool isOngoing;
  final GlobalKey _otherItemsSectionKey = GlobalKey();

  EcommerceOrderDetailScreen({
    super.key,
    required this.orderItemId,
    this.isOngoing = false,
  });

  void _scrollToOtherItems() {
    final sectionContext = _otherItemsSectionKey.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  /// Returns the changed item to the listing screen so it can move it from
  /// Ongoing to Completed (cancel) or patch it in place (return) locally,
  /// without a refetch.
  void _popWithResult(BuildContext context) {
    final state = context.read<EcommerceOrderDetailCubit>().state;
    final order = state is EcommerceOrderDetailLoaded
        ? state.orderDetail
        : null;
    final changed =
        order != null &&
        (order.activeStatus == OrderStatus.cancelled ||
            order.returnRequested == 1);
    AppNavigator.pop(context, changed ? order : null);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderStatusUpdateCubit>(
          create: (_) => OrderStatusUpdateCubit(),
        ),
        BlocProvider<InvoiceDownloadCubit>(
          create: (_) => InvoiceDownloadCubit(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<OrderStatusUpdateCubit, OrderStatusUpdateState>(
            listener: (context, state) {
              if (state is OrderStatusUpdateLoaded && state.data != null) {
                context.read<EcommerceOrderDetailCubit>().applyStatusUpdate(
                  state.data!,
                );
              } else if (state is OrderStatusUpdateError) {
                AppSnackBar.show(
                  context: context,
                  message: state.message,
                  type: SnackBarType.error,
                );
              }
            },
          ),
          BlocListener<InvoiceDownloadCubit, InvoiceDownloadState>(
            listener: (context, state) async {
              if (state is InvoiceDownloadLoaded) {
                await OpenFile.open(state.file.path);
              } else if (state is InvoiceDownloadError) {
                AppSnackBar.show(
                  context: context,
                  message: state.message,
                  type: SnackBarType.error,
                );
              }
            },
          ),
        ],
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _popWithResult(context);
          },
          child: AppScaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: CustomAppBar(
              title: context.translate(LanguageLabelKeys.orderDetail),
              showBackButton: true,
              onBackPressed: () => _popWithResult(context),
              actions: [
                BlocBuilder<
                  EcommerceOrderDetailCubit,
                  EcommerceOrderDetailState
                >(
                  builder: (context, state) {
                    final id = state is EcommerceOrderDetailLoaded
                        ? state.orderDetail.orderId?.toString()
                        : null;
                    if (id == null || id.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return OrderHelpButton(orderId: id);
                  },
                ),
              ],
            ),
            body: BlocBuilder<EcommerceOrderDetailCubit, EcommerceOrderDetailState>(
              builder: (context, state) {
                if (state is EcommerceOrderDetailLoading) {
                  return const OrderDetailSkeletonLoader();
                }

                if (state is EcommerceOrderDetailError) {
                  return EmptyStateWidget(
                    imagePath: AssetsConstants.noOrderFound,
                    title: state.message,
                    subtitle: context.translate(
                      LanguageLabelKeys.pullToRefresh,
                    ),
                    onRetry: () => context
                        .read<EcommerceOrderDetailCubit>()
                        .loadOrderDetail(orderItemId),
                  );
                }

                if (state is EcommerceOrderDetailLoaded) {
                  final order = state.orderDetail;
                  final hasDeliveryBoy =
                      order.deliveryBoyName.hasValue &&
                      (order.isDeliveryBoyChatVisible == true ||
                          (order.activeStatus != OrderStatus.delivered &&
                              order.activeStatus != OrderStatus.cancelled &&
                              order.activeStatus != OrderStatus.returned));
                  final hasTrackingInfo =
                      order.activeStatus != OrderStatus.cancelled &&
                      order.activeStatus != OrderStatus.returned &&
                      (order.courierAgency ?? '').isNotEmpty &&
                      (order.trackingId ?? '').isNotEmpty &&
                      (order.trackingUrl ?? '').isNotEmpty;
                  final hasReturnRejectReason = order.returnRejectReason.hasValue;

                  return RefreshIndicator(
                    onRefresh: () => context
                        .read<EcommerceOrderDetailCubit>()
                        .loadOrderDetail(orderItemId),
                    child: ListView(
                      padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingL),
                      children: [
                        OrderTimelineStatusCard(
                          statusLabel:
                              '${context.translate(LanguageLabelKeys.item)} ${order.orderItemStatus ?? (order.activeStatus == OrderStatus.paymentPending ? 'Ongoing' : 'Completed')}',
                          color:
                              order.activeStatus == OrderStatus.paymentPending
                              ? context.cs.errorContainer
                              : context.cs.onSecondaryContainer,
                          timeline: order.timeline,
                          icon: OrderStatusLabels.icon(order.activeStatus),
                          moreItemsCount: order.otherItems?.length ?? 0,
                          moreItemsThumbnails: (order.otherItems ?? [])
                              .map((item) => item.image ?? '')
                              .toList(),
                          onMoreItemsTap:
                              (order.otherItems?.isNotEmpty ?? false)
                              ? _scrollToOtherItems
                              : null,
                        ),
                        if (hasReturnRejectReason) ...[
                          AppSpacing.h12,
                          EcommerceOrderDetailReturnRejectCard(order: order),
                        ],
                        if ((order.refundAmount ?? 0) > 0) ...[
                          AppSpacing.h12,
                          OrderDetailRefundCard(
                            refundAmount: order.refundAmount!,
                            currency: order.currency ?? '',
                          ),
                        ],
                        if (isOngoing &&
                            order.otp != null &&
                            order.otp != 0) ...[
                          AppSpacing.h12,
                          OrderDetailOtpCard(otp: order.otp!.toString()),
                        ],
                        if (hasTrackingInfo) ...[
                          AppSpacing.h12,
                          EcommerceOrderDetailTrackingCard(order: order),
                        ],
                        AppSpacing.h12,
                        EcommerceOrderDetailItemsCard(
                          order: order,
                          otherItemsSectionKey: _otherItemsSectionKey,
                        ),
                        AppSpacing.h12,
                        EcommerceOrderDetailCustomerInfoCard(order: order),
                        AppSpacing.h12,
                        BlocBuilder<InvoiceDownloadCubit, InvoiceDownloadState>(
                          builder: (context, invoiceState) {
                            return EcommerceOrderDetailPriceSummaryCard(
                              order: order,
                              isDownloadingInvoice:
                                  invoiceState is InvoiceDownloadLoading,
                              onDownloadInvoice: () => context
                                  .read<InvoiceDownloadCubit>()
                                  .downloadEcommerceInvoice(orderItemId),
                            );
                          },
                        ),
                        if (hasDeliveryBoy) ...[
                          AppSpacing.h12,
                          EcommerceOrderDetailStoreDeliveryCard(order: order),
                        ],
                        AppSpacing.h80,
                      ],
                    ),
                  );
                }

                return AppSpacing.shrink;
              },
            ),
          ),
        ),
      ),
    );
  }
}
