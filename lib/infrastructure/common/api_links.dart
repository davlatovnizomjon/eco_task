import '../../constants/app_config.dart';

/// Every backend path the app calls, in one place. Repositories reference
/// these constants — an inline endpoint literal is banned, so a moved route
/// is a one-line change here.
///
/// Paths are relative to [baseUrl].
class ApiLinks {
  /// Private constructor — the class is a namespace of constants.
  const ApiLinks._();

  /// Root of the REST API (`/api/v1/`). Nothing else in the app hardcodes it.
  static const baseUrl = '${AppConfig.apiHost}/api/v1/';

  /// Root of the chat WebSocket (`ws://` / `wss://` form of the API host).
  static final wsBase = AppConfig.apiHost.replaceFirst('http', 'ws');

  /// WebSocket of one conversation; the token travels in the `bearer` subprotocol.
  static String chatSocket(String conversationId) => '$wsBase/ws/chat/$conversationId/';

  /// `GET` — conversations of the signed-in user; `POST` opens a direct/task/group chat.
  static const conversations = 'conversations/';

  /// `GET` — people the signed-in user may start a direct chat with.
  static const chatContacts = 'conversations/contacts/';

  /// `GET` — one conversation.
  static String conversation(String id) => 'conversations/$id/';

  /// `GET` — message history (`before`, `limit`); `POST` sends over REST.
  static String conversationMessages(String id) => 'conversations/$id/messages/';

  /// `PATCH` / `DELETE` — edits or deletes one message.
  static String conversationMessage(String id, int messageId) => 'conversations/$id/messages/$messageId/';

  /// `PUT` / `DELETE` — sets or removes the caller's reaction on a message.
  static String messageReaction(String id, int messageId) => 'conversations/$id/messages/$messageId/reaction/';

  /// `PUT` / `DELETE` — pins a message or clears the pin.
  static String conversationPin(String id) => 'conversations/$id/pin/';

  /// `POST` — adds members to a group.
  static String conversationMembers(String id) => 'conversations/$id/members/';

  /// `DELETE` — removes a member (or leaves the group when it is the caller).
  static String conversationMember(String id, String userId) => 'conversations/$id/members/$userId/';

  /// `POST` — moves the read marker of the signed-in user.
  static String conversationRead(String id) => 'conversations/$id/read/';

  /// `POST` — sign-in with login and password; returns token and account.
  static const authLogin = 'auth/login';

  /// `POST` — trades `{refresh}` for a new `{token, refresh}` pair; needs no bearer token.
  static const authRefresh = 'auth/refresh';

  /// `POST` — revokes the current bearer token on the backend; no body, 204 response.
  static const authLogout = 'auth/logout';

  /// `GET` — newest published app build of `?platform=android|ios`; public, needs no bearer token.
  static const appVersion = 'app-version/';

  /// `GET` — terms of use `{title, message, updated_at}` in the `Accept-Language` language (Uzbek when
  /// it is not translated yet); public, needs no bearer token.
  static const legalTerms = 'legal/terms/';

  /// `GET` — privacy policy, same shape and rules as [legalTerms].
  static const legalPrivacy = 'legal/privacy/';

  /// `GET` — dispatcher phone and Telegram `{phone, telegram}` shown on the sign-in screen; public, needs no bearer token.
  static const supportContact = 'support/';

  /// `GET` — paged, filtered task list of the signed-in scope; `POST` creates.
  static const tasks = 'tasks';

  /// `GET` — tasks of one month for the calendar (not paged).
  static const calendar = 'tasks/calendar';

  /// `GET` — one task with expenses, comments and log; `PUT` edits it.
  static String task(String id) => 'tasks/$id';

  /// `POST` — cancels a task.
  static String taskCancel(String id) => 'tasks/$id/cancel';

  /// `DELETE` — removes the comment at position [index] of a task.
  static String taskComment(String id, int index) => 'tasks/$id/comments/$index';

  /// Marks a task as failed with a reason.
  static String taskFail(String id) => 'tasks/$id/fail';

  /// Reports progress on a task.
  static String taskProgress(String id) => 'tasks/$id/progress';

  /// `POST` multipart — uploads one file.
  static const files = 'files/';

  /// `GET` — downloads one file (authorized).
  static String file(int id) => 'files/$id/';

  /// `POST` — starts a call in a conversation; `GET` lists its calls.
  static String conversationCalls(String id) => 'conversations/$id/calls/';

  /// `GET` — one call.
  static String call(int id) => 'calls/$id/';

  /// `POST` — `answer`, `decline`, `end` or `invite` on a call.
  static String callAction(int id, String action) => 'calls/$id/$action/';

  /// WebSocket of the signed-in device: call events and WebRTC signalling.
  static String get meSocket => '$wsBase/ws/me/';

  /// `POST` — adds a comment.

  static String taskComments(String id) => 'tasks/$id/comments';

  /// `POST` — a worker adds an expense.
  static String taskExpenses(String id) => 'tasks/$id/expenses';

  /// `POST` — a worker submits the result for review.
  static String taskSubmit(String id) => 'tasks/$id/submit';

  /// `POST` — the boss approves the submitted result.
  static String taskApprove(String id) => 'tasks/$id/approve';

  /// `POST` — the boss returns the task for rework.
  static String taskReturn(String id) => 'tasks/$id/return';

  /// `POST` — marks the task reward as paid out.
  static String taskPay(String id) => 'tasks/$id/pay';

  /// `GET` — paged expenses list with a status filter.
  static const expenses = 'expenses';

  /// `GET` — money totals and filter counters of the expenses screen.
  static const expensesSummary = 'expenses/summary';

  /// `POST` — approves (with `amount`) or rejects one expense.
  static String expenseReview(String taskId, String expenseId) => 'tasks/$taskId/expenses/$expenseId/review';

  /// `POST` — marks an approved expense as paid out.
  static String expensePay(String taskId, String expenseId) => 'tasks/$taskId/expenses/$expenseId/pay';

  /// `GET` — paged staff or client directory; `POST` opens a new account.
  static const users = 'users';

  /// `GET` — one account.
  static String user(String id) => 'users/$id';

  /// `GET`/`PUT` — role and permission switches of a staff member.
  static String permissions(String id) => 'users/$id/permissions';

  /// `GET` — paged inbox of the signed-in user.
  static const notifications = 'notifications';

  /// `POST` — marks one entry (or all) as read.
  static const notificationsRead = 'notifications/read';

  /// `POST` registers / `DELETE` forgets this device's push token.
  static const notificationsDevices = 'notifications/devices';

  /// `GET` — numbers of the boss dashboard.
  static const dashboard = 'dashboard';

  /// `GET` — aggregated report numbers for a period.
  static const reports = 'reports';

  /// `GET` — numbers of one statistics screen (`kind`, `period`, `offset`).
  static const stats = 'reports/stats';

  /// `POST` — prepares the downloadable file of one statistics screen.
  static const statsExport = 'reports/export';

  /// `GET` — numbers of the profile screen.
  static const profileSummary = 'profile/summary';

  /// `PATCH` — edits the signed-in person's `{name, login}`; returns the updated account.
  static const account = 'account';

  /// `POST` — changes the signed-in person's password from `{oldPassword, newPassword}`; returns `{token}`.
  static const accountPassword = 'account/password';
}
