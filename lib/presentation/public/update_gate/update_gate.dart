/// Public surface of the app-update feature.
///
/// It owns no repository: `AppUpdateRepository` is created by the app root and read by the gate.
library;

export 'bloc/bloc.dart';
export 'presentation/update_gate.dart';
