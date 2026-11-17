part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the account form renders itself from.
class MemberFormState extends Equatable {
  /// Request lifecycle of the create call.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Raw name text.
  final String name;

  /// Raw (masked) phone text.
  final String phone;

  /// Raw login text.
  final String login;

  /// The temporary password the boss will hand over.
  final String password;

  /// Chosen staff role.
  final UserRole role;

  /// Raw address text (clients).
  final String address;

  /// True when the new client is an organization.
  final bool isOrg;

  /// Contact person (organization clients).
  final String contactPerson;

  /// Free note (clients).
  final String note;

  /// The account being edited, once loaded; null when opening a new one.
  final AppUser? seed;

  /// Flipped on the first submit attempt; until then no field turns red.
  final bool showErrors;

  /// One-shot: the created account; the screen shows its credentials and closes.
  final AppUser? created;

  /// Builds the initial state with a generated [password].
  const MemberFormState({
    required this.password,
    this.status = ScreenStatus.initial,
    this.response,
    this.name = '',
    this.phone = '',
    this.login = '',
    this.role = UserRole.worker,
    this.address = '',
    this.isOrg = false,
    this.contactPerson = '',
    this.note = '',
    this.seed,
    this.showErrors = false,
    this.created,
  });

  /// Validation message for the name, independent of [showErrors].
  String? get nameError => name.trim().isEmpty ? TrWords.vNameRequired.tr() : null;

  /// Validation message for the login, independent of [showErrors].
  String? get loginError => seed != null || login.trim().isNotEmpty ? null : TrWords.vLoginRequired.tr();

  /// Validation message for the phone (optional, but valid when typed).
  String? get phoneError => phone.isEmpty || PhoneFormatter.isValid(phone) ? null : TrWords.vPhoneInvalid.tr();

  /// Name error the FIELD should display — nothing before the first submit.
  String? get visibleNameError => showErrors ? nameError : null;

  /// Login error the FIELD should display — nothing before the first submit.
  String? get visibleLoginError => showErrors ? loginError : null;

  /// Phone error the FIELD should display — nothing before the first submit.
  String? get visiblePhoneError => showErrors ? phoneError : null;

  /// Copies the state; [response] and [created] reset unless passed, so each
  /// fires once per emit.
  MemberFormState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    String? name,
    String? phone,
    String? login,
    String? password,
    UserRole? role,
    String? address,
    bool? isOrg,
    String? contactPerson,
    String? note,
    AppUser? seed,
    bool? showErrors,
    AppUser? created,
  }) => MemberFormState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    login: login ?? this.login,
    password: password ?? this.password,
    role: role ?? this.role,
    address: address ?? this.address,
    isOrg: isOrg ?? this.isOrg,
    contactPerson: contactPerson ?? this.contactPerson,
    note: note ?? this.note,
    seed: seed ?? this.seed,
    showErrors: showErrors ?? this.showErrors,
    created: created,
  );

  @override
  List<Object?> get props => [
    status,
    response,
    name,
    phone,
    login,
    password,
    role,
    address,
    isOrg,
    contactPerson,
    note,
    seed,
    showErrors,
    created,
  ];
}
