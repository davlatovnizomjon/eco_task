import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/update_dialog.dart';
import 'package:eco_task/infrastructure/dto/models/update_check.dart';
import 'package:eco_task/infrastructure/repository/app_update_repository.dart';
import 'package:eco_task/presentation/routes/coordinator.dart';

import '../bloc/bloc.dart';
import 'maintenance_screen.dart';

/// Wraps the whole app: checks the version at launch and whenever the app returns to the foreground. While the version
/// endpoint fails with a server error it covers the app with [MaintenanceScreen]; otherwise it shows the update dialog:
/// with a "Keyinroq" button the user can postpone, or — when the backend marks the release as mandatory — without it,
/// so the dialog stays until the app is updated.
class UpdateGate extends StatefulWidget {
  /// The app (the router's navigator) the gate sits over.
  final Widget child;

  /// Wraps [child].
  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

/// Owns the bloc for the lifetime of the app and re-checks on resume.
class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  /// Version check bloc, created once.
  late final UpdateBloc _bloc = UpdateBloc(repository: context.read<AppUpdateRepository>())
    ..add(const UpdateRequested());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _bloc.add(const UpdateRequested());
  }

  /// Opens the store page of the app; a missing or unopenable link is ignored.
  Future<void> _openStore(UpdateCheck check) async {
    final uri = Uri.tryParse(check.storeUrl);
    if (uri == null || !uri.hasScheme) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No handler for the link: the dialog simply stays.
    }
  }

  /// Kinds of update dialog on screen right now (`true` = mandatory), so the maintenance wall coming and going never
  /// stacks a second copy of a dialog that is still open underneath it.
  final _open = <bool>{};

  /// Shows the update dialog above the router's navigator (the gate itself sits above it). A [forced] one has no
  /// "later" button and never closes.
  void _offer(UpdateCheck check, {required bool forced}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = rootNavigatorKey.currentContext;
      if (navigator == null || !navigator.mounted || !_open.add(forced)) return;
      showUpdateDialog(
        navigator,
        // The admin's wording from the backend wins; the app's own text fills in when a field is empty.
        title: check.title.isNotEmpty ? check.title : (forced ? TrWords.updateRequiredTitle : TrWords.updateTitle).tr(),
        subtitle: check.subtitle.isNotEmpty
            ? check.subtitle
            : forced
            ? TrWords.updateRequiredBody.tr()
            : TrWords.updateBody.tr(args: [check.latest, check.current]),
        onUpdate: () => _openStore(check),
        onLater: forced ? null : () => _bloc.add(UpdateDismissed(check.latest)),
      ).whenComplete(() => _open.remove(forced));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<UpdateBloc, UpdateState>(
        listenWhen: (previous, current) => (!previous.offer && current.offer) || (!previous.blocked && current.blocked),
        listener: (context, state) => _offer(state.check!, forced: state.blocked),
        buildWhen: (previous, current) => previous.maintenance != current.maintenance,
        // The maintenance wall sits above the router, so it hides every screen and dialog at once.
        builder: (context, state) => Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (state.maintenance) const Positioned.fill(child: MaintenanceScreen()),
          ],
        ),
      ),
    );
  }
}
