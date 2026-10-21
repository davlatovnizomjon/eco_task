import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

import '../../bloc/bloc.dart';

/// "Who is it for?" sheet: searchable list of the boss themself and the staff.
/// It reads the candidate list from the opener's [TaskFormBloc] and dispatches
/// the final selection back to it.
class AssigneePickerDialog extends StatefulWidget {
  /// Builds the sheet body.
  const AssigneePickerDialog({super.key});

  @override
  State<AssigneePickerDialog> createState() => _AssigneePickerDialogState();
}

/// Holds the draft selection and the search text.
class _AssigneePickerDialogState extends State<AssigneePickerDialog> {
  /// Ids currently ticked, seeded from the form's assignees.
  late final Set<String> _picked = {for (final p in context.read<TaskFormBloc>().state.assignees) p.id};

  /// Lower-cased search text.
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaskFormBloc>();
    final me = RepositoryProvider.of<SessionRepository>(context).user.value!.user;
    // The boss themself first, then the staff; each as a reference + subtitle.
    final people = [
      (me.ref, TrWords.formMyself.tr(), me.name),
      for (final u in bloc.state.candidates)
        if (u.id != me.id) (u.ref, u.name, TrWords.cActiveN.tr(args: ['${u.activeCount}'])),
    ].where((p) => _query.isEmpty || p.$1.name.toLowerCase().contains(_query)).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputBox(
          hint: TrWords.formSearchPerson.tr(),
          leftIcon: AppIcons.search,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        12.h.height,
        Flexible(
          child: SingleChildScrollView(
            child: CardWidget(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, (ref, title, subtitle)) in people.indexed)
                    OptionTile(
                      title: title,
                      subtitle: subtitle,
                      first: i == 0,
                      leading: UserAvatar(ref, size: 40.w),
                      onTap: () =>
                          setState(() => _picked.contains(ref.id) ? _picked.remove(ref.id) : _picked.add(ref.id)),
                      trailing: AppIcon(
                        _picked.contains(ref.id) ? AppIcons.checkc : AppIcons.eq,
                        color: _picked.contains(ref.id) ? theme.primary : theme.line,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        10.h.height,
        Row(
          children: [
            AppIcon(AppIcons.info, size: 16.sp, color: theme.grayText),
            6.w.width,
            Expanded(
              child: Text(
                TrWords.formPickHelp.tr(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.cardSubtitle,
              ),
            ),
          ],
        ),
        14.h.height,
        Btn(
          text: TrWords.formPickN.tr(args: ['${_picked.length}']),
          onPressed: () {
            // Candidates plus the boss, in the order the sheet showed them.
            final all = <String, UserRef>{me.id: me.ref, for (final u in bloc.state.candidates) u.id: u.ref};
            bloc.add(
              TaskFormAssigneesChanged([
                for (final id in _picked)
                  if (all[id] != null) all[id]!,
              ]),
            );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
