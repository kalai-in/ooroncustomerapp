import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

enum SignInMode { email, phone }

class SignInModeToggle extends StatelessWidget {
  final SignInMode mode;
  final ValueChanged<SignInMode> onChanged;

  const SignInModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingXS),
      decoration: AppDecorations.box(
        color: context.cs.surfaceContainerHighest,
        borderRadius: AppRadius.r12,
      ),
      child: Row(
        children: [
          _Option(
            label: context.translate(LanguageLabelKeys.email),
            mode: SignInMode.email,
            current: mode,
            onChanged: onChanged,
          ),
          _Option(
            label: context.translate(LanguageLabelKeys.mobile),
            mode: SignInMode.phone,
            current: mode,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final SignInMode mode;
  final SignInMode current;
  final ValueChanged<SignInMode> onChanged;

  const _Option({
    required this.label,
    required this.mode,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: AppDecorations.box(
            color: selected ? context.cs.primary : Colors.transparent,
            borderRadius: AppRadius.r9,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: context.cs.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AppText(
            label,
            style: context.tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected
                  ? context.cs.onPrimary
                  : context.cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
