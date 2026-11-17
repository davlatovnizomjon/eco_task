import '../common/api_cache.dart';
import '../common/api_links.dart';
import '../dto/models/app_user.dart';
import '../dto/models/new_account.dart';
import '../dto/models/paged_list.dart';
import '../dto/models/permissions_model.dart';

import 'package:eco_task/infrastructure/common/dio_client.dart';

/// Staff and client directory, account opening and permission switches.
class TeamRepository {
  /// Rows per page of the directory.
  static const pageSize = 30;

  /// Cache key of a directory query.
  String _key(bool clients, String search) => 'users|$clients|$search';

  /// Cached first page of the directory query, or an empty page.
  PagedList<AppUser> cachedUsers({required bool clients, String search = ''}) =>
      ApiCache.read<PagedList<AppUser>>(_key(clients, search)) ?? const PagedList();

  /// Loads page [page] of the staff (or [clients]) directory filtered by [search].
  Future<PagedList<AppUser>> getUsers({required bool clients, String search = '', int page = 1}) async {
    final response = await dioClient.get(
      ApiLinks.users,
      queryParameters: {
        'role': clients ? 'client' : 'staff',
        if (search.isNotEmpty) 'q': search,
        'page': page,
        'pageSize': pageSize,
      },
    );
    final result = PagedList.fromJson(response.data as Map<String, dynamic>, AppUser.fromJson);
    return page == 1 ? ApiCache.write(_key(clients, search), result) : result;
  }

  /// Loads one account.
  Future<AppUser> getUser(String id) async =>
      AppUser.fromJson((await dioClient.get(ApiLinks.user(id))).data as Map<String, dynamic>);

  /// Opens a new account; the backend answers 409 when the login is taken.
  Future<AppUser> addUser(NewAccount account) async {
    final response = await dioClient.post(ApiLinks.users, data: account.toJson());
    ApiCache.invalidate();
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  /// Saves the editable fields of account [id]; only the given keys change.
  Future<AppUser> updateUser(String id, Map<String, dynamic> fields) async {
    final response = await dioClient.patch(ApiLinks.user(id), data: fields);
    ApiCache.invalidate();
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  /// Deletes account [id]; resolves to true when it was removed, false when it was only deactivated (it has history).
  Future<bool> deleteUser(String id) async {
    final response = await dioClient.delete(ApiLinks.user(id));
    ApiCache.invalidate();
    return (response.data as Map)['result'] == 'deleted';
  }

  /// Loads the permission switches of staff member [id].
  Future<PermissionsModel> getPermissions(String id) async =>
      PermissionsModel.fromJson((await dioClient.get(ApiLinks.permissions(id))).data as Map<String, dynamic>);

  /// Saves the permission switches and role of a staff member.
  Future<PermissionsModel> savePermissions(PermissionsModel value) async {
    final response = await dioClient.put(ApiLinks.permissions(value.userId), data: value.toJson());
    ApiCache.invalidate();
    return PermissionsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
