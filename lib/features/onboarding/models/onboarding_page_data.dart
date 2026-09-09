import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';

class OnboardingPageData {
  final String imagePath;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final List<Color> bgDecor;

  const OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.bgDecor,
  });
}

List<OnboardingPageData> buildOnboardingPages(BuildContext context) {
  final cs = context.cs;
  return [
    OnboardingPageData(
      imagePath: AssetsConstants.onBoarding1,
      title: context.translate(LanguageLabelKeys.onboardingTitle1),
      subtitle: context.translate(LanguageLabelKeys.onboardingSubtitle1),
      gradient: [cs.primary, cs.primaryContainer],
      bgDecor: [cs.primaryContainer, cs.primary.withValues(alpha: 0.6)],
    ),
    OnboardingPageData(
      imagePath: AssetsConstants.onBoarding2,
      title: context.translate(LanguageLabelKeys.onboardingTitle2),
      subtitle: context.translate(LanguageLabelKeys.onboardingSubtitle2),
      gradient: [cs.secondary, cs.secondaryContainer],
      bgDecor: [cs.secondaryContainer, cs.secondary.withValues(alpha: 0.6)],
    ),
    OnboardingPageData(
      imagePath: AssetsConstants.onBoarding3,
      title: context.translate(LanguageLabelKeys.onboardingTitle3),
      subtitle: context.translate(LanguageLabelKeys.onboardingSubtitle3),
      gradient: [cs.tertiary, cs.tertiaryContainer],
      bgDecor: [cs.tertiaryContainer, cs.tertiary.withValues(alpha: 0.6)],
    ),
  ];
}
