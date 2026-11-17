import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/call_status.dart';
import 'package:eco_task/infrastructure/services/call_media.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/duration_formatter.dart';

import '../../bloc/bloc.dart';
import 'call_controls.dart';

/// A live one-to-one call: the other person's portrait with "calling…" or the timer, or — while the camera is on — their
/// picture full screen with your own in a small corner window. [media] is null on the mock backend (no real pictures).
class DirectCallView extends StatelessWidget {
  /// Current call state.
  final CallState state;

  /// Id of the signed-in person.
  final String meId;

  /// Audio/video session of the call, or null.
  final CallMedia? media;

  /// Builds the view.
  const DirectCallView({super.key, required this.state, required this.meId, required this.media});

  @override
  Widget build(BuildContext context) {
    final call = state.call!;
    final other = state.conversation!.other(meId);
    final ringing = call.status == CallStatus.ringing;
    final status = ringing ? TrWords.callCalling.tr() : DurationFormatter.clock(state.seconds);
    return ListenableBuilder(
      listenable: media?.changes ?? ValueNotifier(0),
      builder: (context, _) {
        final remote = other == null ? null : media?.remoteRenderers[other.id];
        final remoteVideo = other != null && (media?.remoteDevices[other.id]?.video ?? false) && remote != null;
        final showVideo = state.video || remoteVideo;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (showVideo && remote != null)
              Positioned.fill(child: RTCVideoView(remote, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)),
            if (showVideo)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.callBottom.withValues(alpha: 0.35),
                        const Color(0x00000000),
                        const Color(0x00000000),
                        theme.callBottom.withValues(alpha: 0.55),
                      ],
                      stops: const [0, 0.22, 0.62, 1],
                    ),
                  ),
                ),
              ),
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
                  if (showVideo)
                    Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            other?.name ?? '',
                            style: theme.textStyle.copyWith(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: theme.callInk,
                            ),
                          ),
                          Text(
                            status,
                            style: theme.textStyle.copyWith(fontSize: 13.sp, color: theme.callInkSoft),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (!showVideo)
              Positioned(
                top: 120.h,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (other != null)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: ringing
                              ? [
                                  BoxShadow(color: theme.callVeil.withValues(alpha: 0.08), spreadRadius: 10.w),
                                  BoxShadow(color: theme.callVeil.withValues(alpha: 0.04), spreadRadius: 22.w),
                                ]
                              : null,
                        ),
                        child: UserAvatar(other, size: 120.w),
                      ),
                    28.h.height,
                    Text(
                      other?.name ?? '',
                      style: theme.textStyle.copyWith(
                        fontSize: 26.sp,
                        height: 32 / 26,
                        fontWeight: FontWeight.w700,
                        color: theme.callInk,
                      ),
                    ),
                    6.h.height,
                    Text(
                      status,
                      style: theme.textStyle.copyWith(fontSize: 16.sp, color: theme.callInkSoft),
                    ),
                  ],
                ),
              ),
            if (state.video && media != null)
              Positioned(
                right: 16.w,
                top: 110.h,
                width: 104.w,
                height: 150.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18.r),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.callInk.withValues(alpha: 0.7), width: 2),
                    ),
                    child: RTCVideoView(
                      media!.localRenderer,
                      mirror: state.front,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 34.h,
              child: CallControls(state: state),
            ),
          ],
        );
      },
    );
  }
}
