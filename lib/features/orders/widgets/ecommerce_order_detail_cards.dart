import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/commons/widgets/product_image_placeholder.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/routes/order_detail_args.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/address/cubit/address_cubit.dart';
import 'package:customer/features/address/models/address_model.dart';
import 'package:customer/features/address/widgets/address_actions.dart';
import 'package:customer/features/address/widgets/address_picker_sheet.dart';
import 'package:customer/features/chat/models/chat_message.dart';
import 'package:customer/features/chat/services/chat_conversation_resolver.dart';
import 'package:customer/features/orders/cubit/ecommerce_order_detail_cubit.dart';
import 'package:customer/features/orders/cubit/order_status_update_cubit.dart';
import 'package:customer/features/orders/models/ecommerce_order_model.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/commons/widgets/app_button.dart';
import 'package:customer/features/orders/models/order_model.dart'
    show ItemRating;
import 'package:customer/features/orders/widgets/order_detail_cards.dart'
    show showCancelOrderSheet;
import 'package:customer/features/orders/utils/order_payment_utils.dart';
import 'package:customer/features/orders/widgets/order_detail_shared_widgets.dart';
import 'package:customer/utils/app_date_formatter.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:customer/utils/extensions/string_extensions.dart';
import 'package:customer/utils/order_status_labels.dart';
import 'package:customer/utils/variant_attributes_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:customer/utils/show_app_bottom_sheet.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/constants/theme_constants.dart';

class EcommerceOrderDetailReturnRejectCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  const EcommerceOrderDetailReturnRejectCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingM),
      decoration: AppDecorations.box(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.cs.error.withValues(alpha: 0.14),
            context.cs.error.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: AppRadius.r12,
        border: Border.all(
          color: context.cs.error.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: .start,
        spacing: 10,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppDecorations.box(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.cs.error,
                  context.cs.error.withValues(alpha: 0.7),
                ],
              ),
              shape: .circle,
              boxShadow: [
                BoxShadow(
                  color: context.cs.error.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: AppSvgIcon(
              AssetsConstants.dangerIcon,
              size: 18,
              color: context.cs.onError,
              fit: BoxFit.scaleDown,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 2,
              children: [
                AppText(
                  context.translate(LanguageLabelKeys.returnRejectReason),
                  style: context.tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.cs.error,
                  ),
                ),
                AppText(
                  order.returnRejectReason!,
                  style: context.tt.bodySmall?.copyWith(
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EcommerceOrderDetailCustomerInfoCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  const EcommerceOrderDetailCustomerInfoCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final fullAddress = order.address?.address.hasValue ?? false
        ? order.address!.address!
        : '';
    final orderIdText = order.orderNumber?.toString() ?? '';

    final rows = <Widget>[
      OrderDetailLabelValueRow(
        label: context.translate(LanguageLabelKeys.orderId),
        value: orderIdText,
        trailing: orderIdText.isEmpty
            ? null
            : InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: orderIdText));
                  AppSnackBar.show(
                    context: context,
                    message: context.translate(LanguageLabelKeys.copied),
                    type: SnackBarType.success,
                  );
                },
                child: AppSvgIcon(
                  AssetsConstants.copyIcon,
                  size: 16,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
      ),
      if (order.paymentMethod.hasValue)
        OrderDetailLabelValueRow(
          label: context.translate(LanguageLabelKeys.paymentMethod),
          value: formatOrderPaymentMethod(context, order.paymentMethod!),
        ),
      if (order.address?.mobile.hasValue ?? false)
        OrderDetailLabelValueRow(
          label: context.translate(LanguageLabelKeys.mobileNumber),
          value: order.address!.mobile!,
        ),
      if (fullAddress.isNotEmpty)
        OrderDetailLabelValueRow(
          label: context.translate(LanguageLabelKeys.deliveryAddress),
          value: fullAddress,
          maxLines: 2,
        ),
      if (order.date.hasValue)
        OrderDetailLabelValueRow(
          label: context.translate(LanguageLabelKeys.orderPlaced),
          value:
              '${context.translate(LanguageLabelKeys.placedOn)} ${AppDateFormatter.formatDateTime(order.date!)}',
        ),
      if (order.cancellationReason.hasValue)
        OrderDetailLabelValueRow(
          label: context.translate(LanguageLabelKeys.cancellationReason),
          value: order.cancellationReason!,
          maxLines: 3,
        ),
      if (order.returnReason.hasValue)
        OrderDetailLabelValueRow(
          label: context.translate(LanguageLabelKeys.returnReason),
          value: order.returnReason!,
          maxLines: 3,
        ),
    ];

    return OrderDetailInfoCard(rows: rows);
  }
}

class EcommerceOrderDetailItemsCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  final GlobalKey? otherItemsSectionKey;
  const EcommerceOrderDetailItemsCard({
    super.key,
    required this.order,
    this.otherItemsSectionKey,
  });

  @override
  Widget build(BuildContext context) {
    final otherItems = order.otherItems ?? [];
    final dividerColor = context.cs.outlineVariant;

    return Column(
      crossAxisAlignment: .start,
      spacing: 12,
      children: [
        OrderDetailCard(
          child: Column(
            crossAxisAlignment: .start,
            spacing: 12,
            children: [
              OrderDetailSectionTitle(
                title: context.translate(LanguageLabelKeys.items),
              ),
              EcommerceOrderDetailItemRow(order: order),
            ],
          ),
        ),
        if (otherItems.isNotEmpty) ...[
          OrderDetailCard(
            key: otherItemsSectionKey,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                OrderDetailSectionTitle(
                  title: context.translate(LanguageLabelKeys.otherItemsInOrder),
                ),
                AppSpacing.h2,
                AppText(
                  '${context.translate(LanguageLabelKeys.orderId)} ${AppConstants.hashSymbol}${order.orderId ?? ''}',
                  style: context.tt.bodySmall?.copyWith(
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
                AppSpacing.h12,
                ...otherItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      _OtherItemRow(
                        item: item,
                        currency: order.currency ?? '',
                        isOngoing: order.activeStatus == OrderStatus.paymentPending,
                      ),
                      if (i < otherItems.length - 1) ...[
                        AppSpacing.h10,
                        Divider(height: 1, color: dividerColor),
                        AppSpacing.h10,
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class EcommerceOrderDetailItemRow extends StatelessWidget {
  final EcommerceOrderDataModel order;
  const EcommerceOrderDetailItemRow({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final imgSize = context.screenWidth * 0.15;
    final variant =
        VariantAttributesFormatter.format(order.variantAttributes) ?? '';
    final hasImage = order.image.hasValue;
    final dividerColor = context.cs.outlineVariant;

    final showCancel = order.isCancellable ?? false;
    final returnEligible = order.isReturnable ?? false;
    final isRated =
        order.productRating == true &&
        order.activeStatus == OrderStatus.delivered &&
        (order.itemRating?.isNotEmpty ?? false);
    final showRate =
        order.productRating == true &&
        order.activeStatus == OrderStatus.delivered &&
        !showCancel &&
        !returnEligible &&
        !isRated;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Container(
          padding: const EdgeInsetsDirectional.all(10),
          decoration: AppDecorations.box(
            border: (showRate || isRated)
                ? Border(
                    top: BorderSide(color: dividerColor),
                    left: BorderSide(color: dividerColor),
                    right: BorderSide(color: dividerColor),
                  )
                : Border.all(color: dividerColor),
            borderRadius: (showRate || isRated)
                ? const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  )
                : AppRadius.r12,
          ),
          child: Row(
            crossAxisAlignment: .start,
            children: [
              hasImage
                  ? AppNetworkImage(
                      url: order.image!,
                      width: imgSize,
                      height: imgSize,
                      borderRadius: AppRadius.r8,
                    )
                  : ProductImagePlaceholder(size: imgSize),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 2,
                  children: [
                    AppText(
                      '${order.quantity ?? 1} × ${order.productName ?? ''}',
                      style: context.tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: .ellipsis,
                    ),
                    if (variant.isNotEmpty)
                      AppText(
                        variant,
                        style: context.tt.bodySmall?.copyWith(
                          color: context.cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              AppSpacing.w8,
              AppText(
                '${order.currency ?? ''}${order.discountedPrice ?? order.price ?? 0}',
                style: context.tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (order.prescriptionUrl != null &&
            order.prescriptionUrl!.isNotEmpty) ...[
          AppSpacing.h8,
          PrescriptionAttachmentRow(prescriptionUrl: order.prescriptionUrl!),
        ],
        if (((order.prescriptionUrl != null &&
                    order.prescriptionUrl!.isNotEmpty) ||
                returnEligible) &&
            (showCancel || returnEligible || showRate || isRated))
          AppSpacing.h8,
        Builder(
          builder: (context) {
            if (!showCancel && !returnEligible && !showRate && !isRated) {
              return AppSpacing.shrink;
            }

            return SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: .end,
                children: [
                  if (showRate || isRated)
                    EcommerceItemRatingControl(
                      order: order,
                      onRatingChanged: (data) => context
                          .read<EcommerceOrderDetailCubit>()
                          .applyItemRating(ItemRating.fromJson(data)),
                    ),
                  if (showCancel || returnEligible) AppSpacing.h8,
                  if (showCancel || returnEligible)
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (showCancel) _cancelButton(context),
                        if (returnEligible) _returnButton(context),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _cancelButton(BuildContext context) {
    return AppButton(
      label: context.translate(LanguageLabelKeys.cancelItem),
      variant: AppButtonVariant.outline,
      color: context.cs.errorContainer,
      fullWidth: false,
      height: 28,
      fontSize: 13,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: ThemeConstants.paddingXS,
      ),
      onPressed: () async {
        final reason = await showCancelOrderSheet(
          context,
          title: context.translate(LanguageLabelKeys.cancelItem),
          message: context.translate(LanguageLabelKeys.cancelItemConfirm),
          confirmLabel: context.translate(LanguageLabelKeys.cancelItem),
          hint: context.translate(LanguageLabelKeys.enterCancellationReason),
        );
        if (reason == null || !context.mounted) return;
        context.read<OrderStatusUpdateCubit>().updateStatus(
          orderId: order.orderId?.toString() ?? '',
          status: '${OrderStatus.cancelled}',
          orderItemId: order.id?.toString(),
          from: 'cancel',
          reason: reason,
        );
        AppSnackBar.show(
          context: context,
          message: context.translate(LanguageLabelKeys.requestSubmitted),
          type: SnackBarType.success,
        );
      },
    );
  }

  /// Opens the saved-address picker so the user can choose a pickup address
  /// for the return — returns the chosen address, or null if dismissed.
  Future<AddressData?> _pickReturnAddress(BuildContext context) {
    final addressCubit = AddressCubit()..fetchInitial();
    return showAppBottomSheet<AddressData>(
      context,
      showDragHandle: false,
      padding: null,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: addressCubit,
        child: AddressPickerSheet(
          selectedId: null,
          onSelect: (addr) => AppNavigator.pop(context, addr),
          onAddNew: () {
            AppNavigator.pop(context, null);
            openAddressEditor(context, addressCubit: addressCubit);
          },
        ),
      ),
    );
  }

  Widget _returnButton(BuildContext context) {
    return AppButton(
      label: context.translate(LanguageLabelKeys.returnItem),
      variant: AppButtonVariant.outline,
      fullWidth: false,
      height: 28,
      fontSize: 13,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: ThemeConstants.paddingXS,
      ),
      onPressed: () async {
        final address = await _pickReturnAddress(context);
        if (address == null || !context.mounted) return;
        final reason = await showCancelOrderSheet(
          context,
          title: context.translate(LanguageLabelKeys.returnItem),
          message: context.translate(LanguageLabelKeys.returnItemConfirm),
          confirmLabel: context.translate(LanguageLabelKeys.returnItem),
          hint: context.translate(LanguageLabelKeys.enterReturnReason),
        );
        if (reason == null || !context.mounted) return;
        context.read<OrderStatusUpdateCubit>().updateStatus(
          orderId: order.orderId?.toString() ?? '',
          status: '${OrderStatus.returned}',
          orderItemId: order.id?.toString(),
          from: 'return',
          reason: reason,
          addressId: address.id,
        );
        AppSnackBar.show(
          context: context,
          message: context.translate(LanguageLabelKeys.requestSubmitted),
          type: SnackBarType.success,
        );
      },
    );
  }
}

class _OtherItemRow extends StatelessWidget {
  final OtherItems item;
  final String currency;
  final bool isOngoing;
  const _OtherItemRow({
    required this.item,
    required this.currency,
    required this.isOngoing,
  });

  @override
  Widget build(BuildContext context) {
    final imgSize = context.screenWidth * 0.15;
    final hasImage = item.image.hasValue;

    return InkWell(
      onTap: item.orderItemId == null
          ? null
          : () => AppNavigator.pushNamed(
              context,
              RouteNames.ecommerceOrderDetail,
              arguments: EcommerceOrderDetailArgs(
                orderItemId: item.orderItemId!.toString(),
                isOngoing: isOngoing,
              ),
            ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          hasImage
              ? AppNetworkImage(
                  url: item.image!,
                  width: imgSize,
                  height: imgSize,
                  borderRadius: AppRadius.r8,
                )
              : ProductImagePlaceholder(size: imgSize),
          AppSpacing.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                AppText(
                  '${item.quantity ?? 1} × ${item.productName ?? ''}',
                  style: context.tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: .ellipsis,
                ),
                if (item.finalTotal != null) ...[
                  AppSpacing.h2,
                  AppText(
                    '$currency${item.finalTotal}',
                    style: context.tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.orderItemId != null)
            Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: AppSvgIcon(
                AssetsConstants.arrowRightIcon,
                size: 18,
                color: context.cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class EcommerceOrderDetailPriceSummaryCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  final VoidCallback? onDownloadInvoice;
  final bool isDownloadingInvoice;
  const EcommerceOrderDetailPriceSummaryCard({
    super.key,
    required this.order,
    this.onDownloadInvoice,
    this.isDownloadingInvoice = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = order.currency ?? '';
    final hasPromo = order.promoDiscount != null && order.promoDiscount != 0;
    final paymentInfo = resolveOrderPaymentInfo(
      context: context,
      walletUsed: order.walletBalance,
      finalTotal: order.finalTotal,
      rawPaymentMethod: order.paymentMethod,
      isDelivered: order.activeStatus == OrderStatus.delivered,
    );
    final hasWallet = paymentInfo.hasWallet;
    final hasAdditional =
        order.additionalCharges != null && order.additionalCharges!.isNotEmpty;
    final hasSurge =
        order.surgeCharges != null && order.surgeCharges!.isNotEmpty;
    final saved = (order.savedAmount ?? 0) > 0
        ? order.savedAmount!
        : (order.promoDiscount ?? 0);
    final hasCashback =
        order.cashbackCredited == 1 && (order.cashbackAmount ?? 0) > 0;

    return OrderDetailBillSummaryCard(
      currency: currency,
      onDownloadInvoice: onDownloadInvoice,
      isDownloadingInvoice: isDownloadingInvoice,
      walletValue: (hasWallet && !paymentInfo.isFullyPaidByWallet)
          ? '${order.walletBalance}'
          : null,
      totalRowLabel: paymentInfo.totalRowLabel,
      totalRowValue: '$currency${paymentInfo.totalRowAmount}',
      saved: saved,
      cashbackText: hasCashback
          ? '${context.translate(LanguageLabelKeys.cashback)} $currency${order.cashbackAmount!.toStringAsFixed(2)}'
          : null,
      cashbackSubtitle: hasCashback
          ? context.translate(LanguageLabelKeys.cashbackCreditedToWallet)
          : null,
      rows: [
        OrderDetailPriceRow(
          label: context.translate(LanguageLabelKeys.subtotal),
          value: '$currency${order.subTotal ?? 0}',
          suffixLabel: (order.taxAmount != null && order.taxAmount != 0)
              ? context.translate(LanguageLabelKeys.inclTax)
              : null,
        ),
        OrderDetailPriceRow(
          label: context.translate(LanguageLabelKeys.deliveryCharge),
          value: '$currency${order.deliveryCharge ?? 0}',
        ),
        if (hasPromo)
          OrderDetailPriceRow(
            label: context.translate(LanguageLabelKeys.discount),
            value: '- $currency${order.promoDiscount}',
            valueColor: context.cs.onSecondaryContainer,
          ),
        if (hasAdditional)
          ...order.additionalCharges!.map(
            (charge) => OrderDetailPriceRow(
              label:
                  charge.name ??
                  context.translate(LanguageLabelKeys.additional),
              value: '$currency${charge.amount ?? 0}',
              isRefundable: charge.isRefundable,
            ),
          ),
        if (hasSurge)
          ...order.surgeCharges!.map(
            (surge) => OrderDetailPriceRow(
              label: surge.label ?? '',
              value: '$currency${surge.charge ?? 0}',
              isRefundable: surge.isRefundable,
            ),
          ),
      ],
    );
  }
}

class EcommerceOrderDetailTrackingCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  const EcommerceOrderDetailTrackingCard({super.key, required this.order});

  Future<void> _openTrackingUrl() async {
    final uri = Uri.tryParse(order.trackingUrl ?? '');
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyTrackingId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: order.trackingId!));
    AppSnackBar.show(
      context: context,
      message: context.translate(LanguageLabelKeys.copied),
      type: SnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrderDetailCard(
      child: Column(
        crossAxisAlignment: .start,
        spacing: 12,
        children: [
          OrderDetailSectionTitle(
            title: context.translate(LanguageLabelKeys.trackingDetails),
          ),
          Row(
            crossAxisAlignment: .center,
            spacing: 12,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: context.cs.surfaceContainerHighest,
                child: AppSvgIcon(AssetsConstants.deliveryBikeIcon, size: 22),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 3,
                  children: [
                    AppText(
                      context.translate(LanguageLabelKeys.courierAgency),
                      style: context.tt.bodySmall?.copyWith(
                        color: context.cs.onSurfaceVariant,
                      ),
                    ),
                    AppText(
                      order.courierAgency!,
                      style: context.tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const OrderDetailDivider(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 3,
                  children: [
                    AppText(
                      context.translate(LanguageLabelKeys.trackingId),
                      style: context.tt.bodySmall?.copyWith(
                        color: context.cs.onSurfaceVariant,
                      ),
                    ),
                    AppText(
                      order.trackingId!,
                      style: context.tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: AppRadius.r8,
                onTap: () => _copyTrackingId(context),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(6),
                  child: AppSvgIcon(
                    AssetsConstants.copyIcon,
                    size: 18,
                    color: context.cs.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openTrackingUrl,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.r8),
              ),
              icon: const AppSvgIcon(
                AssetsConstants.openInNewRoundedIcon,
                size: 16,
              ),
              label: AppText(
                context.translate(LanguageLabelKeys.trackShipment),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EcommerceOrderDetailStoreDeliveryCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  const EcommerceOrderDetailStoreDeliveryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return OrderDetailDeliveryBoyView(
      deliveryBoyName: order.deliveryBoyName ?? '',
      deliveryBoyMobile: order.deliveryBoyMobile,
      showChat: order.isDeliveryBoyChatVisible == true,
      onChatTap: () async {
        final orderId = order.orderId?.toString() ?? '';
        final conversationId = await resolveOrderConversationId(
          orderId,
          orderItemId: order.id?.toString(),
        );
        if (!context.mounted) return;
        AppNavigator.pushNamed(
          context,
          RouteNames.chat,
          arguments: ChatScreenArgs(
            chatType: ChatType.deliveryBoyChat,
            recipientName: order.deliveryBoyName ?? '',
            recipientId: order.deliveryBoyId ?? 0,
            orderId: orderId,
            conversationId: conversationId,
          ),
        );
      },
    );
  }
}
