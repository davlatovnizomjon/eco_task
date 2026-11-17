/// Every route of the app, with the path `go_router` registers it under.
/// Screens navigate with `context.push(Routes.x.path)` so a path is written
/// down exactly once. Parameterized paths expose a builder next to the enum
/// value, e.g. `Routes.taskDetail.of('ECO-142')`.
///
/// The full list with class and file names is in `NAVIGATION_MAP.md`.
enum Routes {
  /// Login and password sign-in; the entry while there is no session.
  signIn('/sign-in'),

  /// Bottom-navigation shell; its tabs depend on the account's role.
  home('/home'),

  /// Create a task (boss).
  taskNew('/tasks/new'),

  /// Start a chat or create a group.
  chatNew('/chat/new'),

  /// Create a group chat (admin).
  groupNew('/chat/group'),

  /// One conversation; `:id` is the conversation id.
  chat('/chat/:id'),

  /// Info page of a conversation (profile or group info); `:id` is the conversation id.
  chatInfo('/chat/:id/info'),

  /// Edit a group chat (title, members); `:id` is the conversation id.
  groupEdit('/chat/:id/edit'),

  /// Discussion of a task (opened or created on first use); `:id` is the task id.
  taskChat('/tasks/:id/chat'),

  /// Today's tasks (admin).
  todayTasks('/today'),

  /// Employee ranking by period (admin).
  rating('/rating'),

  /// Client list (admin).
  clients('/clients'),

  /// Archive of closed tasks (admin).
  archive('/archive'),

  /// Edit the signed-in person's profile (admin).
  profileEdit('/profile/edit'),

  /// Change the signed-in person's login and password (admin).
  loginChange('/profile/login'),

  /// A voice or video call; `:id` is the call id, or `new` to start one (query `conversation` and `kind`).
  call('/call/:id'),

  /// One statistics screen of the report tab (admin and manager); `:kind` is a `StatsKind` name.
  stats('/reports/:kind'),

  /// Calendar opened from the profile (worker).
  calendar('/calendar'),

  /// Task details; `:id` is the task id.
  taskDetail('/tasks/:id'),

  /// The admin's own task; `:id` is the task id.
  myTask('/my-tasks/:id'),

  /// Personal notes of the admin's own task; `:id` is the task id.
  myTaskNotes('/my-tasks/:id/notes'),

  /// Edit a task (boss); `:id` is the task id.
  taskEdit('/tasks/:id/edit'),

  /// Add an expense to a task (worker); `:id` is the task id.
  expenseForm('/tasks/:id/expense'),

  /// Submit the result of a task (worker); `:id` is the task id.
  resultSubmit('/tasks/:id/submit'),

  /// Review queue of results and expenses (boss).
  review('/review'),

  /// Expenses and payouts (boss).
  expenses('/expenses'),

  /// Approve or reject one expense; `:taskId` and `:expenseId`.
  expenseReview('/expenses/:taskId/:expenseId'),

  /// Staff and client directory (boss).
  team('/team'),

  /// Open a staff or client account (boss); `?client=1` selects clients.
  memberForm('/team/new'),

  /// Staff member profile; `:id` is the account id.
  employee('/team/:id'),

  /// Every task of a staff member, with done / failed tabs; `:id` is the account id.
  employeeTasks('/team/:id/tasks'),

  /// Inbox opened from a boss dashboard bell.
  notifications('/notifications'),

  /// A worker's closed tasks.
  history('/history'),

  /// Settings › language.
  settingsLanguage('/settings/language'),

  /// Settings › appearance.
  settingsAppearance('/settings/appearance'),

  /// Settings › notifications.
  settingsNotifications('/settings/notifications'),

  /// Settings › deadline reminders.
  settingsReminder('/settings/reminder');

  /// Binds a route to its URL path.
  const Routes(this.path);

  /// Path `go_router` matches and `context.push` receives.
  final String path;

  /// The concrete location with `:id` replaced by [id].
  String of(String id) => path.replaceFirst(':id', id);

  /// The concrete location with `:kind` replaced by [kind].
  String ofKind(String kind) => path.replaceFirst(':kind', kind);

  /// The concrete location of [expenseReview] for a task and expense.
  String ofExpense(String taskId, String expenseId) =>
      path.replaceFirst(':taskId', taskId).replaceFirst(':expenseId', expenseId);
}
