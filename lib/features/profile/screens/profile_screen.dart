import 'dart:io';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/commons/widgets/menu_card.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/constants/navigation_service.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/core/local_storage/auth_hive_box.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:customer/features/chat/models/chat_message.dart';
import 'package:customer/features/chat/services/chat_conversation_resolver.dart';
import 'package:customer/core/localization/cubit/language_cubit.dart';
import 'package:customer/core/localization/models/language_model.dart';
import 'package:customer/core/local_storage/settings_hive_box.dart';
import 'package:customer/core/theme/cubit/theme_cubit.dart';
import 'package:customer/features/profile/widgets/language_sheet.dart';
import 'package:customer/features/profile/widgets/profile_dialogs.dart';
import 'package:customer/commons/cubit/settings_cubit.dart';
import 'package:customer/commons/cubit/country_settings_cubit.dart';
import 'package:customer/features/profile/screens/policies_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routes/route_names.dart';
import '../../../utils/extensions/context_extensions.dart';
import '../../../utils/extensions/localization_extensions.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import '../../../commons/widgets/app_text.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/constants/theme_constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No connectivity gate here: this screen only ever renders inside
    // MainScreen's IndexedStack, and MainScreen layers the offline view over
    // the whole shell.
    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.translate(LanguageLabelKeys.profile),
        showBackButton: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _ProfileHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingXS, ThemeConstants.paddingL, 0),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  if (AuthHiveBox.instance.isLoggedIn)
                    Builder(
                      builder: (context) {
                        final countrySettingsState = context
                            .watch<CountrySettingsCubit>()
                            .state;
                        final settingsData =
                            countrySettingsState is CountrySettingsLoaded
                            ? countrySettingsState.settings.data
                            : null;
                        final referralFirstOrder =
                            settingsData?.referralCreditFirstOrder ?? 0;
                        final referralReferred =
                            settingsData?.referralCreditReferred ?? 0;
                        final showReferAndEarn =
                            referralFirstOrder != 0 || referralReferred != 0;

                        return MenuCard(
                      title: context.translate(LanguageLabelKeys.personalData),
                      items: [
                        MenuItemData(
                          iconPath: AssetsConstants.orderIcon,
                          label: context.translate(LanguageLabelKeys.myOrders),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.myOrders,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.addressIcon,
                          label: context.translate(
                            LanguageLabelKeys.myAddresses,
                          ),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.addresses,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.transactionIcon,
                          label: context.translate(
                            LanguageLabelKeys.transactionHistory,
                          ),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.transactions,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.walletIcon,
                          label: context.translate(
                            LanguageLabelKeys.walletHistory,
                          ),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.walletTransactions,
                          ),
                        ),
                        if (showReferAndEarn)
                          MenuItemData(
                            iconPath: AssetsConstants.giftIcon,
                            label: context.translate(
                              LanguageLabelKeys.referAndEarn,
                            ),
                            onTap: () => AppNavigator.pushNamed(
                              context,
                              RouteNames.referEarn,
                            ),
                          ),
                      ],
                        );
                      },
                    ),
                  if (AuthHiveBox.instance.isLoggedIn) AppSpacing.h12,
                  BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, themeState) {
                      /* final themeLabel = switch (themeState.themeMode) {
                        ThemeMode.light => context.translate(
                          LanguageLabelKeys.light,
                        ),
                        ThemeMode.dark => context.translate(
                          LanguageLabelKeys.dark,
                        ),
                        _ => context.translate(LanguageLabelKeys.systemDefault),
                      }; */
                      return BlocBuilder<LanguageCubit, LanguageState>(
                        builder: (context, langState) {
                          String langName;
                          if (langState is LanguageLoaded) {
                            final lang = langState.languages
                                .where(
                                  (LanguageJsonData l) =>
                                      l.id == langState.selectedId,
                                )
                                .firstOrNull;
                            final name = lang?.name ?? '';
                            final code =
                                (lang?.code ??
                                        SettingsHiveBox.instance.languageCode)
                                    .toUpperCase();
                            langName = name.isNotEmpty ? '$name ($code)' : code;
                          } else {
                            langName = SettingsHiveBox.instance.languageCode
                                .toUpperCase();
                          }
                          return MenuCard(
                            title: context.translate(
                              LanguageLabelKeys.preferences,
                            ),
                            items: [
                              MenuItemData(
                                iconPath: AssetsConstants.languageIcon,
                                label: context.translate(
                                  LanguageLabelKeys.changeLanguage,
                                ),
                                trailing: langName,
                                onTap: () => showLanguageSheet(context),
                              ),/* 
                              MenuItemData(
                                iconPath: AssetsConstants.themeIcon,
                                label: context.translate(
                                  LanguageLabelKeys.changeTheme,
                                ),
                                trailing: themeLabel,
                                onTap: () => showAppearanceSheet(context),
                              ), */
                            ],
                          );
                        },
                      );
                    },
                  ),
                  AppSpacing.h12,
                  MenuCard(
                    title: context.translate(LanguageLabelKeys.quickAccess),
                    items: [
                      MenuItemData(
                        iconPath: AssetsConstants.notificationIcon,
                        label: context.translate(
                          LanguageLabelKeys.notifications,
                        ),
                        onTap: () => AppNavigator.pushNamed(
                          context,
                          RouteNames.notificationList,
                        ),
                      ),
                      MenuItemData(
                        iconPath: AssetsConstants.shareIcon,
                        label: context.translate(LanguageLabelKeys.shareApp),
                        onTap: () {
                          final settings = context.read<SettingsCubit>().state;
                          if (settings is SettingsLoaded) {
                            final url = Platform.isIOS
                                ? (settings.settings.data?.iosAppUrl ?? '')
                                : (settings.settings.data?.androidAppUrl ?? '');
                            if (url.isNotEmpty) {
                              SharePlus.instance.share(ShareParams(text: url));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  AppSpacing.h12,
                  MenuCard(
                    title: context.translate(LanguageLabelKeys.helpAndSupport),
                    items: [
                      if (AuthHiveBox.instance.isLoggedIn)
                        MenuItemData(
                          iconPath: AssetsConstants.supportChatIcon,
                          label: context.translate(
                            LanguageLabelKeys.chatWithSupport,
                          ),
                          onTap: () async {
                            final conversationId =
                                await resolveAdminConversationId();
                            if (!context.mounted) return;
                            AppNavigator.pushNamed(
                              context,
                              RouteNames.chat,
                              arguments: ChatScreenArgs(
                                chatType: ChatType.adminChat,
                                recipientName: context.translate(
                                  LanguageLabelKeys.chatWithSupport,
                                ),
                                recipientId: AuthHiveBox.instance.userId,
                                conversationId: conversationId,
                              ),
                            );
                          },
                        ),
                      MenuItemData(
                        iconPath: AssetsConstants.blogIcon,
                        label: context.translate(LanguageLabelKeys.blog),
                        onTap: () =>
                            AppNavigator.pushNamed(context, RouteNames.blog),
                      ),
                      MenuItemData(
                        iconPath: AssetsConstants.rateIcon,
                        label: context.translate(LanguageLabelKeys.rateUs),
                        onTap: () {
                          final settings = context.read<SettingsCubit>().state;
                          if (settings is SettingsLoaded) {
                            final url = Platform.isIOS
                                ? (settings.settings.data?.iosAppUrl ?? '')
                                : (settings.settings.data?.androidAppUrl ?? '');
                            if (url.isNotEmpty) {
                              launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  AppSpacing.h12,
                  MenuCard(
                    title: context.translate(LanguageLabelKeys.helpAndPolicies),
                    items: [
                      MenuItemData(
                        iconPath: AssetsConstants.faqIcon,
                        label: context.translate(LanguageLabelKeys.faq),
                        onTap: () =>
                            AppNavigator.pushNamed(context, RouteNames.faq),
                      ),
                    ],
                    footer: _ExpandableMenuSection(
                      iconPath: AssetsConstants.helpPolicyIcon,
                      label: context.translate(
                        LanguageLabelKeys.helpAndPolicies,
                      ),
                      children: [
                        MenuItemData(
                          iconPath: AssetsConstants.helpPolicyIcon,
                          label: context.translate(LanguageLabelKeys.aboutUs),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.policies,
                            arguments: PoliciesType.aboutUs,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.helpPolicyIcon,
                          label: context.translate(LanguageLabelKeys.contactUs),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.policies,
                            arguments: PoliciesType.contactUs,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.helpPolicyIcon,
                          label: context.translate(
                            LanguageLabelKeys.privacyPolicy,
                          ),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.policies,
                            arguments: PoliciesType.privacyPolicy,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.helpPolicyIcon,
                          label: context.translate(
                            LanguageLabelKeys.termsAndConditions,
                          ),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.policies,
                            arguments: PoliciesType.termsConditions,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.helpPolicyIcon,
                          label: context.translate(
                            LanguageLabelKeys.returnPolicy,
                          ),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.policies,
                            arguments: PoliciesType.returnPolicy,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.helpPolicyIcon,
                          label: context.translate(
                            LanguageLabelKeys.shippingPolicy,
                          ),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.policies,
                            arguments: PoliciesType.shippingPolicy,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.helpPolicyIcon,
                          label: context.translate(
                            LanguageLabelKeys.cancellationPolicy,
                          ),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.policies,
                            arguments: PoliciesType.returnsAndExchangesPolicy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (AuthHiveBox.instance.isLoggedIn) ...[
                    AppSpacing.h12,
                    MenuCard(
                      title: context.translate(LanguageLabelKeys.account),
                      items: [
                        MenuItemData(
                          iconPath: AssetsConstants.settingsIcon,
                          label: context.translate(LanguageLabelKeys.settings),
                          onTap: () => AppNavigator.pushNamed(
                            context,
                            RouteNames.accountSettings,
                          ),
                        ),
                        MenuItemData(
                          iconPath: AssetsConstants.logoutIcon,
                          label: context.translate(LanguageLabelKeys.logout),
                          onTap: () => showLogoutDialog(context),
                        ),
                      ],
                    ),
                  ],
                  AppSpacing.h28,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: AuthHiveBox.instance.listenable,
      builder: (context, box, child) {
        final name = AuthHiveBox.instance.userName;
        final email = AuthHiveBox.instance.userEmail;
        final imageUrl = AuthHiveBox.instance.userProfile;
        final mobile = AuthHiveBox.instance.userMobile;
        final countryCode = AuthHiveBox.instance.userCountryCode;
        final isLoggedIn = AuthHiveBox.instance.isLoggedIn;

        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingS),
          child: Container(
            decoration: AppDecorations.shadowedCard(
              color: context.cs.surface,
              shadowColor: context.theme.shadowColor.withValues(alpha: 0.06),
              borderRadius: AppRadius.r16,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: ThemeConstants.paddingL,
              vertical: ThemeConstants.paddingL,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: AppDecorations.box(
                    shape: .circle,
                    color: context.cs.surfaceContainerHigh,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isLoggedIn && imageUrl.isNotEmpty
                      ? AppNetworkImage(
                          url: imageUrl,
                          placeholder: AppSvgIcon(
                            AssetsConstants.userIcon,
                            size: 34,
                            color: context.cs.onSurfaceVariant,
                            fit: BoxFit.scaleDown,
                          ),
                          errorWidget: AppSvgIcon(
                            AssetsConstants.userIcon,
                            size: 34,
                            color: context.cs.onSurfaceVariant, fit: BoxFit.scaleDown,
                          ),
                        )
                      : AppSvgIcon(
                          AssetsConstants.userIcon,
                          size: 24,
                          color: context.cs.onSurfaceVariant,
                          fit: BoxFit.scaleDown,
                        ),
                ),
                AppSpacing.w14,
                Expanded(
                  child: isLoggedIn
                      ? Column(
                          crossAxisAlignment: .start,
                          spacing: 3,
                          children: [
                            AppText(
                              name,
                              style: context.tt.titleLarge?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: context.cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                            AppText(
                              email.isNotEmpty ? email : "$countryCode $mobile",
                              style: context.tt.bodySmall?.copyWith(
                                color: context.cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: .start,
                          spacing: 3,
                          children: [
                            AppText(
                              context.translate(LanguageLabelKeys.guest),
                              style: context.tt.titleLarge?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: context.cs.onSurface,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => AppNavigator.pushNamed(
                                context,
                                RouteNames.login,
                              ),
                              child: AppText(
                                '${context.translate(LanguageLabelKeys.login)} / ${context.translate(LanguageLabelKeys.register)}',
                                style: context.tt.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: context.cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                if (isLoggedIn) ...[
                  AppSpacing.w8,
                  GestureDetector(
                    onTap: () =>
                        AppNavigator.pushNamed(context, RouteNames.editProfile),
                    child: Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: ThemeConstants.paddingM,
                        vertical: 6,
                      ),
                      decoration: AppDecorations.box(
                        color: context.cs.surfaceContainerHigh,
                        borderRadius: AppRadius.r8,
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        spacing: 4,
                        children: [
                          AppSvgIcon(
                            AssetsConstants.editIcon,
                            size: 16,
                            color: context.cs.onSurface,
                          ),
                          AppText(
                            context.translate(LanguageLabelKeys.edit),
                            style: context.tt.labelSmall?.copyWith(
                              color: context.cs.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Expandable Menu Section ────────────────────────────────────────────────────

class _ExpandableMenuSection extends StatefulWidget {
  final String iconPath;
  final String label;
  final List<MenuItemData> children;

  const _ExpandableMenuSection({
    required this.iconPath,
    required this.label,
    required this.children,
  });

  @override
  State<_ExpandableMenuSection> createState() => _ExpandableMenuSectionState();
}

class _ExpandableMenuSectionState extends State<_ExpandableMenuSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: ThemeConstants.paddingL,
              vertical: 13,
            ),
            child: Row(
              spacing: 14,
              children: [
                AppSvgIcon(
                  widget.iconPath,
                  size: 22,
                  color: context.cs.onSurfaceVariant,
                ),
                Expanded(
                  child: AppText(
                    widget.label,
                    style: context.tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.cs.onSurface,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: AppSvgIcon(
                    AssetsConstants.arrowDownIcon,
                    color: context.cs.onSurfaceVariant,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: List.generate(widget.children.length, (i) {
              final child = widget.children[i];
              return Column(
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: context.cs.outlineVariant,
                  ),
                  InkWell(
                    onTap: child.onTap,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 52,
                        end: ThemeConstants.paddingL,
                        top: ThemeConstants.paddingM,
                        bottom: ThemeConstants.paddingM,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              child.label,
                              style: context.tt.bodySmall?.copyWith(
                                color: context.cs.onSurface,
                              ),
                            ),
                          ),
                          Transform.flip(
                            flipX:
                                Directionality.of(context) ==
                                TextDirection.rtl,
                            child: AppSvgIcon(
                              AssetsConstants.arrowRightIcon,
                              color: context.cs.onSurfaceVariant,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}
