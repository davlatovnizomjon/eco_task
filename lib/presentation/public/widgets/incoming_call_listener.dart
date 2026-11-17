import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/infrastructure/repository/call_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

/// Wraps a signed-in role shell: opens the personal call link while the shell lives and opens the call screen as
/// soon as somebody rings the signed-in person, whatever screen they are on.
class IncomingCallListener extends StatefulWidget {
  /// The shell to wrap.
  final Widget child;

  /// Builds the listener.
  const IncomingCallListener({super.key, required this.child});

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

/// Holds the repository and the id of the ring that already opened a screen.
class _IncomingCallListenerState extends State<IncomingCallListener> {
  late final CallRepository _calls;

  /// Id of the call whose screen was already opened, so one ring opens one screen.
  int? _shown;

  @override
  void initState() {
    super.initState();
    _calls = RepositoryProvider.of<CallRepository>(context);
    final me = RepositoryProvider.of<SessionRepository>(context).user.value;
    if (me != null) _calls.connect(me.user.id);
    _calls.incoming.addListener(_onIncoming);
  }

  @override
  void dispose() {
    _calls.incoming.removeListener(_onIncoming);
    _calls.disconnect();
    super.dispose();
  }

  /// Opens the call screen for a new ring.
  void _onIncoming() {
    final call = _calls.incoming.value;
    if (call == null) {
      _shown = null;
      return;
    }
    if (_shown == call.id || !mounted) return;
    _shown = call.id;
    context.push(Routes.call.of('${call.id}'));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
