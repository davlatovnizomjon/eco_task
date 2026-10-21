/// Public surface of the sign-in feature.
///
/// It owns no repository: signing in mutates the app-wide `SessionRepository`,
/// which the router and every other feature also read.
library;

export 'bloc/bloc.dart';
export 'presentation/auth_screen.dart';
