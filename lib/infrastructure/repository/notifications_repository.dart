import 'package:flutter/foundation.dart';

import '../common/api_cache.dart';
import '../common/api_links.dart';
import '../dto/models/inbox_page.dart';
import '../dto/models/notification_model.dart';
import '../dto/models/paged_list.dart';

import 'package:eco_task/infrastructure/common/dio_client.dart';

/// The signed-in user's inbox. [unread] is reactive so the tab badge updates
/// the moment any screen reads or marks entries.
class NotificationsRepository {
  /// Rows per page of the inbox.
  static const pageSize = 20;

  /// Unread counter shown on the notifications tab.
  final ValueNotifier<int> unread = ValueNotifier(0);

  /// Cached first page of the [group] tab, or an empty page.
  InboxPage cachedInbox(String group) =>
      ApiCache.read<InboxPage>('inbox|$group') ?? const InboxPage(page: PagedList<NotificationModel>());

  /// Loads page [page] of the [group] tab (`all|unread|review|deadlines|expenses`).
  Future<InboxPage> getInbox(String group, {int page = 1}) async {
    final response = await dioClient.get(
      ApiLinks.notifications,
      queryParameters: {'group': group, 'page': page, 'pageSize': pageSize},
    );
    final result = InboxPage.fromJson(response.data as Map<String, dynamic>);
    unread.value = result.unread;
    return page == 1 ? ApiCache.write('inbox|$group', result) : result;
  }

  /// Marks entry [id] (or every entry when null) as read.
  Future<void> markRead({String? id}) async {
    await dioClient.post(ApiLinks.notificationsRead, data: {if (id != null) 'id': id});
    ApiCache.invalidate();
  }

  /// Re-reads only the unread counter (first page of the unread tab).
  Future<void> refreshUnread() async {
    final response = await dioClient.get(
      ApiLinks.notifications,
      queryParameters: {'group': 'unread', 'page': 1, 'pageSize': 1},
    );
    unread.value = InboxPage.fromJson(response.data as Map<String, dynamic>).unread;
  }

  /// Releases the notifier when the app root is torn down.
  void dispose() => unread.dispose();
}
