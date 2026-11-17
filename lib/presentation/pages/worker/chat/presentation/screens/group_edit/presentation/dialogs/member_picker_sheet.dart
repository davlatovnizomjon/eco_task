import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/select_mark.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

/// Bottom sheet that lists the people who can still join a group (or a call), each with a round check; the action
/// button resolves to the checked people.
class MemberPickerSheet extends StatefulWidget {
  /// People that are not in the group yet.
  final List<UserRef> candidates;

  /// Heading of the sheet; "Add member" when null.
  final String? title;

  /// Grey line under the heading; none when null.
  final String? hint;

  /// Text of the action button; "Add" when null.
  final String? action;

  /// Builds the sheet.
  const MemberPickerSheet({super.key, required this.candidates, this.title, this.hint, this.action});

  /// Opens the sheet; resolves to the picked people, or null when dismissed.
  static Future<List<UserRef>?> show(
    BuildContext context,
    List<UserRef> candidates, {
    String? title,
    String? hint,
    String? action,
  }) => showBottomDialog<List<UserRef>>(
    MemberPickerSheet(candidates: candidates, title: title, hint: hint, action: action),
    context,
  );

  @override
  State<MemberPickerSheet> createState() => _MemberPickerSheetState();
}

/// Holds the ids that are checked.
class _MemberPickerSheetState extends State<MemberPickerSheet> {
  /// Ids currently checked.
  final Set<String> _picked = {};

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ?? TrWords.ch2AddMember.tr(),
            style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
          ),
          if (widget.hint != null) ...[2.h.height, Text(widget.hint!, style: theme.cardSubtitle)],
          4.h.height,
          Flexible(
            child: widget.candidates.isEmpty
                ? EmptyView.tile(title: TrWords.chatNoContacts.tr(), icon: AppIcons.users)
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.candidates.length,
                    itemBuilder: (context, i) {
                      final u = widget.candidates[i];
                      return InkWell(
                        onTap: () => setState(() {
                          if (!_picked.remove(u.id)) _picked.add(u.id);
                        }),
                        child: Container(
                          constraints: BoxConstraints(minHeight: 60.h),
                          decoration: BoxDecoration(
                            border: i == 0 ? null : Border(top: BorderSide(color: theme.line)),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(u, size: 36.w),
                              12.w.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textStyle),
                                    if (u.role != null) ...[3.h.height, RolePill(u.role!)],
                                  ],
                                ),
                              ),
                              SelectMark(shape: SelectShape.circle, on: _picked.contains(u.id)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          12.h.height,
          Btn(
            text: widget.action ?? TrWords.ch2Add.tr(),
            height: 52.h,
            onPressed: _picked.isEmpty
                ? null
                : () => Navigator.pop(context, [
                    for (final u in widget.candidates)
                      if (_picked.contains(u.id)) u,
                  ]),
          ),
        ],
      ),
    );
  }
}
