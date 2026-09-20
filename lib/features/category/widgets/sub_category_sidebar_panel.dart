import 'package:customer/commons/cubit/base_pagination_cubit.dart';
import 'package:customer/commons/utils/pagination_scroll_controller.dart';
import 'package:customer/features/category/cubit/sub_category_cubit.dart';
import 'package:customer/features/category/models/category_model.dart';
import 'package:customer/features/category/widgets/sub_category_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:customer/core/theme/app_spacing.dart';
import 'package:customer/utils/extensions/context_extensions.dart';
import 'package:customer/commons/widgets/app_text.dart';
import 'package:customer/core/constants/theme_constants.dart';

class SubCategorySidebarPanel extends StatelessWidget {
  final PaginationScrollController pager;
  final String? selectedCategoryId;
  // Id of the category currently previewed as a right-side grid (only ever
  // the very first auto-selected category). That one item legitimately
  // shows its own content on the right, so it's the one has_child exception
  // allowed to render as selected.
  final String? autoChildCategoryId;
  final ValueChanged<Category> onSelectCategory;
  final ValueChanged<Category> onAutoSelectCategory;

  const SubCategorySidebarPanel({
    super.key,
    required this.pager,
    required this.selectedCategoryId,
    required this.onSelectCategory,
    required this.onAutoSelectCategory,
    this.autoChildCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarBg = context.cs.surfaceContainerLow;

    return SizedBox(
      width: 84,
      child: BlocConsumer<SubCategoryCubit, PaginationState<Category>>(
        listener: (context, state) {
          if (state is PaginationLoaded<Category> &&
              state.data.isNotEmpty &&
              selectedCategoryId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onAutoSelectCategory(state.data.first);
            });
          }
        },
        builder: (context, state) {
          if (state is PaginationLoading<Category>) {
            return SidebarLoader(bg: sidebarBg);
          }
          if (state is PaginationError<Category>) {
            return Container(
              padding: EdgeInsetsDirectional.all(ThemeConstants.paddingS),
              color: sidebarBg,
              alignment: AlignmentDirectional.center,
              child: AppText(
                state.message,
                style: context.tt.labelSmall?.copyWith(fontSize: 10),
                textAlign: .center,
              ),
            );
          }
          if (state is PaginationLoaded<Category>) {
            return Container(
              color: sidebarBg,
              child: pager.attach(
                ListView.builder(
                  controller: pager.controller,
                  itemCount: state.data.length,
                  itemBuilder: (context, index) {
                    final cat = state.data[index];
                    return SidebarItem(
                      category: cat,
                      // A has_child item only reads as "selected" if it's the
                      // one previewed as a grid on the right; otherwise tapping
                      // it drills into its own page instead of showing content
                      // here, so it shouldn't look selected.
                      isSelected:
                          selectedCategoryId == cat.id &&
                          (cat.hasChild != true || cat.id == autoChildCategoryId),
                      onTap: () => onSelectCategory(cat),
                    );
                  },
                ),
              ),
            );
          }
          return AppSpacing.shrink;
        },
      ),
    );
  }
}
