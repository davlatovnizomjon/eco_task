import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

/// One tile of the group-call grid: the person's picture (or their avatar), their name and a red microphone mark while
/// they are muted. [dim] fades a person who is still ringing.
class ParticipantTile extends StatelessWidget {
  /// The person.
  final UserRef user;

  /// Name shown on the tile ("You" for the signed-in person).
  final String label;

  /// Diameter of the avatar; smaller in the three-column grid.
  final double avatarSize;

  /// Live picture of the person, or null to show the avatar.
  final RTCVideoRenderer? video;

  /// True while the person is muted.
  final bool muted;

  /// True while the person has not answered yet.
  final bool dim;

  /// Mirrors the picture (own front camera).
  final bool mirror;

  /// Builds the tile.
  const ParticipantTile({
    super.key,
    required this.user,
    required this.label,
    required this.avatarSize,
    this.video,
    this.muted = false,
    this.dim = false,
    this.mirror = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: ColoredBox(
          color: theme.callVeil.withValues(alpha: 0.08),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (video != null)
                RTCVideoView(video!, mirror: mirror, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
              else
                Center(child: UserAvatar(user, size: avatarSize)),
              Positioned(
                left: 12.w,
                bottom: 10.h,
                right: 12.w,
                child: Row(
                  children: [
                    if (muted) ...[AppIcon(AppIcons.micOff, size: 14.sp, color: theme.callRedSoft), 6.w.width],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textStyle.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.callInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
