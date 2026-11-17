import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/list_row.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/tone_circle.dart';
import 'package:eco_task/presentation/public/widgets/underline_tabs.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';

/// Every task of one staff member: the title carries their name, three tabs (all, done, failed) narrow the flat list,
/// each row shows the status marker, the title, the status word and the deadline day. Provides [EmployeeTasksBloc].
class EmployeeTasksScreen extends StatelessWidget {
  /// Id of the staff member.
  final String userId;

  /// Builds the screen.
  const EmployeeTasksScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          EmployeeTasksBloc(repository: RepositoryProvider.of<TasksRepository>(ctx), userId: userId)
            ..add(const EmployeeTasksStarted()),
      child: _EmployeeTasksView(userId: userId),
    );
  }
}

/// Renders the tabs and the list for the current state.
class _EmployeeTasksView extends StatelessWidget {
  /// Id of the staff member, to look up their name for the title.
  final String userId;

  /// Builds the view.
  const _EmployeeTasksView({required this.userId});

  /// Empty state of tab [tab].
  EmptyView _empty(int tab) => switch (tab) {
    1 => EmptyView.tile(icon: AppIcons.checkc, title: TrWords.emEDoneT.tr(), message: TrWords.emEDoneD.tr()),
    2 => EmptyView.tile(
      icon: AppIcons.xc,
      tone: StatusTone.error,
      title: TrWords.emEFailT.tr(),
      message: TrWords.emEFailD.tr(),
    ),
    _ => EmptyView.tile(icon: AppIcons.tasks, title: TrWords.emEAllT.tr(), message: TrWords.emEAllD.tr()),
  };

  @override
  Widget build(BuildContext context) {
    /// The member's name for the title; the list screen reads it from the cached directory when known.
    final name =
        RepositoryProvider.of<TeamRepository>(context)
            .cachedUsers(clients: false)
            .items
            .where((u) => u.id == userId)
            .firstOrNull
            ?.name ??
        '';
    return BlocConsumer<EmployeeTasksBloc, EmployeeTasksState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        /// Bloc of this screen.
        final bloc = context.read<EmployeeTasksBloc>();
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(title: name.isEmpty ? TrWords.emTasks.tr() : TrWords.emTasksOf.tr(args: [name])),
              UnderlineTabs(
                labels: [TrWords.emAll.tr(), TrWords.emDone.tr(), TrWords.emFailed.tr()],
                selected: state.tab,
                onChanged: (i) => bloc.add(EmployeeTasksTabChanged(i)),
              ),
              Expanded(
                child: state.status.isLoading && state.items.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 5))
                    : RefreshList(
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h + MediaQuery.of(context).padding.bottom),
                        gap: 0,
                        onRefresh: () async {
                          bloc.add(const EmployeeTasksRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        placeholder: state.status == ScreenStatus.error
                            ? EmptyView.tile(
                                icon: AppIcons.wifioff,
                                tone: StatusTone.warn,
                                title: TrWords.cLoadFailed.tr(),
                                message: TrWords.cLoadFailedDesc.tr(),
                                onRetry: () => bloc.add(const EmployeeTasksStarted()),
                              )
                            : _empty(state.tab),
                        children: [
                          for (final (i, t) in state.visible.indexed)
                            ListRow(
                              first: i == 0,
                              chevron: false,
                              titleSize: 15,
                              leading: ToneCircle(t.status.icon, tone: t.status.tone),
                              title: t.title,
                              subtitle: t.status.title,
                              trailing: Text(
                                DateFormatter.dayShort(t.due),
                                style: theme.textStyle.copyWith(fontSize: 13.sp, color: theme.textSecondary),
                              ),
                              onTap: () => context.push(Routes.taskDetail.of(t.id)),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
