import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// The scroll container of every data screen: pull-to-refresh, bottom-inset
/// padding, always-scrollable physics (so refresh works on short or empty
/// content) and optional "load the next page" when the user nears the end.
class RefreshList extends StatefulWidget {
  /// Content of the list, already laid out as widgets.
  final List<Widget> children;

  /// Reloads the screen; must complete when the NETWORK call settles.
  final Future<void> Function() onRefresh;

  /// Fetches the next page when the user scrolls near the end; null disables paging.
  final VoidCallback? onLoadMore;

  /// True while the next page is loading — a spinner row is appended.
  final bool isLoadingMore;

  /// Space around the content before the bottom inset is added.
  final EdgeInsets padding;

  /// Space between consecutive [children].
  final double gap;

  /// Shown (still scrollable, so pull-to-refresh works) when [children] is empty.
  final Widget? placeholder;

  /// Builds the list.
  const RefreshList({
    super.key,
    required this.children,
    required this.onRefresh,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.padding = EdgeInsets.zero,
    this.gap = 12,
    this.placeholder,
  });

  @override
  State<RefreshList> createState() => _RefreshListState();
}

/// Owns the scroll controller that detects "near the end".
class _RefreshListState extends State<RefreshList> {
  /// Controller observed for the load-more trigger.
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Asks for the next page once less than 300 logical pixels remain.
  void _onScroll() {
    if (widget.onLoadMore == null || widget.isLoadingMore) return;
    if (_controller.position.extentAfter < 300) widget.onLoadMore!();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: theme.primary,
      backgroundColor: theme.cardColor,
      onRefresh: widget.onRefresh,
      child: widget.children.isEmpty && widget.placeholder != null
          ? LayoutBuilder(
              builder: (context, box) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [SizedBox(height: box.maxHeight, child: widget.placeholder)],
              ),
            )
          : ListView.separated(
              controller: _controller,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                widget.padding.left,
                widget.padding.top + 8.h,
                widget.padding.right,
                widget.padding.bottom + 16.h + ScreenSize.bottomInset(context),
              ),
              itemCount: widget.children.length + (widget.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => widget.gap.h.height,
              itemBuilder: (_, i) => i < widget.children.length
                  ? widget.children[i]
                  : Padding(
                      padding: 12.h.vertical,
                      child: Center(
                        child: SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(strokeWidth: 2.w, color: theme.primary),
                        ),
                      ),
                    ),
            ),
    );
  }
}
