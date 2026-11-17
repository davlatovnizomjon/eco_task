import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/bottom_action_bar.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/infrastructure/repository/files_repository.dart';
import 'package:eco_task/presentation/public/dialogs/pick_source_sheet.dart';
import 'package:eco_task/presentation/public/widgets/auth_image.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

import '../bloc/bloc.dart';
import 'dialogs/member_picker_sheet.dart';

/// Edit page of a group: the title field, the member list (each with a red minus, the caller's own row without one)
/// and "add member", saved with one button. Provides [GroupEditBloc].
class GroupEditScreen extends StatelessWidget {
  /// Id of the group to edit.
  final String conversationId;

  /// Builds the page.
  const GroupEditScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => GroupEditBloc(
        repository: RepositoryProvider.of<ChatRepository>(ctx),
        files: RepositoryProvider.of<FilesRepository>(ctx),
        conversationId: conversationId,
      )..add(const GroupEditStarted()),
      child: const _GroupEditView(),
    );
  }
}

/// Owns the title controller and renders the page.
class _GroupEditView extends StatefulWidget {
  /// Builds the view.
  const _GroupEditView();

  @override
  State<_GroupEditView> createState() => _GroupEditViewState();
}

/// Fills the title controller once when the group arrives.
class _GroupEditViewState extends State<_GroupEditView> {
  /// Controller of the title field.
  final _title = TextEditingController();

  /// True after the loaded title was copied into the controller.
  bool _filled = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Id of the signed-in person, whose own row has no minus.
    final meId = RepositoryProvider.of<SessionRepository>(context).user.value!.user.id;
    return BlocConsumer<GroupEditBloc, GroupEditState>(
      listenWhen: (prev, cur) => cur.response != null || cur.saved || (!_filled && cur.original != null),
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.saved) context.pop(true);
        if (!_filled && state.original != null) {
          _filled = true;
          _title.text = state.title;
        }
      },
      builder: (context, state) {
        /// Bloc of this page.
        final bloc = context.read<GroupEditBloc>();
        if (state.original == null) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Column(
              children: [
                InnerBar(title: TrWords.ch2EditGroup.tr()),
                Expanded(
                  child: state.status == ScreenStatus.error
                      ? EmptyView.tile(
                          icon: AppIcons.wifioff,
                          tone: StatusTone.warn,
                          title: TrWords.cLoadFailed.tr(),
                          message: TrWords.cLoadFailedDesc.tr(),
                          onRetry: () => bloc.add(const GroupEditStarted()),
                        )
                      : const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 2)),
                ),
              ],
            ),
          );
        }

        /// People who could still be added: candidates not already in the draft.
        final addable = [
          for (final c in state.candidates)
            if (!state.members.any((m) => m.id == c.id)) c,
        ];
        return Scaffold(
          backgroundColor: theme.background,
          bottomNavigationBar: BottomActionBar(
            child: Btn(
              text: TrWords.cSave.tr(),
              height: 52.h,
              isLoading: state.busy,
              onPressed: () => bloc.add(const GroupEditSaved()),
            ),
          ),
          body: Column(
            children: [
              InnerBar(title: TrWords.ch2EditGroup.tr()),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: state.uploading
                            ? null
                            : () async {
                                final picked = await PickSourceSheet.show(context, documents: false);
                                if (picked.isNotEmpty) bloc.add(GroupEditPhotoPicked(picked.first));
                              },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            SizedBox(
                              width: 96.w,
                              height: 96.w,
                              child: (state.photo ?? state.original?.avatar) != null
                                  ? AuthImage((state.photo ?? state.original!.avatar)!.id, radius: 48.w)
                                  : AppIcon.tile(AppIcons.users, tone: StatusTone.primary, size: 96),
                            ),
                            Container(
                              width: 30.w,
                              height: 30.w,
                              decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: state.uploading
                                  ? SizedBox(
                                      width: 14.w,
                                      height: 14.w,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.onPrimary),
                                    )
                                  : AppIcon(AppIcons.camera, size: 16.sp, color: theme.onPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    20.h.height,
                    InputBox(
                      controller: _title,
                      title: TrWords.ch2GroupName.tr(),
                      errorText: state.showErrors && state.title.trim().isEmpty ? TrWords.formNeedsName.tr() : null,
                      onChanged: (v) => bloc.add(GroupEditTitleChanged(v)),
                    ),
                    16.h.height,
                    Text(TrWords.ch2Members.tr(), style: theme.fieldLabel),
                    6.h.height,
                    CardWidget(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                      decoration: theme.panelDecor,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              /// People picked in the sheet; null when dismissed.
                              final picked = await MemberPickerSheet.show(context, addable);
                              if (picked != null) bloc.add(GroupEditMembersAdded(picked));
                            },
                            child: Container(
                              constraints: BoxConstraints(minHeight: 60.h),
                              child: Row(
                                children: [
                                  AppIcon.tile(AppIcons.plus, tone: StatusTone.primary, size: 40),
                                  12.w.width,
                                  Text(
                                    TrWords.ch2AddMember.tr(),
                                    style: theme.textStyle.copyWith(fontWeight: FontWeight.w600, color: theme.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          for (final m in state.members)
                            Container(
                              constraints: BoxConstraints(minHeight: 60.h),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: theme.line)),
                              ),
                              child: Row(
                                children: [
                                  UserAvatar(m, size: 40.w),
                                  12.w.width,
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textStyle,
                                    ),
                                  ),
                                  if (m.role != null) ...[RolePill(m.role!), 10.w.width],
                                  if (m.id == meId)
                                    SizedBox(width: 26.w)
                                  else
                                    GestureDetector(
                                      onTap: () => bloc.add(GroupEditMemberRemoved(m.id)),
                                      child: Container(
                                        width: 26.w,
                                        height: 26.w,
                                        decoration: BoxDecoration(color: theme.redBg, shape: BoxShape.circle),
                                        child: Icon(Icons.remove, size: 16.sp, color: theme.red),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
