import 'dart:io';

import 'package:customer/commons/widgets/app_snack_bar.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/features/products/models/product_model.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/utils/show_app_bottom_sheet.dart';
import 'package:customer/commons/animations/slide_animation.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// Per-product prescription uploader shown only for medical products
/// (product_type == 5). A [ProductDataModel.requiresPrescription] item marks
/// the upload mandatory; otherwise it's optional. Accepts a single image
/// (jpg/png) or a PDF, keyed by the product's variant id at place-order time.
class CheckoutPrescriptionTile extends StatelessWidget {
  const CheckoutPrescriptionTile({
    super.key,
    required this.item,
    required this.file,
    required this.onPicked,
    required this.onRemove,
  });

  final ProductDataModel item;
  final File? file;
  final ValueChanged<File> onPicked;
  final VoidCallback onRemove;

  static final ImagePicker _picker = ImagePicker();

  // Keep uploads reasonable for a checkout attachment.
  static const int _maxBytes = 10 * 1024 * 1024;

  bool _isWithinSizeLimit(BuildContext context, String path) {
    if (File(path).lengthSync() <= _maxBytes) return true;
    AppSnackBar.show(
      context: context,
      message: context.translate(LanguageLabelKeys.fileTooLarge),
      type: SnackBarType.warning,
    );
    return false;
  }

  Future<void> _pick(BuildContext context) async {
    final source = await showAppBottomSheet<_PrescriptionSource>(
      context,
      padding: const EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingS),
      builder: (ctx) => SlideAnimationList(
        children: [
          ListTile(
            leading: AppSvgIcon(
              AssetsConstants.cameraIcon,
              color: ctx.cs.primary,
            ),
            title: AppText(context.translate(LanguageLabelKeys.takePhoto)),
            onTap: () => AppNavigator.pop(context, _PrescriptionSource.camera),
          ),
          ListTile(
            leading: AppSvgIcon(
              AssetsConstants.galleryIcon,
              color: ctx.cs.primary,
            ),
            title: AppText(
              context.translate(LanguageLabelKeys.chooseFromGallery),
            ),
            onTap: () => AppNavigator.pop(context, _PrescriptionSource.gallery),
          ),
          ListTile(
            leading: AppSvgIcon(
              AssetsConstants.fileIcon,
              color: ctx.cs.primary,
            ),
            title: AppText(context.translate(LanguageLabelKeys.choosePdf)),
            onTap: () => AppNavigator.pop(context, _PrescriptionSource.pdf),
          ),
        ],
      ),
    );

    if (source == null || !context.mounted) return;

    String? path;
    if (source == _PrescriptionSource.pdf) {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      path = result?.path;
    } else {
      final picked = await _picker.pickImage(
        source: source == _PrescriptionSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
      );
      path = picked?.path;
    }

    if (path == null || !context.mounted) return;
    if (!_isWithinSizeLimit(context, path)) return;
    onPicked(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final isPdf =
        file != null && p.extension(file!.path).toLowerCase() == '.pdf';
    final isRequired = item.requiresPrescription;

    return Container(
      margin: const EdgeInsetsDirectional.only(top: ThemeConstants.paddingM),
      padding: const EdgeInsetsDirectional.all(10),
      decoration: AppDecorations.box(
        color: context.cs.surfaceContainerLow,
        borderRadius: AppRadius.r10,
        border: Border.all(color: context.cs.outline.withValues(alpha: 0.15)),
      ),
      child: file == null
          ? _buildEmpty(context, isRequired)
          : _buildPicked(context, isPdf),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isRequired) {
    return InkWell(
      borderRadius: AppRadius.r8,
      onTap: () => _pick(context),
      child: Row(
        children: [
          AppSvgIcon(
            AssetsConstants.uploadIcon,
            size: 20,
            color: context.cs.primary,
          ),
          AppSpacing.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AppText(
                        context.translate(LanguageLabelKeys.uploadPrescription),
                        style: context.tt.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: .ellipsis,
                      ),
                    ),
                    AppSpacing.w6,
                    _StatusChip(isRequired: isRequired),
                  ],
                ),
                AppSpacing.h2,
                AppText(
                  context.translate(LanguageLabelKeys.imageOrPdfSupported),
                  style: context.tt.labelSmall?.copyWith(
                    color: context.cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicked(BuildContext context, bool isPdf) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: AppRadius.r8,
          child: isPdf
              ? Container(
                  width: 40,
                  height: 40,
                  color: context.cs.error.withValues(alpha: 0.1),
                  child: AppSvgIcon(
                    AssetsConstants.fileIcon,
                    size: 22,
                    color: context.cs.error,
                  ),
                )
              : Image.file(file!, width: 40, height: 40, fit: BoxFit.cover),
        ),
        AppSpacing.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              AppText(
                context.translate(LanguageLabelKeys.prescription),
                style: context.tt.labelSmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              AppText(
                p.basename(file!.path),
                style: context.tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.cs.onSurface,
                ),
                maxLines: 1,
                overflow: .ellipsis,
              ),
            ],
          ),
        ),
        AppSpacing.w8,
        GestureDetector(
          onTap: () => _pick(context),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 6,
              vertical: ThemeConstants.paddingXS,
            ),
            child: AppText(
              context.translate(LanguageLabelKeys.change),
              style: context.tt.bodySmall?.copyWith(
                color: context.cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        InkWell(
          borderRadius: AppRadius.r8,
          onTap: onRemove,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingXS),
            child: AppSvgIcon(
              AssetsConstants.closeIcon,
              size: 18,
              color: context.cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

enum _PrescriptionSource { camera, gallery, pdf }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isRequired});

  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final color = isRequired ? context.cs.error : context.cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: AppDecorations.box(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.r6,
      ),
      child: AppText(
        context.translate(
          isRequired
              ? LanguageLabelKeys.prescriptionRequired
              : LanguageLabelKeys.prescriptionOptional,
        ),
        style: context.tt.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}
