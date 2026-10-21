import 'notification_model.dart';
import 'paged_list.dart';

/// One page of the inbox plus the account's total unread counter.
class InboxPage {
  /// The page of entries.
  final PagedList<NotificationModel> page;

  /// Unread entries across all pages (drives the tab badge).
  final int unread;

  /// Builds an inbox page from its parts.
  const InboxPage({required this.page, this.unread = 0});

  /// Parses the API object.
  factory InboxPage.fromJson(Map<String, dynamic> json) => InboxPage(
    page: PagedList.fromJson(json, NotificationModel.fromJson),
    unread: (json['unread'] as num?)?.toInt() ?? 0,
  );
}
