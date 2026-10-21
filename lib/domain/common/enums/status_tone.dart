import 'package:flutter/painting.dart';

import '../../../constants/constants.dart';

/// Color family of a status, chip or tile; every status enum points at one.
enum StatusTone {
  /// Brand green — done, approved, healthy.
  primary,

  /// Blue — in progress, informational.
  info,

  /// Amber — overdue, needs attention.
  warn,

  /// Red — failed, rejected, destructive.
  error,

  /// Purple — waiting for a decision.
  review,

  /// Gray — new, canceled, neutral.
  neutral;

  /// Foreground color: text and icon of a chip or tile.
  Color get color => switch (this) {
    StatusTone.primary => theme.primaryDark,
    StatusTone.info => theme.info,
    StatusTone.warn => theme.warn,
    StatusTone.error => theme.red,
    StatusTone.review => theme.review,
    StatusTone.neutral => theme.neutral,
  };

  /// Tinted background that sits behind [color].
  Color get bgColor => switch (this) {
    StatusTone.primary => theme.primaryTint,
    StatusTone.info => theme.infoBg,
    StatusTone.warn => theme.warnBg,
    StatusTone.error => theme.redBg,
    StatusTone.review => theme.reviewBg,
    StatusTone.neutral => theme.neutralBg,
  };
}
