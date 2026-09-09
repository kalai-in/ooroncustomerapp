import 'package:flutter/widgets.dart';

/// Wraps a [ScrollController] with a near-bottom listener for pagination.
class PaginationScrollController {
  final ScrollController controller = ScrollController();
  final VoidCallback onLoadMore;
  final double threshold;

  PaginationScrollController({required this.onLoadMore, this.threshold = 200}) {
    controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!controller.hasClients) return;
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - threshold) {
      onLoadMore();
    }
  }

  void dispose() => controller.dispose();
}
