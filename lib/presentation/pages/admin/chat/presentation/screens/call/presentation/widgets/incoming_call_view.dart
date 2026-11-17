import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/call_buttons.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

import '../../bloc/bloc.dart';

/// Ringing screen of the invited person: who is calling (a person, or a group with the people already in) and the
/// round decline / answer buttons.
class IncomingCallView extends StatelessWidget {
  /// Current call state.
  final CallState state;

  /// Id of the signed-in person.
  final String meId;

  /// Builds the view.
  const IncomingCallView({super.key, required this.state, required this.meId});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CallBloc>();
    final call = state.call!;
    final conversation = state.conversation!;
    final group = conversation.kind == ChatKind.group;
    final caller = call.caller;
    final inCall = call.joined;
    return Stack(
      children: [
        Positioned(
          top: 120.h,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (group)
                Container(
                  width: 120.w,
                  height: 120.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primary,
                    boxShadow: [
                      BoxShadow(color: theme.callVeil.withValues(alpha: 0.08), spreadRadius: 10.w),
                      BoxShadow(color: theme.callVeil.withValues(alpha: 0.04), spreadRadius: 22.w),
                    ],
                  ),
                  child: AppIcon(AppIcons.users, size: 52.sp, color: theme.callInk),
                )
              else if (caller != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: theme.callVeil.withValues(alpha: 0.08), spreadRadius: 10.w),
                      BoxShadow(color: theme.callVeil.withValues(alpha: 0.04), spreadRadius: 22.w),
                    ],
                  ),
                  child: UserAvatar(caller, size: 120.w),
                ),
              28.h.height,
              Text(
                group ? conversation.title : caller?.name ?? '',
                textAlign: TextAlign.center,
                style: theme.textStyle.copyWith(
                  fontSize: 26.sp,
                  height: 32 / 26,
                  fontWeight: FontWeight.w700,
                  color: theme.callInk,
                ),
              ),
              6.h.height,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  group ? TrWords.callGroupInvite.tr(args: [caller?.name ?? '']) : TrWords.callIncoming.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textStyle.copyWith(fontSize: 16.sp, color: theme.callInkSoft),
                ),
              ),
              if (group && inCall.isNotEmpty) ...[
                18.h.height,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: (34 + (inCall.take(4).length - 1) * 29).w,
                      height: 34.w,
                      child: Stack(
                        children: [
                          for (final (i, u) in inCall.take(4).indexed)
                            Positioned(
                              left: (i * 29).w,
                              child: UserAvatar(u, size: 34.w),
                            ),
                        ],
                      ),
                    ),
                    10.w.width,
                    Text(
                      TrWords.callInCallN.tr(args: ['${inCall.length}']),
                      style: theme.textStyle.copyWith(fontSize: 14.sp, color: theme.callInkSoft),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 68.w,
          right: 68.w,
          bottom: 80.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CallPickButton(
                label: TrWords.cReject.tr(),
                accept: false,
                icon: AppIcons.callEnd,
                onTap: state.busy ? null : () => bloc.add(const CallDeclined()),
              ),
              CallPickButton(
                label: TrWords.callAccept.tr(),
                accept: true,
                icon: AppIcons.handset,
                onTap: state.busy ? null : () => bloc.add(const CallAnswered()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
