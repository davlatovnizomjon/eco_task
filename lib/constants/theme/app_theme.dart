import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The single app-wide design-token object. Every color, text style and
/// decoration in the app is read from here — never a raw hex or `Colors.*`.
final theme = _AppTheme();

/// Holds the Eco Tasks light/dark palettes, typography and shared
/// decorations. Private to this file; the app uses the [theme] instance.
class _AppTheme {
  /// True while the dark palette is active; set by the app root from the
  /// stored theme mode and the platform brightness before each rebuild.
  bool dark = false;

  /// Picks [light] or [night] depending on [dark].
  Color _pick(int light, int night) => Color(dark ? night : light);

  // ─── Brand ────────────────────────────────────────────────────────────────

  /// Brand green: primary buttons, active states, links.
  Color get primary => _pick(0xFF0E7A52, 0xFF3BC189);

  /// Pressed/darker brand shade, used for text on [primaryTint].
  Color get primaryDark => _pick(0xFF095C3D, 0xFF6AD9A8);

  /// Soft brand tint behind selected items and success blocks.
  Color get primaryTint => _pick(0xFFE2F1E8, 0xFF163527);

  /// Foreground drawn on top of [primary].
  Color get onPrimary => _pick(0xFFFFFFFF, 0xFF05261A);

  /// Deep forest green of the wordmark.
  Color get forest => const Color(0xFF0B3D2A);

  // ─── Surfaces ─────────────────────────────────────────────────────────────

  /// Screen background behind every scaffold.
  Color get background => _pick(0xFFF3F5F2, 0xFF0F1411);

  /// Default card/panel surface sitting on [background].
  Color get cardColor => _pick(0xFFFFFFFF, 0xFF171E1A);

  /// Lighter surface for chips, tracks and segmented controls.
  Color get cardColorLight => _pick(0xFFEDF1EC, 0xFF1F2823);

  /// Background of dialogs and bottom sheets.
  Color get dialogBackground => cardColor;

  /// Hairline borders, dividers and the sheet drag handle.
  Color get line => _pick(0xFFDCE2DA, 0xFF2B362F);

  // ─── Text ─────────────────────────────────────────────────────────────────

  /// Primary text color.
  Color get text => _pick(0xFF15201A, 0xFFE6ECE7);

  /// Secondary text — descriptions and values.
  Color get textSecondary => _pick(0xFF46524A, 0xFFB0BBB3);

  /// Third-level text — hints, captions, disabled labels.
  Color get grayText => _pick(0xFF5F6B63, 0xFF8E9A92);

  // ─── Status families (foreground + tinted background) ─────────────────────

  /// Informational blue (in progress).
  Color get info => _pick(0xFF2059C0, 0xFF86ADF3);

  /// Tinted background behind [info].
  Color get infoBg => _pick(0xFFE5EDFA, 0xFF1A2942);

  /// Warning amber (overdue, attention).
  Color get warn => _pick(0xFF965500, 0xFFEDB04F);

  /// Tinted background behind [warn].
  Color get warnBg => _pick(0xFFFCEFD9, 0xFF382A12);

  /// Error red: failures, destructive actions, invalid fields.
  Color get red => _pick(0xFFB8352A, 0xFFF2887A);

  /// Tinted background behind [red].
  Color get redBg => _pick(0xFFFAE6E3, 0xFF3C1D19);

  /// Review purple (waiting for a decision).
  Color get review => _pick(0xFF6544BC, 0xFFB9A4F6);

  /// Tinted background behind [review].
  Color get reviewBg => _pick(0xFFEEE8FA, 0xFF29233F);

  /// Neutral gray (new, canceled).
  Color get neutral => _pick(0xFF56625A, 0xFFA3AEA7);

  /// Tinted background behind [neutral].
  Color get neutralBg => _pick(0xFFE7ECE7, 0xFF252E29);

  // ─── Decorations ──────────────────────────────────────────────────────────

  /// Default card surface — used by `CardWidget` and every panel.
  BoxDecoration get cardDecor => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(14.r),
    border: Border.all(color: line),
  );

  /// Shadow of the pinned bottom bar, separating it from scrolled content.
  List<BoxShadow> get bottomBarShadow => [
    BoxShadow(
      offset: const Offset(0, -2),
      blurRadius: 12,
      color: const Color(0xFF000000).withValues(alpha: dark ? 0.35 : 0.06),
    ),
  ];

  // ─── Typography ───────────────────────────────────────────────────────────

  /// Base body style every other inline style is derived from with `copyWith`.
  TextStyle get textStyle => TextStyle(fontFamily: 'Onest', fontSize: 15.sp, fontWeight: FontWeight.w500, color: text);

  /// Main heading inside a card — task title, person name.
  TextStyle get cardTitle => textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600);

  /// Second line under [cardTitle] — dates, hints, counters.
  TextStyle get cardSubtitle => textStyle.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w400, color: grayText);

  /// Text inside a colored status pill; the color comes from the caller.
  TextStyle get badgeText => textStyle.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600);

  /// Small gray label above an input or a value row.
  TextStyle get fieldLabel => textStyle.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600, color: textSecondary);

  /// Section heading above a block of cards.
  TextStyle get sectionLabel => fieldLabel;

  /// Big title of a tab root screen.
  TextStyle get screenTitle => textStyle.copyWith(fontSize: 24.sp, fontWeight: FontWeight.w700, letterSpacing: -0.3);

  /// Large marketing-style headline (login).
  TextStyle get headline =>
      textStyle.copyWith(fontSize: 28.sp, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.3);

  /// Wordmark style (Unbounded) for `eco.tasks`.
  TextStyle get logoStyle =>
      TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w700, letterSpacing: -1, color: dark ? text : forest);

  /// Material 3 [ThemeData] for the active palette, handed to `MaterialApp`.
  ThemeData get data => ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    fontFamily: 'Onest',
    scaffoldBackgroundColor: background,
    dividerColor: line,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: background,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: text, size: 20.sp),
    ),
    dialogTheme: DialogThemeData(backgroundColor: dialogBackground),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primary,
      selectionHandleColor: primary,
      selectionColor: primary.withValues(alpha: 0.35),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Color(0xFFFFFFFF)),
      trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : line),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primaryTint,
      height: 68.h,
      labelTextStyle: WidgetStatePropertyAll(
        textStyle.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600, color: textSecondary),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: forest,
      contentTextStyle: const TextStyle(color: Color(0xFFFFFFFF)),
    ),
  );
}
