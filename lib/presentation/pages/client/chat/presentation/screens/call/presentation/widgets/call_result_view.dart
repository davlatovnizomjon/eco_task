import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/call_status.dart';
import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/call_buttons.dart';
import 'package:eco_task/presentation/public/widgets/call_glass_bar.dart';
import 'package:eco_task/presentation/public/widgets/redial_slider.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

import '../../bloc/bloc.dart';

/// What the caller sees when nobody picked up: "declined" or "no answer" under the callee, a swipe-to-redial control
/// and a close button.
class CallResultView extends StatelessWidget {
  /// Current call state.
  final CallState state;

  /// Id of the signed-in person.
  final String meId;

  /// Builds the view.
  const CallResultView({super.key, required this.state, required this.meId});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CallBloc>();
    final conversation = state.conversation!;
    final group = conversation.kind == ChatKind.group;
    final other = conversation.other(meId);
    final declined = state.call!.status == CallStatus.declined;
    return Stack(
      children: [
        Positioned(
          top: 50.h,
          left: 12.w,
          child: IconButton(
            tooltip: TrWords.callClose.tr(),
            onPressed: () => context.pop(),
            icon: AppIcon(AppIcons.left, size: 24.sp, color: theme.callInk),
          ),
        ),
        Positioned(
          top: 120.h,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Opacity(
                opacity: 0.85,
                child: group
                    ? Container(
                        width: 120.w,
                        height: 120.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: theme.primary),
                        child: AppIcon(AppIcons.users, size: 52.sp, color: theme.callInk),
                      )
                    : other == null
                    ? SizedBox(width: 120.w, height: 120.w)
                    : UserAvatar(other, size: 120.w),
              ),
              28.h.height,
              Text(
                group ? conversation.title : other?.name ?? '',
                textAlign: TextAlign.center,
                style: theme.textStyle.copyWith(
                  fontSize: 26.sp,
                  height: 32 / 26,
                  fontWeight: FontWeight.w700,
                  color: theme.callInk,
                ),
              ),
              6.h.height,
              Text(
                declined ? TrWords.callDeclined.tr() : TrWords.callNoAnswer.tr(),
                style: theme.textStyle.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: declined ? theme.callRedSoft : theme.callWarn,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16.w,
          right: 16.w,
          bottom: 34.h,
          child: CallGlassBar(
            child: Row(
              children: [
                Expanded(
                  child: RedialSlider(text: TrWords.callRedial.tr(), onRedial: () => bloc.add(const CallRedialed())),
                ),
                10.w.width,
                Semantics(
                  button: true,
                  label: TrWords.callClose.tr(),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 64.w,
                      height: 64.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.callVeil),
                      child: AppIcon(AppIcons.x, size: 26.sp, color: theme.callInk),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
