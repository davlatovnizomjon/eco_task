# Enums for closed sets (status / type / state / level)

Whenever a value can only be one of a **fixed, known set** — a request status, a domain state, a kind,
a difficulty level, a role, an attendance result — model it as an **enum**, not a `String`, an `int`,
or a cluster of `bool` flags. Enums make the set exhaustive (the compiler checks every `switch`),
self-documenting, and impossible to set to an invalid value.

**Put per-value behaviour and data INSIDE the enum**, so every screen reads it the same way and a change
propagates from one place. A consumer must never re-interpret an enum with its own `switch`/`if` to pick
a label, icon, or color — that scatters the mapping and drifts out of sync.

```dart
// {feature}/enum/attendance_status.dart
import 'package:app/constants/constants.dart';
import 'package:flutter/material.dart';

enum AttendanceStatus {
  pending,
  attended,
  absent;

  /// Parse from API/JSON (name- or id-based); always provide a safe fallback.
  factory AttendanceStatus.fromString(String? value) => values.firstWhere(
        (e) => e.name == value?.trim().toLowerCase(),
        orElse: () => AttendanceStatus.pending,
      );

  String get title => switch (this) {            // a label per value
        AttendanceStatus.pending  => Tr.attendancePending.tr(),
        AttendanceStatus.attended => Tr.attendanceCame.tr(),
        AttendanceStatus.absent   => Tr.attendanceMissed.tr(),
      };

  IconData get icon => switch (this) {           // an icon per value (or `Widget get badge`)
        AttendanceStatus.pending  => Icons.more_horiz,
        AttendanceStatus.attended => Icons.check,
        AttendanceStatus.absent   => Icons.close,
      };

  Color get color => switch (this) {             // a color per value
        AttendanceStatus.pending  => theme.orangeText,
        AttendanceStatus.attended => theme.primary,
        AttendanceStatus.absent   => theme.red,
      };

  bool get isMarked => this != AttendanceStatus.pending;   // a predicate per value
}
```

## What belongs on the enum

Add the member only when that facet actually exists for the set:

- **`title` / label** → `String get title` (localized).
- **icon** → `IconData get icon`; if the UI needs a ready widget (badge, colored dot, chip),
  expose `Widget get badge` / `Widget icon({double size})` ON the enum instead of building it per screen.
- **color** → `Color get color`.
- **parsing** → `factory X.fromJson(...)` / `factory X.fromString(...)` (with a fallback); serialize
  back with `value.name` (or a stable `int get id`).
- **predicates / transitions** → `bool get isFinal`, `bool get canEdit`, `X get next`.
- **a value derived from another model** → a `factory X.fromModel(model)` (e.g. an activity's lifecycle
  computed from its date + cancelled flag). Keep the enum free of an import cycle: take the raw inputs
  (`factory X.compute({required DateTime date, required bool isCancelled})`) rather than importing the
  model, and expose it as a getter ON the model (`ActivityLifecycle get lifecycle`).

## Rules

- **One enum per file** at `{feature}/enum/{name}.dart`; **export every enum from the feature barrel**
  (`{feature}.dart`, named after the feature folder) — an enum that isn't exported is an incomplete feature.
- **Models hold the enum, not the raw code.** `fromJson` builds it via the enum's factory; `toJson`
  emits `value.name`/`value.id`. State fields, event payloads, and filters are typed by the enum
  (`ActivityDifficulty difficulty`, not `int`).
- **The UI calls `value.title` / `value.icon` / `value.color` directly.** Finding a `switch`/`if` over an
  enum inside a widget to choose UI is a smell — move that mapping onto the enum and inline the getter.
- Use `BlocStatus`-style status enums (with an extension exposing `isLoading`/`isSuccess`/...) for the
  request lifecycle; use feature enums for domain states.

## Worked reference — a feature's `enum/` folder

A feature that models three closed sets ends up with one file per enum under `{feature}/enum/`:

- `{feature}_difficulty.dart` — `easy/middle/hard` with `title`, `icon`, `color`, `factory fromString`.
- `{feature}_attendance.dart` — `pending/attended/absent` with `title`, `icon`, `color`
  (yellow/green/red) and an `isMarked` predicate.
- `{feature}_lifecycle.dart` — `upcoming/completed/cancelled` with `title`, `color`, `isActive`, and a
  `factory compute({date, isCancelled})` consumed by the model's `lifecycle` getter.

All three are exported from `{feature}.dart`; the model stores the enum (not its raw code); cards, the
detail screen, the form and the filter render `value.title` / `value.icon` / `value.color` with no
local `switch`.
