import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/commons/widgets/menu_card.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/core/local_storage/auth_hive_box.dart';
import 'package:customer/core/routes/route_names.dart';
import 'package:customer/features/profile/widgets/profile_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/features/auth/cubits/auth_cubit.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/core/constants/theme_constants.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.translate(LanguageLabelKeys.settings),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingL, 28),
        children: [
          MenuCard(
            title: context.translate(LanguageLabelKeys.general),
            items: [
              MenuItemData(
                iconPath: AssetsConstants.notificationIcon,
                label: context.translate(
                  LanguageLabelKeys.notificationSettings,
                ),
                onTap: () =>
                    AppNavigator.pushNamed(context, RouteNames.notifications),
              ),
              if (AuthHiveBox.instance.isLoggedIn) ...[
                if (AuthHiveBox.instance.userData?.type == AuthType.email.name)
                  MenuItemData(
                    iconPath: AssetsConstants.passwordIcon,
                    label: context.translate(LanguageLabelKeys.changePassword),
                    onTap: () => showChangePasswordSheet(context),
                  ),
                MenuItemData(
                  iconPath: AssetsConstants.deleteIcon,
                  label: context.translate(LanguageLabelKeys.deleteAccount),
                  onTap: () => showDeleteAccountDialog(context),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
