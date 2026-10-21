import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_assignee.dart';
import 'package:eco_task/infrastructure/dto/models/task_draft.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';
import 'package:eco_task/domain/common/enums/task_priority.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';

part 'event.dart';
part 'state.dart';

/// Drives the create/edit task form: loads the people who can be assigned (and
/// the task when editing), keeps every typed value, validates on submit and
/// saves through [TasksRepository].
class TaskFormBloc extends Bloc<TaskFormEvent, TaskFormState> {
  /// Data source of task writes; owned by the app root.
  final TasksRepository tasks;

  /// Data source of the assignable people; owned by the app root.
  final TeamRepository team;

  /// Id of the task being edited, or null when creating a new one.
  final String? editId;

  /// Wires the handlers of the form.
  TaskFormBloc({required this.tasks, required this.team, this.editId}) : super(TaskFormState(due: _defaultDue())) {
    on<TaskFormStarted>(_onStarted);
    on<TaskFormTitleChanged>((event, emit) => emit(state.copyWith(title: event.value)));
    on<TaskFormAssigneesChanged>(_onAssignees);
    on<TaskFormSplitToggled>((event, emit) => emit(state.copyWith(split: event.value)));
    on<TaskFormShareChanged>(
      (event, emit) => emit(state.copyWith(shares: {...state.shares, event.userId: event.value})),
    );
    on<TaskFormDueChanged>((event, emit) => emit(state.copyWith(due: event.value)));
    on<TaskFormPriorityChanged>((event, emit) => emit(state.copyWith(priority: event.value)));
    on<TaskFormRewardChanged>((event, emit) => emit(state.copyWith(reward: event.value)));
    on<TaskFormDescriptionChanged>((event, emit) => emit(state.copyWith(description: event.value)));
    on<TaskFormExpectedChanged>((event, emit) => emit(state.copyWith(expected: event.value)));
    on<TaskFormSubmitted>(_onSubmitted);
  }

  /// Tomorrow at 18:00 — the deadline a new task starts with.
  static DateTime _defaultDue() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 18);
  }

  /// Loads the assignable people and, when editing, fills the form from the task.
  Future<void> _onStarted(TaskFormStarted event, Emitter<TaskFormState> emit) async {
    emit(state.copyWith(status: ScreenStatus.loading));
    try {
      final people = await team.getUsers(clients: false);
      if (editId == null) {
        emit(state.copyWith(status: ScreenStatus.success, candidates: people.items));
        return;
      }
      final task = await tasks.getTask(editId!);
      emit(
        state.copyWith(
          status: ScreenStatus.success,
          candidates: people.items,
          title: task.title,
          assignees: [for (final a in task.assignees) a.user],
          split: task.totalShare > 0,
          shares: {for (final a in task.assignees) a.userId: a.share == 0 ? '' : '${a.share}'},
          due: task.due,
          priority: task.priority,
          reward: task.reward == 0 ? '' : MoneyFormatter.number(task.reward),
          description: task.description,
          expected: task.expected,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: ScreenStatus.error, response: e is ScreenResponse ? e : const UnExpectedErrorResponse()),
      );
    }
  }

  /// Replaces the assignee list with the picked ids, keeping typed quotas.
  void _onAssignees(TaskFormAssigneesChanged event, Emitter<TaskFormState> emit) {
    emit(state.copyWith(assignees: event.people));
  }

  /// Validates, then creates or edits the task. A failed validation emits the
  /// FIRST invalid field's message and flips `showErrors`; nothing is sent.
  Future<void> _onSubmitted(TaskFormSubmitted event, Emitter<TaskFormState> emit) async {
    final invalid = state.titleError ?? state.assigneesError;
    if (invalid != null) {
      emit(state.copyWith(showErrors: true, response: MessageErrorResponse(invalid)));
      return;
    }
    emit(state.copyWith(status: ScreenStatus.loading, showErrors: true, saved: false));
    final draft = TaskDraft(
      title: state.title.trim(),
      due: state.due,
      priority: state.priority,
      reward: MoneyFormatter.parse(state.reward),
      description: state.description.trim(),
      expected: state.expected.trim(),
      assignees: [
        for (final p in state.assignees)
          TaskAssignee(user: p, share: state.split ? int.tryParse(state.shares[p.id] ?? '') ?? 0 : 0),
      ],
    );
    try {
      editId == null ? await tasks.createTask(draft) : await tasks.editTask(editId!, draft);
      emit(state.copyWith(status: ScreenStatus.success, saved: true));
    } catch (e) {
      emit(
        state.copyWith(
          status: ScreenStatus.success,
          response: e is ScreenResponse ? e : const UnExpectedErrorResponse(),
        ),
      );
    }
  }
}
