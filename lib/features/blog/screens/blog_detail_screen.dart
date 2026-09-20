import 'package:customer/commons/widgets/app_network_image.dart';
import 'package:customer/commons/widgets/app_svg_icon.dart';
import 'package:customer/commons/widgets/custom_app_bar.dart';
import 'package:customer/core/constants/app_constants.dart';
import 'package:customer/core/constants/assets_constants.dart';
import 'package:customer/core/localization/language_label_key.dart';
import 'package:customer/features/blog/models/blog_model.dart';
import 'package:customer/features/blog/widgets/blog_meta_info.dart';
import 'package:customer/utils/app_date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/core/theme/app_radius.dart';
import 'package:customer/core/theme/app_decorations.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/utils/extensions/localization_extensions.dart';
import 'package:customer/commons/widgets/app_scaffold.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

class BlogDetailScreen extends StatefulWidget {
  final Blog blog;
  const BlogDetailScreen({super.key, required this.blog});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blog = widget.blog;
    final categoryName = blog.category?.name;
    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.translate(LanguageLabelKeys.blogDetail),
        scrollController: _scrollController,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsetsDirectional.only(bottom: ThemeConstants.spaceXXXL),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            if ((blog.imageUrl ?? '').isNotEmpty) _buildHeroImage(context),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingL, 0),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  if ((categoryName != null && categoryName.isNotEmpty) ||
                      (blog.createdAt ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: ThemeConstants.paddingS),
                      child: Row(
                        children: [
                          if (categoryName != null && categoryName.isNotEmpty)
                            Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: ThemeConstants.paddingS,
                                vertical: ThemeConstants.paddingXS,
                              ),
                              decoration: AppDecorations.box(
                                color: context.cs.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: AppRadius.r4,
                              ),
                              child: AppText(
                                categoryName,
                                style: context.tt.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.cs.primary,
                                ),
                              ),
                            ),
                          if ((blog.createdAt ?? '').isNotEmpty) ...[
                            const Spacer(),
                            AppText(
                              AppDateFormatter.formatDateTime(blog.createdAt!),
                              style: context.tt.bodySmall?.copyWith(
                                color: context.cs.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  AppText(
                    blog.title ?? '',
                    style: context.tt.headlineSmall?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.cs.onSurface,
                      height: 1.3,
                    ),
                  ),
                  AppSpacing.h10,
                  BlogMetaInfo(
                    blog: blog,
                    iconSize: 14,
                    dateIconSize: 13,
                    groupSpacing: AppSpacing.w16,
                    showDate: false,
                    textStyle: context.tt.bodySmall?.copyWith(
                      fontSize: 13,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                  if ((blog.tagNames ?? []).isNotEmpty) ...[
                    AppSpacing.h12,
                    _buildTags(context),
                  ],
                  AppSpacing.h16,
                  Divider(color: context.cs.outlineVariant),
                  AppSpacing.h16,
                  if ((blog.description ?? '').isNotEmpty)
                    HtmlWidget(
                      blog.description!,
                      textStyle: context.tt.bodyMedium?.copyWith(
                        color: context.cs.onSurface,
                        height: 1.6,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    return AppNetworkImage(
      url: widget.blog.imageUrl!,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: Container(
        height: 220,
        color: context.cs.surfaceContainerHighest,
        alignment: Alignment.center,
        child: FractionallySizedBox(widthFactor: 0.3, heightFactor: 0.3, child: AppSvgIcon(AssetsConstants.placeholder, fit: BoxFit.contain)),
      ),
      errorWidget: Container(
        height: 220,
        color: context.cs.surfaceContainerHighest,
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: 0.3,
          heightFactor: 0.3,
          child: AppSvgIcon(AssetsConstants.placeholder, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: ThemeConstants.spaceS,
      runSpacing: 6,
      children: (widget.blog.tagNames ?? [])
          .map(
            (tag) => Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: ThemeConstants.paddingS,
                vertical: ThemeConstants.paddingXS,
              ),
              decoration: AppDecorations.box(
                color: context.cs.surfaceContainerHighest,
                borderRadius: AppRadius.r20,
                border: Border.all(color: context.cs.outlineVariant),
              ),
              child: AppText(
                '${AppConstants.hashSymbol}$tag',
                style: context.tt.bodySmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
