import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_icon.dart';
import 'user_avatar.dart';

/// One entry of a role's left menu: either a section shown inside the shell ([page]) or a pushed screen ([route]).
class SideMenuItem {
  /// Localized label.
  final String label;

  /// SVG asset of the leading glyph.
  final String icon;

  /// Section body kept alive in the shell's `IndexedStack`; null for a pushed entry.
  final Widget? page;

  /// Router path pushed on tap; used when [page] is null.
  final String? route;

  /// Optional reactive unread counter shown as a badge.
  final ValueListenable<int>? badge;

  /// Builds a section entry.
  const SideMenuItem.section(this.label, this.icon, Widget this.page, {this.badge}) : route = null;

  /// Builds an entry that pushes [route].
  const SideMenuItem.push(this.label, this.icon, String this.route, {this.badge}) : page = null;
}

/// Role shell: the sections of [items] under a left drawer with the account header. The selected
/// section is the app-wide `homeTab`, so any screen can switch it.
class SideMenuShell extends StatelessWidget {
  /// Menu entries in display order; entries with a `page` become the shell's sections, in that order.
  final List<SideMenuItem> items;

  /// Builds the shell.
  const SideMenuShell({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final sections = [
      for (final i in items)
        if (i.page != null) i,
    ];
    final badges = Listenable.merge([
      for (final i in items)
        if (i.badge != null) i.badge!,
    ]);
    return ValueListenableBuilder<int>(
      valueListenable: homeTab,
      builder: (context, selected, _) {
        final index = selected.clamp(0, sections.length - 1);
        return Scaffold(
          backgroundColor: theme.background,
          drawer: Drawer(
            backgroundColor: theme.background,
            child: SafeArea(
              child: ListenableBuilder(
                listenable: badges,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MenuHeader(),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        children: [
                          for (final item in items)
                            _MenuTile(
                              item: item,
                              selected: item.page != null && identical(sections[index], item),
                              onTap: () {
                                Navigator.pop(context);
                                if (item.page != null) {
                                  homeTab.value = sections.indexOf(item);
                                } else {
                                  context.push(item.route!);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: IndexedStack(index: index, children: [for (final s in sections) s.page!]),
        );
      },
    );
  }
}

/// Drawer header: the signed-in account's avatar, name and role.
class _MenuHeader extends StatelessWidget {
  /// Builds the header.
  const _MenuHeader();

  @override
  Widget build(BuildContext context) {
    final me = RepositoryProvider.of<SessionRepository>(context).user.value!.user;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
      child: Row(
        children: [
          UserAvatar(me.ref, size: 48.w),
          12.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(me.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardTitle),
                Text(me.role.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One drawer row: glyph, label and the unread badge.
class _MenuTile extends StatelessWidget {
  /// The entry drawn.
  final SideMenuItem item;

  /// True for the section currently shown.
  final bool selected;

  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Builds the row.
  const _MenuTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = item.badge?.value ?? 0;
    return ListTile(
      selected: selected,
      selectedTileColor: theme.primaryTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      leading: AppIcon(item.icon, size: 22.sp, color: selected ? theme.primaryDark : theme.grayText),
      title: Text(
        item.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.cardTitle.copyWith(color: selected ? theme.primaryDark : theme.text),
      ),
      trailing: count > 0 ? Badge(label: Text('$count')) : null,
      onTap: onTap,
    );
  }
}
