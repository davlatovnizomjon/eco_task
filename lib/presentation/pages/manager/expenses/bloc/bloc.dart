import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/repository/expenses_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/dto/models/expense_entry.dart';
import 'package:eco_task/infrastructure/dto/models/expense_totals.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';

part 'event.dart';
part 'state.dart';

/// Drives the expenses screen: money totals, the filtered expense list, the
/// reward payouts, and the "mark as paid" actions.
class ExpensesBloc extends Bloc<ExpensesEvent, ExpensesState> {
  /// Data source of expenses; owned by the app root.
  final ExpensesRepository expenses;

  /// Data source of the reward payouts (completed tasks); owned by the app root.
  final TasksRepository tasks;

  /// API keys of the four filter tabs, in tab order.
  static const filters = ['pending', 'approved', 'rejected', 'paid'];

  /// Completed tasks, whose rewards the payouts section lists.
  static const _doneQuery = TaskQuery(statuses: {TaskStatus.done});

  /// Wires the handlers of the screen.
  ExpensesBloc({required this.expenses, required this.tasks}) : super(const ExpensesState()) {
    on<ExpensesStarted>((event, emit) => _load(emit, refreshing: false));
    on<ExpensesRefreshed>((event, emit) => _load(emit, refreshing: true));
    on<ExpensesFilterChanged>((event, emit) {
      emit(state.copyWith(filter: event.filter, items: const []));
      return _load(emit, refreshing: false);
    });
    on<ExpensesMoreRequested>(_onMore);
    on<ExpensePaid>((event, emit) => _pay(emit, () => expenses.pay(event.taskId, event.expenseId)));
    on<ExpenseRewardPaid>((event, emit) => _pay(emit, () => tasks.payReward(event.taskId)));
  }

  /// Loads totals, page 1 of the selected tab and the payouts together. Cached
  /// values are emitted first; an error keeps them on screen.
  Future<void> _load(Emitter<ExpensesState> emit, {required bool refreshing}) async {
    final filter = state.filter;
    final cached = expenses.cachedExpenses(filters[filter]);
    final cachedTotals = expenses.cachedTotals();
    emit(
      state.copyWith(
        items: cached.items,
        page: cached.page,
        lastPage: cached.lastPage,
        totals: cachedTotals,
        refreshing: refreshing,
        status: cachedTotals == null ? ScreenStatus.loading : ScreenStatus.success,
      ),
    );
    try {
      final (list, totals, done) = await (
        expenses.getExpenses(filters[filter]),
        expenses.getTotals(),
        tasks.getTasks(_doneQuery),
      ).wait;
      if (state.filter != filter) return;
      emit(
        state.copyWith(
          items: list.items,
          page: list.page,
          lastPage: list.lastPage,
          totals: totals,
          rewards: [
            for (final t in done.items)
              if (t.reward > 0) t,
          ],
          status: ScreenStatus.success,
          refreshing: false,
        ),
      );
    } catch (e) {
      if (state.filter != filter) return;
      emit(
        state.copyWith(
          status: state.totals == null ? ScreenStatus.error : ScreenStatus.success,
          refreshing: false,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }

  /// Appends the next page of the selected tab; ignored while a fetch runs or
  /// on the last page.
  Future<void> _onMore(ExpensesMoreRequested event, Emitter<ExpensesState> emit) async {
    if (state.isLoadingMore || state.status.isLoading || state.page >= state.lastPage) return;
    final filter = state.filter;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final next = await expenses.getExpenses(filters[filter], page: state.page + 1);
      if (state.filter != filter) return;
      emit(
        state.copyWith(
          items: [...state.items, ...next.items],
          page: next.page,
          lastPage: next.lastPage,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }

  /// Runs one payout request, then reloads so totals and tabs stay consistent.
  Future<void> _pay(Emitter<ExpensesState> emit, Future<Object?> Function() action) async {
    try {
      await action();
      await _load(emit, refreshing: false);
    } catch (e) {
      emit(state.copyWith(response: e is ScreenResponse ? e : const UnExpectedErrorResponse()));
    }
  }
}
