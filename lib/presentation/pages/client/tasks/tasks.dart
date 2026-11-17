/// Public surface of the order feature of the client: the list of orders, an order's details and the create / edit
/// sub-screens. The repository is app-wide (`TasksRepository`), so the feature owns only its blocs.
library;

export 'bloc/bloc.dart';
export 'presentation/screens/task_detail/task_detail.dart';
export 'presentation/screens/task_form/task_form.dart';
export 'presentation/tasks_screen.dart';
