part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the legal sheet renders itself from.
class LegalState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// Why the last load failed; null otherwise.
  final ScreenResponse? response;

  /// The loaded text; null before it arrives and when the backend has none published.
  final LegalDocument? document;

  /// Builds the initial state (nothing requested yet).
  const LegalState({this.status = ScreenStatus.initial, this.response, this.document});

  /// Copies the state; [response] is cleared unless a new one is passed and [document] is replaced as given.
  LegalState copyWith({ScreenStatus? status, Object? response = _absent, Object? document = _absent}) => LegalState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    document: identical(document, _absent) ? this.document : document as LegalDocument?,
  );

  @override
  List<Object?> get props => [status, response, document?.title, document?.updatedAt, document?.sections.length];
}
