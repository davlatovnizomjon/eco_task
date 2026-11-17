part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the help sheet renders itself from.
class SupportState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// Why the last load failed; null otherwise.
  final ScreenResponse? response;

  /// Contacts loaded from the backend.
  final SupportContact contact;

  /// Builds the initial state (nothing requested yet).
  const SupportState({this.status = ScreenStatus.initial, this.response, this.contact = SupportContact.none});

  /// Copies the state; [response] is cleared unless a new one is passed.
  SupportState copyWith({ScreenStatus? status, Object? response = _absent, SupportContact? contact}) => SupportState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    contact: contact ?? this.contact,
  );

  @override
  List<Object?> get props => [status, response, contact.phone, contact.telegram];
}
