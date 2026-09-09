import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/commons/widgets/zigzag_top_clipper.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/core/constants/theme_constants.dart';
import 'package:flutter/material.dart';

/// Torn-ticket "you saved X on this order" banner — shown when a promo/wallet
/// discount reduced the total. Caller passes the already-formatted amount
/// text (e.g. `'$currency${saved.toStringAsFixed(2)}'`).
class SavedAmountBanner extends StatelessWidget {
  final String amountText;

  const SavedAmountBanner({super.key, required this.amountText});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const ZigzagTopClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(0, ThemeConstants.paddingL, 0, 10),
        color: context.cs.primary.withValues(alpha: 0.1),
        child: Row(
          mainAxisAlignment: .center,
          spacing: 6,
          children: [
            AppText(AppConstants.celebrateSymbol, style: context.tt.bodyMedium),
            AppText(
              '${context.translate(LanguageLabelKeys.youSaved)} $amountText ${context.translate(LanguageLabelKeys.onThisOrder)}',
              style: context.tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
