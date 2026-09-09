import 'package:flutter/material.dart';
import 'loading_widget.dart';
import 'package:customer/core/constants/theme_constants.dart';

/// Shows a loading spinner while paginating, nothing otherwise.
class PaginatedListFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;

  const PaginatedListFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingL),
        child: Center(child: LoadingWidget(size: 24)),
      );
    }
    return const SizedBox.shrink();
  }
}
