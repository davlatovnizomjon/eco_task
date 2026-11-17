import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/call_buttons.dart';
import 'package:eco_task/presentation/public/widgets/call_glass_bar.dart';

import '../../bloc/bloc.dart';

/// The glass control bar of a live call: loudspeaker (or flip camera while the picture is on), camera, microphone and
/// the red end / leave button.
class CallControls extends StatelessWidget {
  /// Current call state.
  final CallState state;

  /// True when the end button should read "leave" (group calls).
  final bool leave;

  /// Builds the bar.
  const CallControls({super.key, required this.state, this.leave = false});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CallBloc>();
    return CallGlassBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (state.video)
            CallRoundButton(
              icon: AppIcons.flip,
              label: TrWords.callCameraBack.tr(),
              onTap: () => bloc.add(const CallCameraFlipped()),
            )
          else
            CallRoundButton(
              icon: AppIcons.speaker,
              label: TrWords.callStart.tr(),
              on: state.speaker,
              onTap: () => bloc.add(const CallSpeakerToggled()),
            ),
          CallRoundButton(
            icon: state.video ? AppIcons.videoOff : AppIcons.video,
            label: TrWords.callStart.tr(),
            onTap: () => bloc.add(const CallVideoToggled()),
          ),
          CallRoundButton(
            icon: state.muted ? AppIcons.micOff : AppIcons.mic,
            label: TrWords.callStart.tr(),
            on: state.muted,
            onTap: () => bloc.add(const CallMuteToggled()),
          ),
          CallEndButton(
            label: leave ? TrWords.callLeave.tr() : TrWords.callClose.tr(),
            onTap: state.busy ? null : () => bloc.add(const CallEnded()),
          ),
        ],
      ),
    );
  }
}
