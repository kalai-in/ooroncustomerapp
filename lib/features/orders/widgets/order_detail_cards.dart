import 'package:customer/commons/widgets/app_button.dart';
import 'package:customer/commons/widgets/app_confirm_dialog.dart';
import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/commons/widgets/app_text_field.dart';
import 'package:customer/commons/widgets/product_image_placeholder.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/chat/models/chat_message.dart';
import 'package:customer/features/chat/services/chat_conversation_resolver.dart';
import 'package:customer/features/orders/cubit/order_detail_cubit.dart';
import 'package:customer/features/orders/cubit/order_status_update_cubit.dart';
import 'package:customer/features/orders/models/order_model.dart';
import 'package:customer/features/orders/utils/order_payment_utils.dart';
import 'package:customer/features/orders/widgets/order_detail_shared_widgets.dart';
import 'package:customer/features/orders/widgets/rate_product_sheet.dart';
import 'package:customer/features/products/cubit/rating_add_update_cubit.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/utils/app_date_formatter.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:customer/utils/extensions/string_extensions.dart';
import 'package:customer/utils/order_status_labels.dart';
import 'package:customer/commons/animations/slide_animation.dart';
import 'package:customer/utils/variant_attributes_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/utils/show_app_bottom_sheet.dart';
import 'package:customer/core/constants/theme_constants.dart';

/// Confirm + optional reason prompt shared by cancel/return — returns the
/// entered reason (possibly empty) if confirmed, or null if dismissed.
Future<String?> _promptReason(
  BuildContext context,
  String title,
  String message,
) async {
  final controller = TextEditingController();
  final confirmed = await AppConfirmDialog.show(
    context: context,
    icon: AppConfirmDialogIcon.warning,
    title: title,
    message: message,
    cancelLabel: context.translate(LanguageLabelKeys.cancel),
    confirmLabel: context.translate(LanguageLabelKeys.submit),
    extraContent: AppTextField(
      controller: controller,
      maxLines: 2,
      hintText: context.translate(LanguageLabelKeys.enterMessage),
    ),
  );
  return confirmed == true ? controller.text.trim() : null;
}

/// Bottom sheet asking for an optional cancel reason — returns the entered
/// reason (possibly empty) if confirmed, or null if dismissed.
Future<String?> showCancelOrderSheet(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? hint,
}) {
  return showAppBottomSheet<String?>(
    context,
    showDragHandle: false,
    padding: null,
    builder: (_) => _CancelOrderSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      hint: hint,
    ),
  );
}

class _CancelOrderSheet extends StatefulWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? hint;
  const _CancelOrderSheet({
    required this.title,
    required this.message,
    this.confirmLabel,
    this.hint,
  });

  @override
  State<_CancelOrderSheet> createState() => _CancelOrderSheetState();
}

class _CancelOrderSheetState extends State<_CancelOrderSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        ThemeConstants.paddingXL,
        ThemeConstants.paddingM,
        ThemeConstants.paddingXL,
        ThemeConstants.paddingXL +
            context.keyboardInset +
            context.bottomSafePadding,
      ),
      child: SlideAnimationList(
        crossAxisAlignment: .start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: AppDecorations.dragHandle(
                color: context.cs.outlineVariant,
              ),
            ),
          ),
          AppSpacing.h20,
          Center(
            child: AppText(
              widget.title,
              textAlign: .center,
              style: context.tt.titleLarge?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: context.cs.onSurface,
              ),
            ),
          ),
          AppSpacing.h6,
          Center(
            child: AppText(
              widget.message,
              textAlign: .center,
              style: context.tt.bodySmall?.copyWith(
                fontSize: 13,
                color: context.cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          AppSpacing.h20,
          AppTextField(
            controller: _controller,
            maxLines: 3,
            hintText:
                widget.hint ??
                context.translate(LanguageLabelKeys.enterMessage),
          ),
          AppSpacing.h24,
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: AppButton(
                  label: context.translate(LanguageLabelKeys.cancel),
                  variant: AppButtonVariant.outline,
                  height: 48,
                  onPressed: () => AppNavigator.pop(context, null),
                ),
              ),
              Expanded(
                child: AppButton(
                  label:
                      widget.confirmLabel ??
                      context.translate(LanguageLabelKeys.cancelOrder),
                  height: 48,
                  onPressed: () =>
                      AppNavigator.pop(context, _controller.text.trim()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _runStatusUpdate(
  BuildContext context, {
  required String orderId,
  required String status,
  String? orderItemId,
  required String from,
  required String reason,
}) {
  context.read<OrderStatusUpdateCubit>().updateStatus(
    orderId: orderId,
    status: status,
    orderItemId: orderItemId,
    from: from,
    reason: reason,
  );
}

class OrderDetailInstructionCard extends StatelessWidget {
  final String note;
  const OrderDetailInstructionCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return OrderDetailCard(
      child: Row(
        crossAxisAlignment: .start,
        spacing: 12,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: AppDecorations.box(
              color: context.cs.errorContainer.withValues(alpha: 0.12),
              shape: .circle,
            ),
            child: AppSvgIcon(
              AssetsConstants.noteIcon,
              size: 17,
              color: context.cs.errorContainer,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 4,
              children: [
                AppText(
                  context.translate(LanguageLabelKeys.deliveryInstruction),
                  style: context.tt.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
                AppText(
                  note,
                  style: context.tt.bodySmall?.copyWith(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: context.cs.onSurfaceVariant,
                    height: 1.4,
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

class OrderDetailOtpCard extends StatelessWidget {
  final String otp;
  const OrderDetailOtpCard({super.key, required this.otp});

  void _copyOtp(BuildContext context) {
    Clipboard.setData(ClipboardData(text: otp));
    AppSnackBar.show(
      context: context,
      message: context.translate(LanguageLabelKeys.copied),
      type: SnackBarType.success,
    );
  }

  void _shareOtp(BuildContext context) {
    SharePlus.instance.share(
      ShareParams(
        text: '${context.translate(LanguageLabelKeys.deliveryOtp)}: $otp',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor = context.cs.outlineVariant;
    return OrderDetailCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          AppText(
            context.translate(LanguageLabelKeys.deliveryVerification),
            style: context.tt.bodyMedium?.copyWith(
              color: context.cs.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          AppSpacing.h8,
          AppText(
            context.translate(
              LanguageLabelKeys.shareOtpWithDeliveryPartnerMessage,
            ),
            style: context.tt.bodySmall?.copyWith(
              color: context.cs.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          AppSpacing.h10,
          Center(
            child: Row(
              mainAxisSize: .min,
              children: otp
                  .split('')
                  .map(
                    (digit) => Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 6,
                      ),
                      child: AppText(
                        digit,
                        style: context.tt.headlineSmall?.copyWith(
                          color: context.cs.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          AppSpacing.h10,
          Divider(color: dividerColor, height: 1),
          AppSpacing.h8,
          Row(
            children: [
              Expanded(
                child: _OtpActionButton(
                  icon: AssetsConstants.copyIcon,
                  label: context.translate(LanguageLabelKeys.copyOtp),
                  onTap: () => _copyOtp(context),
                ),
              ),
              Container(width: 1, height: 20, color: dividerColor),
              Expanded(
                child: _OtpActionButton(
                  icon: AssetsConstants.shareIcon,
                  label: context.translate(LanguageLabelKeys.shareOtp),
                  onTap: () => _shareOtp(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtpActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _OtpActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.r8,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: .center,
          spacing: 6,
          children: [
            AppSvgIcon(icon, color: context.cs.primary, size: 16),
            AppText(
              label,
              style: context.tt.bodySmall?.copyWith(
                color: context.cs.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailCustomerInfoCard extends StatelessWidget {
  final OrderData order;
  final Widget? footer;
  const OrderDetailCustomerInfoCard({
    super.key,
    required this.order,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final fullAddress = order.orderAddress.hasValue
        ? order.orderAddress!
        : '';
    final orderIdText = order.orderNumber?.toString() ?? '';
    final customerLine = [
      if (order.userName.hasValue) order.userName!,
      if (order.mobile.hasValue) order.mobile!,
    ].join(' · ');

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
      if (customerLine.isNotEmpty)
        OrderDetailLabelValueRow(
          label: context.translate(LanguageLabelKeys.customerInfo),
          value: customerLine,
        ),
      if (fullAddress.isNotEmpty)
        OrderDetailLabelValueRow(
          label: context.translate(LanguageLabelKeys.deliverTo),
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
    ];

    return OrderDetailInfoCard(rows: rows, footer: footer);
  }
}

class OrderDetailItemsCard extends StatelessWidget {
  final List<OrderItems> items;
  final String? currency;
  final OrderData order;
  const OrderDetailItemsCard({
    super.key,
    required this.items,
    this.currency,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return OrderDetailCard(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          OrderDetailSectionTitle(
            title:
                '${context.translate(LanguageLabelKeys.items)} (${items.length})',
          ),
          AppSpacing.h12,
          Builder(
            builder: (context) {
              // Same product id can appear as multiple order line-items
              // (e.g. split quantities). Rating is product-level, so only
              // the LAST occurrence of a product id shows the rating
              // control — earlier duplicates stay silent on rating.
              final lastIndexByProductId = <int, int>{};
              for (var idx = 0; idx < items.length; idx++) {
                final pid = items[idx].productId;
                if (pid != null) lastIndexByProductId[pid] = idx;
              }
              return Column(
                children: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final pid = item.productId;
                  final showRatingControl =
                      pid == null || lastIndexByProductId[pid] == i;
                  return _OrderDetailItemRowSlot(
                    item: item,
                    currency: currency,
                    order: order,
                    showRatingControl: showRatingControl,
                    isLast: i == items.length - 1,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrderDetailItemRowSlot extends StatelessWidget {
  final OrderItems item;
  final String? currency;
  final OrderData order;
  final bool showRatingControl;
  final bool isLast;
  const _OrderDetailItemRowSlot({
    required this.item,
    this.currency,
    required this.order,
    required this.showRatingControl,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OrderDetailItemRow(
          item: item,
          currency: currency,
          order: order,
          showRatingControl: showRatingControl,
        ),
        if (!isLast) ...[
          AppSpacing.h10,
          Divider(height: 1, color: context.cs.outlineVariant),
          AppSpacing.h10,
        ],
      ],
    );
  }
}

class OrderDetailItemRow extends StatelessWidget {
  final OrderItems item;
  final String? currency;
  final OrderData order;
  final bool showRatingControl;
  const OrderDetailItemRow({
    super.key,
    required this.item,
    this.currency,
    required this.order,
    this.showRatingControl = true,
  });

  @override
  Widget build(BuildContext context) {
    final imgSize = context.screenWidth * 0.15;
    final variant =
        VariantAttributesFormatter.format(item.variantAttributes) ?? "";
    final hasImage = item.imageUrl.hasValue;

    return Column(
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: .start,
          children: [
            hasImage
                ? AppNetworkImage(
                    url: item.imageUrl!,
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
                    '${item.quantity ?? 1} × ${item.productName ?? ''}',
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
              '$currency${item.discountedPrice ?? 0}',
              style: context.tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (item.prescriptionUrl != null && item.prescriptionUrl!.isNotEmpty)
          PrescriptionAttachmentRow(prescriptionUrl: item.prescriptionUrl!),
        Builder(
          builder: (context) {
            final isQuick = order.channel == AppConstants.quick;
            // Quick orders cancel as a whole from the listing screen —
            // per-item cancel only applies to ecommerce.
            final showCancel =
                !isQuick &&
                item.cancelableStatus == 1 &&
                item.activeStatus != OrderStatus.cancelled;
            final returnRequested = item.returnRequested;
            final returnEligible =
                item.activeStatus == OrderStatus.delivered &&
                item.returnStatus == 1 &&
                (returnRequested == null || returnRequested == 0);
            // Quick orders don't support returns — offer support chat instead.
            final showReturn = !isQuick && returnEligible;
            final showHelp = isQuick && returnEligible;
            final isRated =
                showRatingControl &&
                order.productRating == true &&
                order.activeStatus == OrderStatus.delivered &&
                (item.itemRating?.isNotEmpty ?? false);
            final showRate =
                showRatingControl &&
                order.productRating == true &&
                order.activeStatus == OrderStatus.delivered &&
                item.activeStatus != OrderStatus.cancelled &&
                item.activeStatus != OrderStatus.returned &&
                !showCancel &&
                !returnEligible &&
                !isRated;

            if (!showCancel &&
                !showReturn &&
                !showHelp &&
                !showRate &&
                !isRated) {
              return AppSpacing.shrink;
            }

            return Padding(
              padding: const EdgeInsetsDirectional.only(top: ThemeConstants.paddingS),
              child: Row(
                mainAxisAlignment: .end,
                children: [
                  if (showCancel)
                    AppButton(
                      label: context.translate(LanguageLabelKeys.cancel),
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
                        final reason = await _promptReason(
                          context,
                          context.translate(LanguageLabelKeys.cancel),
                          context.translate(
                            LanguageLabelKeys.cancelItemConfirm,
                          ),
                        );
                        if (reason == null || !context.mounted) return;
                        _runStatusUpdate(
                          context,
                          orderId: order.id?.toString() ?? '',
                          status: '${OrderStatus.cancelled}',
                          orderItemId: item.id?.toString(),
                          from: 'cancel',
                          reason: reason,
                        );
                      },
                    ),
                  if (showReturn)
                    AppButton(
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
                        final reason = await _promptReason(
                          context,
                          context.translate(LanguageLabelKeys.returnItem),
                          context.translate(
                            LanguageLabelKeys.returnItemConfirm,
                          ),
                        );
                        if (reason == null || !context.mounted) return;
                        _runStatusUpdate(
                          context,
                          orderId: order.id?.toString() ?? '',
                          status: '${OrderStatus.returned}',
                          orderItemId: item.id?.toString(),
                          from: 'return',
                          reason: reason,
                        );
                      },
                    ),
                  if (showHelp)
                    AppButton(
                      label: context.translate(LanguageLabelKeys.getHelp),
                      variant: AppButtonVariant.outline,
                      fullWidth: false,
                      height: 28,
                      fontSize: 13,
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 14,
                        vertical: ThemeConstants.paddingXS,
                      ),
                      prefixIcon: const AppSvgIcon(
                        AssetsConstants.faqIcon,
                        size: 14,
                      ),
                      onPressed: () async {
                        final conversationId =
                            await resolveAdminConversationId();
                        if (!context.mounted) return;
                        AppNavigator.pushNamed(
                          context,
                          RouteNames.chat,
                          arguments: ChatScreenArgs(
                            chatType: ChatType.adminChat,
                            recipientName: context.translate(
                              LanguageLabelKeys.supportTeam,
                            ),
                            recipientId: 0,
                            orderId: order.id?.toString() ?? '',
                            conversationId: conversationId,
                          ),
                        );
                      },
                    ),
                  if (showRate || isRated)
                    Expanded(
                      child: _ItemRatingControl(
                        item: item,
                        isRated: isRated,
                        onRatingChanged: (data) =>
                            context.read<OrderDetailCubit>().applyItemRating(
                              item.id,
                              ItemRating.fromJson(data),
                            ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 5-star row + label, shared by the unrated and already-rated states.
/// Tapping a star always submits that rate directly (add if unrated, update
/// if rated). Tapping the label opens the full bottom sheet for review text
/// and photos.
class _ItemRatingControl extends StatefulWidget {
  final OrderItems item;
  final bool isRated;
  final ValueChanged<Map<String, dynamic>> onRatingChanged;

  const _ItemRatingControl({
    required this.item,
    required this.isRated,
    required this.onRatingChanged,
  });

  @override
  State<_ItemRatingControl> createState() => _ItemRatingControlState();
}

class _ItemRatingControlState extends State<_ItemRatingControl> {
  bool _isSubmitting = false;

  ItemRating? get _own => widget.isRated ? widget.item.itemRating?.first : null;

  Future<void> _quickRate(int rate) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final cubit = RatingAddUpdateCubit();
    try {
      await cubit.submit(
        productId: widget.item.productId?.toString() ?? '',
        ratingId: _own?.id,
        rate: rate.toString(),
        review: _own?.review ?? '',
      );
      final state = cubit.state;
      if (state is RatingAddUpdateSuccess && state.data != null) {
        widget.onRatingChanged(state.data!);
      } else if (state is RatingAddUpdateError && mounted) {
        AppSnackBar.show(
          context: context,
          message: state.message,
          type: SnackBarType.error,
        );
      }
    } finally {
      cubit.close();
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openSheet() async {
    final own = _own;
    final data = await showRateProductSheet(
      context,
      productId: widget.item.productId?.toString() ?? '',
      productName: widget.item.productName ?? '',
      ratingId: own?.id,
      initialRate: int.tryParse(own?.rate ?? '') ?? 0,
      initialReview: own?.review ?? '',
      initialImages: (own?.images ?? [])
          .map(
            (img) =>
                ExistingRatingImage(id: img.id ?? '', url: img.imageUrl ?? ''),
          )
          .toList(),
    );
    if (data != null && context.mounted) {
      widget.onRatingChanged(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRate = int.tryParse(_own?.rate ?? '0') ?? 0;
    final hasReview = (_own?.review ?? '').isNotEmpty;
    final labelKey = !widget.isRated
        ? LanguageLabelKeys.rateThisProductNow
        : hasReview
        ? LanguageLabelKeys.viewReview
        : LanguageLabelKeys.writeAReview;

    return Row(
      crossAxisAlignment: .center,
      mainAxisSize: .min,
      children: [
        Expanded(
          child: RatingStarsRow(
            currentRate: currentRate,
            isSubmitting: _isSubmitting,
            onRate: _quickRate,
          ),
        ),
        InkWell(
          onTap: _openSheet,
          child: AppText(
            context.translate(labelKey),
            style: context.tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.isRated
                  ? context.cs.primary
                  : context.cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class OrderDetailPriceSummaryCard extends StatelessWidget {
  final OrderData order;
  final VoidCallback? onDownloadInvoice;
  final bool isDownloadingInvoice;
  const OrderDetailPriceSummaryCard({
    super.key,
    required this.order,
    this.onDownloadInvoice,
    this.isDownloadingInvoice = false,
  });

  @override
  Widget build(BuildContext context) {
    final currency = order.currency;
    final hasDiscount = order.discount != null && order.discount != 0;
    final paymentInfo = resolveOrderPaymentInfo(
      context: context,
      walletUsed: order.paidWallet,
      finalTotal: order.finalTotal,
      rawPaymentMethod: order.paymentMethod,
      isDelivered: order.activeStatus == OrderStatus.delivered,
    );
    final hasWallet = paymentInfo.hasWallet;
    final hasPromo =
        order.promoCode.hasValue && (order.promoDiscount ?? 0) != 0;
    final hasAdditional =
        order.additionalCharges != null && order.additionalCharges!.isNotEmpty;
    final hasSurge =
        order.surgeCharges != null && order.surgeCharges!.isNotEmpty;
    final saved = (order.savedAmount ?? 0) > 0
        ? order.savedAmount!
        : (order.discount ?? 0) + (order.promoDiscount ?? 0);
    final hasCashback =
        order.cashbackCredited == 1 && (order.cashbackAmount ?? 0) > 0;

    return OrderDetailBillSummaryCard(
      currency: currency ?? '',
      onDownloadInvoice: onDownloadInvoice,
      isDownloadingInvoice: isDownloadingInvoice,
      walletValue: (hasWallet && !paymentInfo.isFullyPaidByWallet)
          ? '${order.paidWallet}'
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
          value: '$currency${order.total ?? 0}',
          suffixLabel: (order.taxAmount != null && order.taxAmount != 0)
              ? context.translate(LanguageLabelKeys.inclTax)
              : null,
        ),
        OrderDetailPriceRow(
          label: context.translate(LanguageLabelKeys.deliveryCharge),
          value: '$currency${order.deliveryCharge ?? 0}',
        ),
        if (hasDiscount)
          OrderDetailPriceRow(
            label: context.translate(LanguageLabelKeys.discount),
            value: '- $currency${order.discount}',
            valueColor: context.cs.onSecondaryContainer,
          ),
        if (hasPromo)
          OrderDetailPriceRow(
            label:
                '${context.translate(LanguageLabelKeys.promo)} (${order.promoCode})',
            value: '- $currency${order.promoDiscount ?? 0}',
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
              label: surge.label ?? context.translate(LanguageLabelKeys.surge),
              value: '$currency${surge.charge ?? 0}',
              isRefundable: surge.isRefundable,
            ),
          ),
      ],
    );
  }
}

class OrderDetailDeliveryBoyCard extends StatelessWidget {
  final OrderData order;
  const OrderDetailDeliveryBoyCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return OrderDetailDeliveryBoyView(
      deliveryBoyName: order.deliveryBoyName ?? '',
      deliveryBoyMobile: order.deliveryBoyMobile,
      showChat: true,
      onChatTap: () async {
        final orderId = order.id?.toString() ?? '';
        final conversationId = await resolveOrderConversationId(orderId);
        if (!context.mounted) return;
        AppNavigator.pushNamed(
          context,
          RouteNames.chat,
          arguments: ChatScreenArgs(
            chatType: ChatType.deliveryBoyChat,
            recipientName: order.deliveryBoyName ?? '',
            recipientId: order.id ?? 0,
            orderId: orderId,
            conversationId: conversationId,
          ),
        );
      },
    );
  }
}
