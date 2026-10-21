import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/notice_banner.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';

import '../../bloc/bloc.dart';

/// Worker's "update progress" sheet: a stepper for the worker's own quota (when
/// the task has one), the outcome (in progress / cannot be done) and a short
/// note. Dispatches to the opener's [TaskDetailBloc].
class TaskProgressDialog extends StatefulWidget {
  /// The worker's quota in pieces; 0 for tasks without a quantity.
  final int share;

  /// Pieces the worker has already reported.
  final int done;

  /// Builds the sheet body.
  const TaskProgressDialog({super.key, required this.share, required this.done});

  @override
  State<TaskProgressDialog> createState() => _TaskProgressDialogState();
}

/// Holds the stepper value, the outcome choice and the note controller.
class _TaskProgressDialogState extends State<TaskProgressDialog> {
  /// Pieces reported in this sheet.
  late int _done = widget.done;

  /// True when "cannot be done" is selected.
  bool _cant = false;

  /// Controller of the optional note.
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.share > 0) ...[
          Text(TrWords.wHowMany.tr(args: ['${widget.share}']), style: theme.sectionLabel),
          10.h.height,
          Row(
            children: [
              SizedBox(
                width: 56.w,
                child: Btn.unActive(text: '−', onPressed: _done > 0 ? () => setState(() => _done--) : null),
              ),
              Expanded(
                child: Center(
                  child: Text('$_done', style: theme.screenTitle.copyWith(fontSize: 30.sp)),
                ),
              ),
              SizedBox(
                width: 56.w,
                child: Btn.unActive(text: '+', onPressed: _done < widget.share ? () => setState(() => _done++) : null),
              ),
            ],
          ),
          10.h.height,
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: 3.circular,
                  child: LinearProgressIndicator(
                    value: _done / widget.share,
                    minHeight: 6.h,
                    backgroundColor: theme.cardColorLight,
                    color: theme.primary,
                  ),
                ),
              ),
              10.w.width,
              Text('${widget.done} → $_done', style: theme.cardSubtitle),
            ],
          ),
          16.h.height,
        ],
        CardWidget(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              OptionTile(
                title: '',
                first: true,
                leading: StatusChip.task(TaskStatus.prog),
                onTap: () => setState(() => _cant = false),
                trailing: AppIcon(_cant ? AppIcons.eq : AppIcons.checkc, color: _cant ? theme.line : theme.primary),
              ),
              OptionTile(
                title: '',
                subtitle: TrWords.wReasonHint.tr(),
                leading: StatusChip(label: TrWords.stCant.tr(), tone: StatusTone.error, icon: AppIcons.xc),
                onTap: () => setState(() => _cant = true),
                trailing: AppIcon(_cant ? AppIcons.checkc : AppIcons.eq, color: _cant ? theme.primary : theme.line),
              ),
            ],
          ),
        ),
        12.h.height,
        NoticeBanner(text: TrWords.tasksConfirmedHint.tr(), tone: StatusTone.primary),
        12.h.height,
        InputBox(controller: _note, hint: TrWords.wShortComment.tr(), leftIcon: AppIcons.msg),
        16.h.height,
        Btn(
          text: TrWords.cSave.tr(),
          onPressed: () {
            context.read<TaskDetailBloc>().add(
              TaskDetailProgressReported(done: _done, cant: _cant, note: _note.text.trim()),
            );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
