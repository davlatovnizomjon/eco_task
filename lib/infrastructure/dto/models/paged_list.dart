/// One page of a server-paged list plus the paging meta.
class PagedList<T> {
  /// Items of this page.
  final List<T> items;

  /// 1-based number of this page.
  final int page;

  /// Number of the last page.
  final int lastPage;

  /// Total number of items across all pages.
  final int total;

  /// Builds a page from its parts.
  const PagedList({this.items = const [], this.page = 1, this.lastPage = 1, this.total = 0});

  /// Parses `{items, page, lastPage, total}`, mapping every item with [parse].
  factory PagedList.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) => PagedList(
    items: [for (final i in (json['items'] as List? ?? const [])) parse(i as Map<String, dynamic>)],
    page: (json['page'] as num?)?.toInt() ?? 1,
    lastPage: (json['lastPage'] as num?)?.toInt() ?? 1,
    total: (json['total'] as num?)?.toInt() ?? 0,
  );

  /// True when a next page can be requested.
  bool get hasMore => page < lastPage;
}
