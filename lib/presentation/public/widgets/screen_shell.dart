import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';
import 'card_widget.dart';

/// The shell every screen is built inside: tap-to-dismiss focus, the themed
/// `Scaffold`, the app bar and an optional pinned bottom bar.
///
/// Feature code never writes its own `Scaffold`/`AppBar` — that duplication
/// is what this widget exists to remove.
class ScreenShell extends StatelessWidget {
  /// App bar title.
  final String title;

  /// Screen body, already padded by [padding].
  final Widget child;

  /// Trailing app bar actions.
  final List<Widget> actions;

  /// Whether the app bar shows a back button. Root screens pass false.
  final bool showBack;

  /// Left-aligned big title with an optional [subtitle] — tab root screens.
  final bool big;

  /// Small line above the big title (a date, a team name).
  final String? subtitle;

  /// SVG asset of the leading button; defaults to the back arrow.
  final String? backIcon;

  /// Body padding; pass `EdgeInsets.zero` when [child] is a scroll view that
  /// carries its own padding, so content scrolls edge to edge.
  final EdgeInsets? padding;

  /// Pinned footer, rendered as the scaffold's bottom bar with the app's
  /// shadow and the bottom safe-area inset already applied.
  final Widget? bottomBar;

  /// Floating action button of the screen.
  final Widget? floatingActionButton;

  /// Lets the body shrink when the keyboard opens; forms pass true.
  final bool resizeToAvoidBottomInset;

  /// Builds the shell around [child].
  const ScreenShell({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.showBack = true,
    this.big = false,
    this.subtitle,
    this.backIcon,
    this.padding,
    this.bottomBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tapping outside an input closes the keyboard on every screen.
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: theme.background,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: !big,
          toolbarHeight: big ? 72.h : kToolbarHeight,
          titleSpacing: big ? 16.w : null,
          title: big
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtitle != null)
                      Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardSubtitle),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.screenTitle),
                  ],
                )
              : Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textStyle.copyWith(fontSize: 17.sp, fontWeight: FontWeight.w600),
                ),
          leading: showBack
              // maybePop keeps a screen's PopScope (exit confirm, result on
              // pop) working without every screen passing a custom handler.
              ? IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: AppIcon(backIcon ?? AppIcons.left, color: theme.text),
                )
              // A root screen inside a role shell opens that shell's left drawer.
              : (Scaffold.maybeOf(context)?.hasDrawer ?? false)
              ? IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: AppIcon(AppIcons.menu, color: theme.text),
                )
              : null,
          actions: [...actions, 8.w.width],
        ),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
            child: child,
          ),
        ),
        bottomNavigationBar: bottomBar == null
            ? null
            : CardWidget(
                radius: 0,
                shadow: theme.bottomBarShadow,
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h + ScreenSize.bottomInset(context)),
                child: bottomBar!,
              ),
      ),
    );
  }
}
