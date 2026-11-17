part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the task form renders itself from.
class TaskFormState extends Equatable {
  /// `loading` while people/task load or the save runs; `success` otherwise.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// People who can be assigned (from the staff directory).
  final List<AppUser> candidates;

  /// Raw title text.
  final String title;

  /// People currently assigned.
  final List<UserRef> assignees;

  /// True when each assignee gets their own quota.
  final bool split;

  /// Raw quota text per assignee id.
  final Map<String, String> shares;

  /// Chosen deadline.
  final DateTime due;

  /// Chosen priority.
  final TaskPriority priority;

  /// Raw reward text (thousands-formatted).
  final String reward;

  /// Raw description text.
  final String description;

  /// Raw expected-result text.
  final String expected;

  /// Flipped on the first submit attempt; until then no field turns red.
  final bool showErrors;

  /// One-shot: the task was saved and the screen should close.
  final bool saved;

  /// Builds the initial state; [due] is the default deadline.
  /// Wizard step shown, 0..4 (create mode only).
  final int step;

  /// True when the client is an organization.
  final bool clientIsOrg;

  /// Organization or client name; empty for an internal task.
  final String client;

  /// Address the work happens at.
  final String address;

  /// Currency of the price: `uzs` or `usd`.
  final String currency;

  /// Files already uploaded for this task (photos and documents), in upload order.
  final List<FileAttachment> attachments;

  /// True while a picked file is being uploaded.
  final bool uploading;

  const TaskFormState({
    required this.due,
    this.status = ScreenStatus.initial,
    this.response,
    this.candidates = const [],
    this.title = '',
    this.assignees = const [],
    this.split = false,
    this.shares = const {},
    this.priority = TaskPriority.medium,
    this.reward = '',
    this.description = '',
    this.expected = '',
    this.showErrors = false,
    this.saved = false,
    this.step = 0,
    this.clientIsOrg = false,
    this.client = '',
    this.address = '',
    this.currency = 'uzs',
    this.attachments = const [],
    this.uploading = false,
  });

  /// Validation message for the title, independent of [showErrors].
  String? get titleError => title.trim().isEmpty ? TrWords.clNeedsName.tr() : null;

  /// Validation message for the assignees, independent of [showErrors].
  String? get assigneesError => assignees.isEmpty ? TrWords.formNeedsWho.tr() : null;

  /// Title error the FIELD should display — nothing before the first submit.
  /// Why the current wizard step cannot be left yet, or null when it can.
  String? get stepError => switch (step) {
    0 => titleError,
    _ => null,
  };

  String? get visibleTitleError => showErrors ? titleError : null;

  /// Assignee error the FIELD should display — nothing before the first submit.
  String? get visibleAssigneesError => showErrors ? assigneesError : null;

  /// Copies the state; [response] and [saved] reset unless passed, so each
  /// fires once per emit.
  TaskFormState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    List<AppUser>? candidates,
    String? title,
    List<UserRef>? assignees,
    bool? split,
    Map<String, String>? shares,
    DateTime? due,
    TaskPriority? priority,
    String? reward,
    String? description,
    String? expected,
    bool? showErrors,
    bool saved = false,
    int? step,
    bool? clientIsOrg,
    String? client,
    String? address,
    String? currency,
    List<FileAttachment>? attachments,
    bool? uploading,
  }) => TaskFormState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    candidates: candidates ?? this.candidates,
    title: title ?? this.title,
    assignees: assignees ?? this.assignees,
    split: split ?? this.split,
    shares: shares ?? this.shares,
    due: due ?? this.due,
    priority: priority ?? this.priority,
    reward: reward ?? this.reward,
    description: description ?? this.description,
    expected: expected ?? this.expected,
    showErrors: showErrors ?? this.showErrors,
    saved: saved,
    step: step ?? this.step,
    clientIsOrg: clientIsOrg ?? this.clientIsOrg,
    client: client ?? this.client,
    address: address ?? this.address,
    currency: currency ?? this.currency,
    attachments: attachments ?? this.attachments,
    uploading: uploading ?? this.uploading,
  );

  @override
  List<Object?> get props => [
    status,
    response,
    candidates,
    title,
    assignees,
    split,
    shares,
    due,
    priority,
    reward,
    description,
    expected,
    showErrors,
    saved,
    step,
    clientIsOrg,
    client,
    address,
    currency,
    attachments,
    uploading,
  ];
}
