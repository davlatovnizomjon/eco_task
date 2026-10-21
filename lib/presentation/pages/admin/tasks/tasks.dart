/// Public surface of the task feature: the boss task list and its sub-screens
/// (details, create/edit form, expense form, result submission). The repository
/// is app-wide (`TasksRepository`), so the feature owns only its blocs.
library;

export 'bloc/bloc.dart';
export 'presentation/screens/expense_form/expense_form.dart';
export 'presentation/screens/result_submit/result_submit.dart';
export 'presentation/screens/task_detail/task_detail.dart';
export 'presentation/screens/task_form/task_form.dart';
export 'presentation/tasks_screen.dart';
