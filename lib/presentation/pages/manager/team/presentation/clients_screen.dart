import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/header_action.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/list_row.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/search_field.dart';
import 'package:eco_task/presentation/public/widgets/underline_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

import '../bloc/bloc.dart';

/// Pushed clients list of the manager: search, an all / with-requests / without-requests switch and one row per
/// client with the address and the active-request count. Provides [TeamBloc] switched to client mode.
class ClientsScreen extends StatelessWidget {
  /// Builds the screen.
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          TeamBloc(repository: RepositoryProvider.of<TeamRepository>(ctx))..add(const TeamTabChanged(clients: true)),
      child: const _ClientsView(),
    );
  }
}

/// Renders the bar, the search row, the switch and the rows.
class _ClientsView extends StatefulWidget {
  /// Builds the view.
  const _ClientsView();

  @override
  State<_ClientsView> createState() => _ClientsViewState();
}

/// Owns the search debounce and the switch.
class _ClientsViewState extends State<_ClientsView> {
  /// Delays the search request until typing pauses.
  Timer? _debounce;

  /// Search text controller.
  final _search = TextEditingController();

  /// Selected switch segment: 0 all, 1 with active requests, 2 without requests.
  /// Selected tab: 0 all, 1 private persons, 2 organizations.
  int _tab = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Clients of the selected tab.
  List<AppUser> _visible(List<AppUser> all) => [
    for (final u in all)
      if (switch (_tab) {
        1 => !u.isOrg,
        2 => u.isOrg,
        _ => true,
      })
        u,
  ];

  /// Empty state of the selected tab.
  EmptyView _empty() => switch (_tab) {
    1 => EmptyView.tile(icon: AppIcons.user, title: TrWords.tmEPersonT.tr(), message: TrWords.tmEPersonD.tr()),
    2 => EmptyView.tile(icon: AppIcons.building, title: TrWords.tmEOrgT.tr(), message: TrWords.tmEOrgD.tr()),
    _ => EmptyView.tile(icon: AppIcons.users, title: TrWords.tmEClAllT.tr(), message: TrWords.tmEClAllD.tr()),
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamBloc, TeamState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<TeamBloc>();
        final people = _visible(state.items);
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(
                title: TrWords.dashClients.tr(),
                actions: [
                  HeaderAction(
                    icon: AppIcons.plus,
                    onTap: () =>
                        context.push('${Routes.memberForm.path}?client=1').then((_) => bloc.add(const TeamRefreshed())),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: SearchField(
                  hint: TrWords.tmSearch.tr(),
                  controller: _search,
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () => bloc.add(TeamSearchChanged(v)));
                  },
                ),
              ),
              UnderlineTabs(
                labels: [TrWords.cAll.tr(), TrWords.tmTabPerson.tr(), TrWords.tmTabOrg.tr()],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              Expanded(
                child: state.items.isEmpty && state.status.isLoading
                    ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3))
                    : RefreshList(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
                        gap: 0,
                        onRefresh: () async {
                          bloc.add(const TeamRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        onLoadMore: () => bloc.add(const TeamMoreRequested()),
                        isLoadingMore: state.isLoadingMore,
                        placeholder: state.status.isError
                            ? EmptyView(
                                title: TrWords.cLoadFailed.tr(),
                                message: TrWords.cLoadFailedDesc.tr(),
                                icon: AppIcons.alert,
                                onRetry: () => bloc.add(const TeamTabChanged(clients: true)),
                              )
                            : _empty(),
                        children: [
                          for (final (i, u) in people.indexed)
                            ListRow(
                              first: i == 0,
                              dividerInset: 52,
                              chevron: false,
                              leading: UserAvatar(u.ref, size: 40.w),
                              title: u.name,
                              titleSize: 15,
                              subtitle: PhoneFormatter.display(u.phone),
                              subtitleColor: theme.textSecondary,
                              trailing: Text(
                                u.activeCount == 0
                                    ? TrWords.tmNoRequests.tr()
                                    : TrWords.tmNRequests.tr(args: ['${u.activeCount}']),
                                style: theme.textStyle.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: u.activeCount == 0 ? FontWeight.w400 : FontWeight.w700,
                                  color: u.activeCount == 0 ? theme.grayText : theme.text,
                                ),
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
