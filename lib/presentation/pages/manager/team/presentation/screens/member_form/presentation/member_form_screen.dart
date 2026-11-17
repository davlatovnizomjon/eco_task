import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/dialogs/public_dialog.dart';
import 'package:eco_task/presentation/public/widgets/dialog_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/bottom_action_bar.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/select_mark.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/underline_tabs.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Open a staff (or, with [client], a client) account. Provides
/// [MemberFormBloc] over the app-wide [TeamRepository].
class MemberFormScreen extends StatelessWidget {
  /// True when a client account is being opened.
  final bool client;

  /// Id of the account being edited; null when opening a new one.
  final String? editId;

  /// Builds the form screen.
  const MemberFormScreen({super.key, required this.client, this.editId});

  @override
  Widget build(BuildContext context) {
    final team = RepositoryProvider.of<SessionRepository>(context).user.value!.user.team;
    return BlocProvider(
      create: (ctx) {
        final bloc = MemberFormBloc(
          repository: RepositoryProvider.of<TeamRepository>(ctx),
          client: client,
          team: team,
          editId: editId,
        );
        if (editId != null) bloc.add(const MemberFormStarted());
        return bloc;
      },
      child: const _MemberFormView(),
    );
  }
}

/// Renders the account fields and the credentials dialog after creation.
class _MemberFormView extends StatefulWidget {
  /// Builds the form body.
  const _MemberFormView();

  @override
  State<_MemberFormView> createState() => _MemberFormViewState();
}

/// Owns the controllers that carry the loaded account's values in edit mode.
class _MemberFormViewState extends State<_MemberFormView> {
  /// Controllers of the text fields that are prefilled when editing.
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _contact, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MemberFormBloc>();
    final editing = bloc.editId != null;
    return BlocConsumer<MemberFormBloc, MemberFormState>(
      listenWhen: (prev, cur) => cur.response != null || cur.created != null || prev.seed != cur.seed,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        final seed = state.seed;
        if (seed != null && _name.text.isEmpty) {
          _name.text = seed.name;
          _phone.text = PhoneFormatter.display(seed.phone);
          _address.text = seed.team;
          _contact.text = seed.contactPerson;
          _note.text = seed.note;
        }
        final created = state.created;
        if (created == null) return;
        if (editing) {
          context.pop(true);
          return;
        }
        // Hand-over dialog: the boss shares these two values with the new user.
        showCenterDialog(
          PublicDialog(
            icon: DialogIcon.green(),
            title: TrWords.teamCreated.tr(),
            subTitle: '${TrWords.teamLogin.tr()}: ${created.id}\n${TrWords.teamTempPwd.tr()}: ${state.password}',
            warningText: TrWords.teamShareCreds.tr(),
            onActiveBtnPressed: () => context.pop(),
          ),
          context,
          isCancelable: false,
        );
      },
      builder: (context, state) => editing && state.seed == null
          ? Scaffold(
              backgroundColor: theme.background,
              body: Column(
                children: [
                  InnerBar(title: (bloc.client ? TrWords.teamEditClient : TrWords.teamEditEmp).tr()),
                  Expanded(
                    child: state.status.isError
                        ? EmptyView(
                            title: TrWords.cLoadFailed.tr(),
                            message: TrWords.cLoadFailedDesc.tr(),
                            icon: AppIcons.alert,
                            onRetry: () => bloc.add(const MemberFormStarted()),
                          )
                        : const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3)),
                  ),
                ],
              ),
            )
          : Scaffold(
              backgroundColor: theme.background,
              bottomNavigationBar: BottomActionBar(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!editing) ...[
                      Text(TrWords.teamShareCreds.tr(), textAlign: TextAlign.center, style: theme.cardSubtitle),
                      8.h.height,
                    ],
                    Btn(
                      text: bloc.client && !editing ? TrWords.teamOpenClient.tr() : TrWords.cSave.tr(),
                      isLoading: state.status.isLoading,
                      onPressed: () => bloc.add(const MemberFormSubmitted()),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  InnerBar(
                    title: editing
                        ? (bloc.client ? TrWords.teamEditClient : TrWords.teamEditEmp).tr()
                        : bloc.client
                        ? TrWords.teamAddClient.tr()
                        : TrWords.teamAddEmp.tr(),
                  ),
                  if (bloc.client)
                    UnderlineTabs(
                      labels: [TrWords.tmTabPerson.tr(), TrWords.tmTabOrg.tr()],
                      selected: state.isOrg ? 1 : 0,
                      onChanged: (i) => bloc.add(MemberFormOrgChanged(isOrg: i == 1)),
                    ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                      children: [
                        InputBox(
                          controller: _name,
                          title: (bloc.client && state.isOrg ? TrWords.tmTabOrg : TrWords.teamFullName).tr(),
                          errorText: state.visibleNameError,
                          onChanged: (v) => bloc.add(MemberFormNameChanged(v)),
                        ),
                        16.h.height,
                        InputBox(
                          controller: _phone,
                          title: TrWords.teamPhone.tr(),
                          hint: '+998 90 123 45 67',
                          leftIcon: AppIcons.phone,
                          inputType: TextInputType.phone,
                          inputFormatters: const [PhoneInputFormatter()],
                          errorText: state.visiblePhoneError,
                          onChanged: (v) => bloc.add(MemberFormPhoneChanged(v)),
                        ),
                        if (!editing) ...[
                          16.h.height,
                          InputBox(
                            title: TrWords.teamLogin.tr(),
                            errorText: state.visibleLoginError,
                            onChanged: (v) => bloc.add(MemberFormLoginChanged(v)),
                          ),
                          16.h.height,
                          Text(TrWords.teamTempPwd.tr(), style: theme.fieldLabel),
                          6.h.height,
                          CardWidget(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(state.password, style: theme.cardTitle.copyWith(letterSpacing: 1)),
                                ),
                                Btn.ghost(
                                  text: TrWords.teamRegen.tr(),
                                  icon: AppIcons.refresh,
                                  onPressed: () => bloc.add(const MemberFormPasswordRegenerated()),
                                ),
                              ],
                            ),
                          ),
                          6.h.height,
                          Text(TrWords.teamPwdHelp.tr(), style: theme.cardSubtitle),
                        ],
                        16.h.height,
                        if (bloc.client) ...[
                          InputBox(
                            controller: _address,
                            title: TrWords.teamAddressOpt.tr(),
                            leftIcon: AppIcons.pin,
                            onChanged: (v) => bloc.add(MemberFormAddressChanged(v)),
                          ),
                          if (state.isOrg) ...[
                            16.h.height,
                            InputBox(
                              controller: _contact,
                              title: TrWords.teamContact.tr(),
                              leftIcon: AppIcons.user,
                              onChanged: (v) => bloc.add(MemberFormContactChanged(v)),
                            ),
                          ],
                          16.h.height,
                          InputBox(
                            controller: _note,
                            title: TrWords.teamNote.tr(),
                            lines: 3,
                            onChanged: (v) => bloc.add(MemberFormNoteChanged(v)),
                          ),
                        ] else if (!editing) ...[
                          Text(TrWords.teamRole.tr(), style: theme.fieldLabel),
                          6.h.height,
                          CardWidget(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final (i, role) in [UserRole.worker].indexed)
                                  OptionTile(
                                    title: role.title,
                                    first: i == 0,
                                    onTap: () => bloc.add(MemberFormRoleChanged(role)),
                                    trailing: SelectMark(shape: SelectShape.radio, on: state.role == role),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
