import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/photo_strip.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// "Submit result" screen (worker): a three-point checklist, photos and a
/// summary, then send for review. Provides [ResultSubmitBloc] over the
/// app-wide [TasksRepository].
class ResultSubmitScreen extends StatelessWidget {
  /// Id of the task being submitted.
  final String taskId;

  /// Builds the screen.
  const ResultSubmitScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          ResultSubmitBloc(repository: RepositoryProvider.of<TasksRepository>(ctx), taskId: taskId)
            ..add(const ResultSubmitStarted()),
      child: const _ResultSubmitView(),
    );
  }
}

/// Renders the checklist, photo section and summary field.
class _ResultSubmitView extends StatelessWidget {
  /// Builds the screen body.
  const _ResultSubmitView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ResultSubmitBloc>();
    final meId = RepositoryProvider.of<SessionRepository>(context).user.value!.user.id;
    return BlocConsumer<ResultSubmitBloc, ResultSubmitState>(
      listenWhen: (prev, cur) => cur.response != null || cur.saved,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        // Closes this screen and the task details screen, which is stale now.
        if (state.saved) {
          context.pop();
          context.pop();
        }
      },
      builder: (context, state) {
        final task = state.task;
        final mine = task?.assigneeOf(meId);
        final spent = task == null ? 0 : task.expenses.where((e) => e.user.id == meId).fold(0, (s, e) => s + e.amount);
        // The three checklist points: done?, label, trailing detail.
        final checks = [
          (
            mine == null || mine.share == 0 || mine.done >= mine.share,
            TrWords.wCDone,
            mine == null || mine.share == 0 ? null : TrWords.cOf.tr(args: ['${mine.done}', '${mine.share}']),
          ),
          (spent > 0, TrWords.wCExp, spent > 0 ? MoneyFormatter.display(spent) : null),
          (state.photos > 0, TrWords.wCPhotos, TrWords.wAtLeast.tr()),
        ];
        return ScreenShell(
          title: TrWords.tasksSendResult.tr(),
          backIcon: AppIcons.x,
          padding: EdgeInsets.zero,
          bottomBar: Btn(
            text: TrWords.expToReview.tr(),
            icon: AppIcons.send,
            isLoading: state.status.isLoading,
            onPressed: () => bloc.add(const ResultSubmitSent()),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            children: [
              Row(
                children: [
                  AppIcon(AppIcons.tasks, size: 18.sp, color: theme.grayText),
                  8.w.width,
                  Expanded(
                    child: Text(
                      '${bloc.taskId}${task == null ? '' : ' · ${task.title}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.cardSubtitle.copyWith(color: theme.textSecondary),
                    ),
                  ),
                ],
              ),
              16.h.height,
              CardWidget(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, (ok, label, trailing)) in checks.indexed)
                      OptionTile(
                        title: label.tr(),
                        first: i == 0,
                        leading: AppIcon(ok ? AppIcons.checkc : AppIcons.eq, color: ok ? theme.primary : theme.line),
                        trailing: trailing == null ? null : Text(trailing, style: theme.cardSubtitle),
                      ),
                  ],
                ),
              ),
              18.h.height,
              Text(TrWords.wPhotosDocs.tr(), style: theme.fieldLabel),
              6.h.height,
              PhotoStrip(
                count: state.photos,
                onAdd: state.photos < 5 ? () => bloc.add(const ResultSubmitPhotoAdded()) : null,
              ),
              if (state.visiblePhotoError != null)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(state.visiblePhotoError!, style: theme.cardSubtitle.copyWith(color: theme.red)),
                ),
              18.h.height,
              InputBox(title: TrWords.wAbout.tr(), lines: 4, onChanged: (v) => bloc.add(ResultSubmitTextChanged(v))),
              6.h.height,
              Text(TrWords.wWillCheck.tr(), style: theme.cardSubtitle),
            ],
          ),
        );
      },
    );
  }
}
