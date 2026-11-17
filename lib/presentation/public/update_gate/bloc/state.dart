part of 'bloc.dart';

/// Everything the update gate renders itself from.
class UpdateState extends Equatable {
  /// Latest comparison, or null before the first successful check.
  final UpdateCheck? check;

  /// Release version the user postponed; its dialog is not shown again.
  final String dismissed;

  /// True while the version endpoint answers with a server error or the release is flagged `is_maintenance`: the
  /// maintenance wall covers the app.
  final bool maintenance;

  /// True while a retry from the maintenance wall is running.
  final bool retrying;

  /// Builds a state; the default is "nothing checked yet".
  const UpdateState({this.check, this.dismissed = '', this.maintenance = false, this.retrying = false});

  /// True while a mandatory update applies: its dialog has no "later" button.
  bool get blocked => !maintenance && check?.need == UpdateNeed.required;

  /// True while the postponable dialog should be on screen.
  bool get offer => !maintenance && check?.need == UpdateNeed.optional && check!.latest != dismissed;

  /// Copy with the given fields replaced.
  UpdateState copyWith({UpdateCheck? check, String? dismissed, bool? maintenance, bool? retrying}) => UpdateState(
    check: check ?? this.check,
    dismissed: dismissed ?? this.dismissed,
    maintenance: maintenance ?? this.maintenance,
    retrying: retrying ?? this.retrying,
  );

  @override
  List<Object?> get props => [check, dismissed, maintenance, retrying];
}
