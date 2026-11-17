import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/call_party_state.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/infrastructure/services/call_media.dart';
import 'package:eco_task/presentation/pages/admin/chat/presentation/screens/group_edit/presentation/dialogs/member_picker_sheet.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/utils/formatters/duration_formatter.dart';

import '../../bloc/bloc.dart';
import 'call_controls.dart';
import 'participant_tile.dart';

/// A live group call: a grid of the people in it (two columns up to four people, three columns beyond, nine tiles per
/// page with "+N more" / "back" tiles), the "add people" button, a short "X declined" notice and the control bar.
class GroupCallView extends StatelessWidget {
  /// Current call state.
  final CallState state;

  /// Id of the signed-in person.
  final String meId;

  /// Audio/video session of the call, or null on the mock backend.
  final CallMedia? media;

  /// Builds the view.
  const GroupCallView({super.key, required this.state, required this.meId, required this.media});

  /// Person tiles on a page that has navigation tiles.
  static const _perPage = 8;

  /// Largest group shown on one page without navigation tiles.
  static const _single = 9;

  /// Opens the "add people to the call" sheet and rings the picked people.
  Future<void> _add(BuildContext context, List<UserRef> inCall) async {
    final bloc = context.read<CallBloc>();
    final here = {for (final u in inCall) u.id};
    final candidates = [
      for (final m in state.conversation!.members)
        if (!here.contains(m.id) && m.id != meId) m,
    ];
    final picked = await MemberPickerSheet.show(
      context,
      candidates,
      title: TrWords.callAddTitle.tr(),
      hint: TrWords.callAddHint.tr(),
      action: TrWords.callInvite.tr(),
    );
    if (picked != null && picked.isNotEmpty) bloc.add(CallInvited([for (final u in picked) u.id]));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CallBloc>();
    final call = state.call!;
    // The signed-in person first, then who is in, then who still rings.
    final people = <(UserRef, CallPartyState)>[
      for (final p in call.parties)
        if (p.user.id == meId) (p.user, p.state),
      for (final p in call.parties)
        if (p.user.id != meId && p.state == CallPartyState.joined) (p.user, p.state),
      for (final p in call.parties)
        if (p.user.id != meId && p.state == CallPartyState.invited) (p.user, p.state),
    ];
    final paged = people.length > _single;
    final pageCount = paged ? (people.length / _perPage).ceil() : 1;
    final page = state.page.clamp(0, pageCount - 1);
    final shown = paged ? people.skip(page * _perPage).take(_perPage).toList() : people;
    final remaining = paged ? people.length - (page + 1) * _perPage : 0;
    final columns = people.length <= 4 ? 2 : 3;
    final cells = shown.length + (paged && page > 0 ? 1 : 0) + (remaining > 0 ? 1 : 0);
    final rows = (cells / columns).ceil();

    return ListenableBuilder(
      listenable: media?.changes ?? ValueNotifier(0),
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: 50.h,
              left: 12.w,
              right: 12.w,
              child: Row(
                children: [
                  IconButton(
                    tooltip: TrWords.callClose.tr(),
                    onPressed: () => context.pop(),
                    icon: AppIcon(AppIcons.left, size: 24.sp, color: theme.callInk),
                  ),
                  8.w.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.conversation!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.callInk,
                          ),
                        ),
                        Text(
                          '${TrWords.callMembersN.tr(args: ['${call.joined.length}'])} · ${DurationFormatter.clock(state.seconds)}',
                          style: theme.textStyle.copyWith(fontSize: 13.sp, color: theme.callInkSoft),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: TrWords.callAddTitle.tr(),
                    onPressed: () => _add(context, [for (final (u, _) in people) u]),
                    icon: AppIcon(AppIcons.plus, size: 24.sp, color: theme.callInk),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 112.h,
              left: 16.w,
              right: 16.w,
              bottom: 150.h,
              child: LayoutBuilder(
                builder: (context, box) {
                  const gap = 10.0;
                  final width = (box.maxWidth - gap * (columns - 1)) / columns;
                  final height = ((box.maxHeight - gap * (rows - 1)) / rows).clamp(0.0, 210.h);
                  return GridView.count(
                    crossAxisCount: columns,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                    childAspectRatio: width / (height <= 0 ? 1 : height),
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      if (paged && page > 0)
                        _NavTile(
                          icon: AppIcons.left,
                          label: TrWords.callBack.tr(),
                          onTap: () => bloc.add(CallPageChanged(page - 1)),
                        ),
                      for (final (u, s) in shown)
                        ParticipantTile(
                          user: u,
                          label: u.id == meId ? TrWords.callYou.tr() : u.firstName,
                          avatarSize: columns == 2 ? 76.w : 54.w,
                          video: u.id == meId
                              ? (state.video ? media?.localRenderer : null)
                              : ((media?.remoteDevices[u.id]?.video ?? false) ? media?.remoteRenderers[u.id] : null),
                          mirror: u.id == meId && state.front,
                          muted: u.id == meId ? state.muted : (media?.remoteDevices[u.id]?.muted ?? false),
                          dim: s == CallPartyState.invited,
                        ),
                      if (remaining > 0)
                        _NavTile(
                          big: '+$remaining',
                          label: TrWords.callMore.tr(),
                          onTap: () => bloc.add(CallPageChanged(page + 1)),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (state.notice != null)
              Positioned(
                left: 24.w,
                right: 24.w,
                bottom: 134.h,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(color: theme.callGlass, borderRadius: BorderRadius.circular(16.r)),
                    child: Text(
                      TrWords.callDeclinedBy.tr(args: [state.notice!]),
                      style: theme.textStyle.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.callInk,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 34.h,
              child: CallControls(state: state, leave: true),
            ),
          ],
        );
      },
    );
  }
}

/// Grid tile that pages the participants: "+N more" (a big number) or "back" (a chevron).
class _NavTile extends StatelessWidget {
  /// SVG asset of the glyph; null when [big] is shown.
  final String? icon;

  /// Large text instead of a glyph, e.g. `+4`.
  final String? big;

  /// Caption under the glyph / number.
  final String label;

  /// Tap handler.
  final VoidCallback onTap;

  /// Builds the tile.
  const _NavTile({this.icon, this.big, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: theme.callVeil, borderRadius: BorderRadius.circular(20.r)),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (big != null)
                Text(
                  big!,
                  style: theme.textStyle.copyWith(fontSize: 24.sp, fontWeight: FontWeight.w700, color: theme.callInk),
                )
              else
                AppIcon(icon!, size: 26.sp, color: theme.callInk),
              2.h.height,
              Text(
                label,
                style: theme.textStyle.copyWith(fontSize: 13.sp, color: theme.callInkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
