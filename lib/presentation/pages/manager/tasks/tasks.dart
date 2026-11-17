/// Public surface of the task feature of the manager: the active task list, today's tasks and the
/// details and create/edit sub-screens. The repository is app-wide (`TasksRepository`), so the feature owns only
/// its blocs.
library;

export 'bloc/bloc.dart';
export 'presentation/screens/task_detail/task_detail.dart';
export 'presentation/screens/task_form/task_form.dart';
export 'presentation/screens/today/today.dart';
export 'presentation/tasks_screen.dart';
