import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/size_extensions.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:flutter/material.dart';

/// Default content padding for a sheet body — bottom safe-area is added on top
/// of the bottom value by [showAppBottomSheet].
const EdgeInsetsDirectional _defaultSheetPadding =
    EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingM, ThemeConstants.paddingL, ThemeConstants.paddingL);

/// Standard bottom sheet launcher.
/// Owns the whole sheet chrome — background colour, top radius, content padding
/// (including bottom safe-area), drag handle and title — so callers only build
/// their own content.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  // Rendered at the end of the title row, e.g. a loading indicator.
  Widget? titleTrailing,
  bool showDragHandle = true,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  // Pass null when the sheet body handles its own padding (e.g. keyboard insets).
  EdgeInsetsDirectional? padding = _defaultSheetPadding,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor ?? context.cs.surface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.top20),
    isDismissible: isDismissible,
    useSafeArea: true,
    enableDrag: enableDrag,
    builder: (sheetContext) {
      Widget content = _SheetBody(
        title: title,
        titleTrailing: titleTrailing,
        showDragHandle: showDragHandle,
        child: builder(sheetContext),
      );

      if (padding != null) {
        // Keyboard covers the sheet's own fields otherwise — viewInsets.bottom
        // is the keyboard height, absent from bottomSafePadding (gesture-area
        // safe zone only). AnimatedPadding tracks it smoothly as the keyboard
        // opens/closes instead of jumping.
        content = AnimatedPadding(
          duration: const Duration(milliseconds: 100),
          padding: padding.add(
            EdgeInsetsDirectional.only(
              bottom:
                  sheetContext.bottomSafePadding +
                  MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
          ),
          child: content,
        );
      }
      return content;
    },
  );
}

/// Drag handle + title header stacked above the caller's content.
class _SheetBody extends StatelessWidget {
  final String? title;
  final Widget? titleTrailing;
  final bool showDragHandle;
  final Widget child;

  const _SheetBody({
    required this.title,
    required this.titleTrailing,
    required this.showDragHandle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDragHandle && title == null) return child;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        if (showDragHandle) ...[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: AppDecorations.dragHandle(color: context.cs.outline),
            ),
          ),
        ],
        if (title != null) ...[
          if (showDragHandle) AppSpacing.h16,
          Row(
            children: [
              Expanded(
                child: AppText(
                  title!,
                  style: context.tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
              ),
              ?titleTrailing,
            ],
          ),
        ],
        AppSpacing.h12,
        Flexible(child: child),
      ],
    );
  }
}
