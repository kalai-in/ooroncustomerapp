import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/commons/cubit/connectivity_cubit.dart';
import 'package:customer/commons/widgets/app_no_internet_widget.dart';
import 'package:customer/commons/widgets/empty_state_widget.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/commons/cubit/country_settings_cubit.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../../commons/cubit/settings_cubit.dart';
import '../../../commons/widgets/custom_app_bar.dart';
import '../../../commons/widgets/loading_widget.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/core/constants/theme_constants.dart';

enum PoliciesType {
  privacyPolicy,
  termsConditions,
  aboutUs,
  contactUs,
  returnPolicy,
  shippingPolicy,
  returnsAndExchangesPolicy,
}

/// Policy types served by the dedicated settings/policies API instead of
/// the general settings endpoint.
const _dedicatedPolicyTypes = {
  PoliciesType.privacyPolicy,
  PoliciesType.termsConditions,
  PoliciesType.returnPolicy,
  PoliciesType.shippingPolicy,
  PoliciesType.returnsAndExchangesPolicy,
};

class PoliciesScreen extends StatelessWidget {
  final PoliciesType type;

  const PoliciesScreen({super.key, required this.type});

  String _title(BuildContext context) {
    switch (type) {
      case PoliciesType.privacyPolicy:
        return context.translate(LanguageLabelKeys.privacyPolicy);
      case PoliciesType.termsConditions:
        return context.translate(LanguageLabelKeys.termsAndConditions);
      case PoliciesType.aboutUs:
        return context.translate(LanguageLabelKeys.aboutUs);
      case PoliciesType.contactUs:
        return context.translate(LanguageLabelKeys.contactUs);
      case PoliciesType.returnPolicy:
        return context.translate(LanguageLabelKeys.returnPolicy);
      case PoliciesType.shippingPolicy:
        return context.translate(LanguageLabelKeys.shippingPolicy);
      case PoliciesType.returnsAndExchangesPolicy:
        return context.translate(LanguageLabelKeys.cancellationPolicy);
    }
  }

  String? _contentFromSettings(SettingsLoaded state) {
    switch (type) {
      case PoliciesType.aboutUs:
        return state.settings.data?.aboutUs;
      case PoliciesType.contactUs:
        return state.settings.data?.contactUs;
      default:
        return null;
    }
  }

  String? _contentFromPolicies(CountrySettingsLoaded state) {
    switch (type) {
      case PoliciesType.privacyPolicy:
        return state.settings.data?.privacyPolicy;
      case PoliciesType.termsConditions:
        return state.settings.data?.termsConditions;
      case PoliciesType.returnPolicy:
        return state.settings.data?.returnPolicy;
      case PoliciesType.shippingPolicy:
        return state.settings.data?.shippingPolicy;
      case PoliciesType.returnsAndExchangesPolicy:
        return state.settings.data?.cancellationPolicy;
      default:
        return null;
    }
  }

  Widget getPolicyEmptyContent(BuildContext context, PoliciesType type) {
    return EmptyStateWidget(
      imagePath: AssetsConstants.noSearchFound,
      title:
          '${_title(context)} ${context.translate(LanguageLabelKeys.contentNotAvailable)}',
      subtitle: context.translate(
        LanguageLabelKeys.contentCurrentlyUnavailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dedicatedPolicyTypes.contains(type)) {
      final cubit = context.read<CountrySettingsCubit>();
      if (cubit.state is CountrySettingsInitial) {
        cubit.loadCountrySettings();
      }
      return _PoliciesDedicatedView(type: type, screen: this);
    }

    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          context.read<SettingsCubit>().loadSettings();
        }
      },
      builder: (context, connectivityState) {
        return AppScaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(title: _title(context)),
          // Offline replaces the body only, so the app bar's back button
          // keeps working.
          body: connectivityState is ConnectivityDisconnected
              ? const AppNoInternetView()
              : BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    if (state is SettingsLoading) {
                      return const LoadingWidget();
                    }

                    if (state is SettingsError) {
                      return EmptyStateWidget(
                        imagePath: AssetsConstants.noSearchFound,
                        title: state.message,
                        subtitle: context.translate(
                          LanguageLabelKeys.pullToRefresh,
                        ),
                        onRetry: () =>
                            context.read<SettingsCubit>().loadSettings(),
                      );
                    }

                    if (state is SettingsInitial) {
                      context.read<SettingsCubit>().loadSettings();
                      return const LoadingWidget();
                    }

                    if (state is SettingsLoaded) {
                      final html = _contentFromSettings(state);
                      if (html == null || html.isEmpty) {
                        return getPolicyEmptyContent(context, type);
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: ThemeConstants.paddingM,
                          vertical: ThemeConstants.paddingS,
                        ),
                        child: HtmlWidget(html),
                      );
                    }

                    return AppSpacing.shrink;
                  },
                ),
        );
      },
    );
  }
}

class _PoliciesDedicatedView extends StatelessWidget {
  final PoliciesType type;
  final PoliciesScreen screen;

  const _PoliciesDedicatedView({required this.type, required this.screen});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          context.read<CountrySettingsCubit>().loadCountrySettings(force: true);
        }
      },
      builder: (context, connectivityState) {
        return AppScaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(title: screen._title(context)),
          // Offline replaces the body only, so the app bar's back button
          // keeps working.
          body: connectivityState is ConnectivityDisconnected
              ? const AppNoInternetView()
              : BlocBuilder<CountrySettingsCubit, CountrySettingsState>(
                  builder: (context, state) {
                    if (state is CountrySettingsLoading ||
                        state is CountrySettingsInitial) {
                      return const LoadingWidget();
                    }

                    if (state is CountrySettingsError) {
                      return EmptyStateWidget(
                        imagePath: AssetsConstants.noSearchFound,
                        title: state.message,
                        subtitle: context.translate(
                          LanguageLabelKeys.pullToRefresh,
                        ),
                        onRetry: () => context
                            .read<CountrySettingsCubit>()
                            .loadCountrySettings(force: true),
                      );
                    }

                    if (state is CountrySettingsLoaded) {
                      final html = screen._contentFromPolicies(state);
                      if (html == null || html.isEmpty) {
                        return screen.getPolicyEmptyContent(context, type);
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: ThemeConstants.paddingM,
                          vertical: ThemeConstants.paddingS,
                        ),
                        child: HtmlWidget(html),
                      );
                    }

                    return AppSpacing.shrink;
                  },
                ),
        );
      },
    );
  }
}
