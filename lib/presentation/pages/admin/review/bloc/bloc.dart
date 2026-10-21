import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/expenses_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/dto/models/expense_entry.dart';

part 'event.dart';
part 'state.dart';

/// Drives the approval queue: results waiting for review and pending expenses,
/// both loaded together cache-first, with approve and return actions.
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  /// Data source of task reads and writes; owned by the app root.
  final TasksRepository tasks;

  /// Data source of the pending expenses; owned by the app root.
  final ExpensesRepository expenses;

  /// The tasks waiting for a decision.
  static const _reviewQuery = TaskQuery(statuses: {TaskStatus.rev});

  /// Wires the handlers of the queue.
  ReviewBloc({required this.tasks, required this.expenses}) : super(const ReviewState()) {
    on<ReviewStarted>((event, emit) => _load(emit, refreshing: false));
    on<ReviewRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<ReviewTabChanged>((event, emit) => emit(state.copyWith(tab: event.tab)));
    on<ReviewApproved>((event, emit) => _act(emit, () => tasks.approve(event.taskId)));
    on<ReviewReturned>(
      (event, emit) =>
          _act(emit, () => tasks.returnForRework(event.taskId, reason: event.reason, extend: event.extend)),
    );
  }

  /// Emits cached results/expenses first, then both fresh lists. An error keeps
  /// cached data on screen and only surfaces the failure.
  Future<void> _load(Emitter<ReviewState> emit, {required bool refreshing}) async {
    final cachedTasks = tasks.cachedTasks(_reviewQuery).items;
    final cachedExpenses = expenses.cachedExpenses('pending').items;
    final hasCache = cachedTasks.isNotEmpty || cachedExpenses.isNotEmpty;
    emit(
      state.copyWith(
        results: cachedTasks,
        pending: cachedExpenses,
        refreshing: refreshing,
        status: hasCache ? ScreenStatus.success : ScreenStatus.loading,
      ),
    );
    try {
      final (freshTasks, freshExpenses) = await (tasks.getTasks(_reviewQuery), expenses.getExpenses('pending')).wait;
      emit(
        state.copyWith(
          results: freshTasks.items,
          pending: freshExpenses.items,
          status: ScreenStatus.success,
          refreshing: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: hasCache ? ScreenStatus.success : ScreenStatus.error,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }

  /// Runs one decision and reloads the queue so the handled row disappears.
  Future<void> _act(Emitter<ReviewState> emit, Future<TaskModel> Function() action) async {
    emit(state.copyWith(busy: true));
    try {
      await action();
      emit(state.copyWith(busy: false));
      await _load(emit, refreshing: false);
    } catch (e) {
      emit(state.copyWith(busy: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
