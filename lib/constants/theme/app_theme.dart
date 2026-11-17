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
  Color get primary => _pick(0xFF15803D, 0xFF3BC189);

  /// Pressed/darker brand shade, used for text on [primaryTint].
  Color get primaryDark => _pick(0xFF116632, 0xFF6AD9A8);

  /// Soft brand tint behind selected items and success blocks.
  Color get primaryTint => _pick(0xFFE3F3E8, 0xFF163527);

  /// Foreground drawn on top of [primary].
  Color get onPrimary => _pick(0xFFFFFFFF, 0xFF05261A);

  /// Deep forest green of the wordmark.
  Color get forest => const Color(0xFF0B3D2A);

  // ─── Surfaces ─────────────────────────────────────────────────────────────

  /// Screen background behind every scaffold.
  Color get background => _pick(0xFFF2F5F3, 0xFF0F1411);

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

  /// Green presence dot of an online person.
  Color get online => const Color(0xFF22A055);

  /// Top of the call screens' dark green backdrop (the same in light and dark mode).
  Color get callTop => const Color(0xFF2E6B4A);

  /// Middle of the call backdrop.
  Color get callMid => const Color(0xFF173826);

  /// Bottom of the call backdrop.
  Color get callBottom => const Color(0xFF0D2016);

  /// Round buttons of the call control bar and tiles on the call backdrop (white veil).
  Color get callVeil => const Color(0x1FFFFFFF);

  /// Glass panel behind the call controls.
  Color get callGlass => const Color(0x38000000);

  /// Foreground of the call screens (text, glyphs on the backdrop).
  Color get callInk => const Color(0xFFFFFFFF);

  /// Softer text on the call backdrop (status line, timer).
  Color get callInkSoft => const Color(0xBFFFFFFF);

  /// Dark glyph on a white (active) call button.
  Color get callInkDark => const Color(0xFF14231B);

  /// Hang up / decline.
  Color get callRed => const Color(0xFFE5383B);

  /// Answer / redial.
  Color get callGreen => const Color(0xFF2BB463);

  /// Amber status line on the call backdrop ("no answer").
  Color get callWarn => const Color(0xFFFFC46B);

  /// Soft red status line and muted-microphone glyph on the call backdrop.
  Color get callRedSoft => const Color(0xFFFF7A7A);

  /// Ring around a participant who is speaking.
  Color get callSpeaking => const Color(0xFF34C759);

  /// Placeholder gradients of photo thumbnails (top-left to bottom-right), cycled by index.
  List<List<Color>> get photoTones => const [
    [Color(0xFF5E8F5A), Color(0xFF2E5B3A)],
    [Color(0xFF9AB86B), Color(0xFF4D7A3C)],
    [Color(0xFFB9A27A), Color(0xFF6E5A3E)],
  ];

  /// Dim layer behind a dialog.
  Color get scrim => const Color(0x6B08120C);

  /// Gold of the "best employee" star badge.
  Color get gold => const Color(0xFFE9A23B);

  // ─── Platform dialogs (iOS alert / Android Material 3 dialog) ───────────────

  /// Frosted surface of the iOS-style alert.
  Color get iosAlertBackground => _pick(0xF0F2F2F2, 0xEB252525);

  /// Title colour of the iOS-style alert.
  Color get iosAlertText => _pick(0xFF000000, 0xFFFFFFFF);

  /// Message colour of the iOS-style alert.
  Color get iosAlertSubtext => _pick(0xBF3C3C43, 0xB3EBEBF5);

  /// Hairlines between the iOS-style alert's text and buttons.
  Color get iosAlertDivider => _pick(0x4A3C3C43, 0xA6545458);

  /// Button label colour of the iOS-style alert.
  Color get iosAlertAction => _pick(0xFF1F8A4C, 0xFF30D158);

  /// Drop shadow of the iOS-style alert.
  Color get iosAlertShadow => _pick(0x2E000000, 0x80000000);

  /// Shadow of a top toast: one soft drop in light, a deeper two-layer drop in dark.
  List<BoxShadow> get toastShadow => dark
      ? const [
          BoxShadow(offset: Offset(0, 14), blurRadius: 36, color: Color(0x99000000)),
          BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x66000000)),
        ]
      : const [BoxShadow(offset: Offset(0, 12), blurRadius: 32, color: Color(0x290F1914))];

  /// Surface of the Material 3 style dialog.
  Color get m3DialogBackground => _pick(0xFFF2F6F2, 0xFF1D2420);

  /// Title colour of the Material 3 style dialog.
  Color get m3DialogTitle => _pick(0xFF191C1A, 0xFFE1E4E0);

  /// Body colour of the Material 3 style dialog.
  Color get m3DialogBody => _pick(0xFF414942, 0xFFC0C9C1);

  /// Icon and button label colour of the Material 3 style dialog.
  Color get m3DialogAction => _pick(0xFF1F8A4C, 0xFF7FDA9E);

  /// Drop shadow of the Material 3 style dialog.
  Color get m3DialogShadow => _pick(0x29000000, 0x80000000);

  // ─── Decorations ──────────────────────────────────────────────────────────

  /// Default card surface — used by `CardWidget` and every panel.
  BoxDecoration get cardDecor => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(14.r),
    border: Border.all(color: line),
  );

  /// Soft elevation of a panel card (light theme only; the dark theme uses borders).
  List<BoxShadow> get panelShadow => dark
      ? const []
      : [
          BoxShadow(offset: const Offset(0, 1), blurRadius: 2, color: const Color(0xFF14281C).withValues(alpha: 0.05)),
          BoxShadow(offset: const Offset(0, 4), blurRadius: 14, color: const Color(0xFF14281C).withValues(alpha: 0.05)),
        ];

  /// Translucent surface of the "⋯" popup menu (the screen shows through, blurred).
  Color get menuSurface => _pick(0xEBFAFAFA, 0xEB252B27);

  /// Drop shadow of the "⋯" popup menu.
  List<BoxShadow> get menuShadow => [
    BoxShadow(offset: const Offset(0, 10), blurRadius: 38, color: const Color(0xFF000000).withValues(alpha: 0.18)),
  ];

  /// Lift of the front card of the dashboard task stack; none in the dark palette.
  List<BoxShadow> get stackShadow => dark
      ? const []
      : [BoxShadow(offset: const Offset(0, 8), blurRadius: 22, color: const Color(0xFF0F1914).withValues(alpha: 0.08))];

  /// Panel card of the redesigned screens: 18 px corners, hairline border and soft shadow.
  BoxDecoration get panelDecor => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(18.r),
    border: Border.all(color: line),
    boxShadow: panelShadow,
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
