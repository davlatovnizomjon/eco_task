import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/domain/common/enums/report_period.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/dto/models/dashboard_summary.dart';
import 'package:eco_task/infrastructure/dto/models/paged_list.dart';
import 'package:eco_task/infrastructure/dto/models/report_summary.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';

part 'event.dart';
part 'state.dart';

/// Drives the boss dashboard: loads the summary numbers cache-first and
/// refreshes them on demand.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  /// Data source of the aggregated numbers; owned by the app root.
  final ReportsRepository repository;

  /// Source of the admin's own open tasks.
  final TasksRepository tasks;

  /// Source of the staff and client head counts.
  final TeamRepository team;

  /// Id of the signed-in admin, the assignee of the "my tasks" stack.
  final String meId;

  /// Wires the handlers of the dashboard.
  DashboardBloc({required this.repository, required this.tasks, required this.team, required this.meId})
    : super(const DashboardState()) {
    on<DashboardStarted>((event, emit) => _load(emit, refreshing: false));
    on<DashboardRefreshed>((event, emit) => _load(emit, refreshing: true));
  }

  /// Emits the cached summary first (if any), then the fresh one. An error keeps
  /// a cached summary on screen and only surfaces the failure.
  Future<void> _load(Emitter<DashboardState> emit, {required bool refreshing}) async {
    final cached = repository.cachedDashboard();
    emit(
      state.copyWith(
        summary: cached,
        refreshing: refreshing,
        status: cached == null ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      final mine = TaskQuery(who: meId, statuses: {TaskStatus.fresh, TaskStatus.prog});
      final results = await Future.wait<Object>([
        repository.getDashboard(),
        repository.getReport(ReportPeriod.week),
        tasks.getTasks(mine),
        team.getUsers(clients: false),
        team.getUsers(clients: true),
      ]);
      emit(
        state.copyWith(
          summary: results[0] as DashboardSummary,
          week: results[1] as ReportSummary,
          mine: (results[2] as PagedList<TaskModel>).items,
          staffTotal: (results[3] as PagedList<AppUser>).total,
          clientTotal: (results[4] as PagedList<AppUser>).total,
          status: ScreenStatus.success,
          refreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: state.summary == null ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
