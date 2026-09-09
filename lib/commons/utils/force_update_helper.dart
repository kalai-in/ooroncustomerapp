import 'dart:io';
import 'package:customer/commons/models/app_settings_model.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/constants/theme_constants.dart';
import '../../commons/widgets/app_text.dart';
import '../../commons/widgets/app_button.dart';

enum UpdateStatus { none, optional, force }

class ForceUpdateHelper {
  static bool _isOutdated(String appVer, String serverVer) {
    try {
      final app = appVer.split('.').map(int.tryParse).toList();
      final srv = serverVer.split('.').map(int.tryParse).toList();
      for (int i = 0; i < 3; i++) {
        final a = i < app.length ? (app[i] ?? 0) : 0;
        final s = i < srv.length ? (srv[i] ?? 0) : 0;
        if (a < s) return true;
        if (a > s) return false;
      }
    } catch (_) {}
    return false;
  }

  static Future<UpdateStatus> getStatus(AppSettingsData data) async {
    try {
      final appVersion = (await PackageInfo.fromPlatform()).version;

      final isVersionSystemOn = Platform.isIOS
          ? data.iosIsVersionSystemOn
          : data.isVersionSystemOn;
      final serverVersion = Platform.isIOS
          ? data.iosCurrentVersion
          : data.currentVersion;
      final requiredForceUpdate = Platform.isIOS
          ? data.iosRequiredForceUpdate
          : data.requiredForceUpdate;

      if (isVersionSystemOn != '1') return UpdateStatus.none;
      if (!_isOutdated(appVersion, serverVersion ?? '')) {
        return UpdateStatus.none;
      }
      return requiredForceUpdate == '1'
          ? UpdateStatus.force
          : UpdateStatus.optional;
    } catch (_) {}
    return UpdateStatus.none;
  }

  static Future<void> launchStore(AppSettingsData data) async {
    final url = Platform.isIOS
        ? (data.iosAppUrl ?? '')
        : (data.androidAppUrl ?? '');
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

class ForceUpdateDialog extends StatelessWidget {
  final AppSettingsData data;
  final UpdateStatus status;
  final VoidCallback onContinue;

  const ForceUpdateDialog({
    super.key,
    required this.data,
    required this.status,
    required this.onContinue,
  });

  bool get _isForce => status == UpdateStatus.force;

  static Future<void> show({
    required BuildContext context,
    required AppSettingsData data,
    required UpdateStatus status,
    required VoidCallback onContinue,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ForceUpdateDialog(data: data, status: status, onContinue: onContinue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r16),
        titlePadding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingXL, ThemeConstants.paddingXL, ThemeConstants.paddingXL, 0),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingXL, ThemeConstants.paddingM, ThemeConstants.paddingXL, 0),
        actionsPadding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingS, ThemeConstants.paddingL, ThemeConstants.paddingL),
        title: Column(
          spacing: 12,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: AppDecorations.box(
                color: context.cs.primary.withValues(alpha: 0.1),
                shape: .circle,
              ),
              child: AppSvgIcon(
                AssetsConstants.forceUpdateIcon,
                color: context.cs.primary,
                size: 30,
              ),
            ),
            AppText(
              _isForce
                  ? context.translate(LanguageLabelKeys.updateRequired)
                  : context.translate(LanguageLabelKeys.updateAvailable),
              style: context.tt.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: .center,
            ),
          ],
        ),
        content: AppText(
          _isForce
              ? context.translate(LanguageLabelKeys.updateRequiredMessage)
              : context.translate(LanguageLabelKeys.updateAvailableMessage),
          style: context.tt.bodyMedium?.copyWith(
            color: context.cs.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: .center,
        ),
        actionsAlignment: .center,
        actions: [
          Column(
            crossAxisAlignment: .stretch,
            spacing: 8,
            children: [
              AppButton(
                label: context.translate(LanguageLabelKeys.updateNow),
                height: 44,
                onPressed: () => ForceUpdateHelper.launchStore(data),
              ),
              if (!_isForce) ...[
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: () {
                    AppNavigator.pop(context);
                    onContinue();
                  },
                  child: AppText(
                    context.translate(LanguageLabelKeys.later),
                    style: context.tt.bodyMedium?.copyWith(
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
