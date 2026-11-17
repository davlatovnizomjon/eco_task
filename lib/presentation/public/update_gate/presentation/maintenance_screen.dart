import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/presentation/pages/_auth/presentation/dialogs/support/support_sheet.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';

import '../bloc/bloc.dart';

/// Full-screen "technical work in progress" wall shown while the version endpoint answers with a server error. It
/// covers every screen of the app; its actions are trying again and contacting the dispatcher. The wall sits above the
/// app's router, so it brings its own [Navigator]: the dispatcher sheet opens inside it and stays visible.
class MaintenanceScreen extends StatelessWidget {
  /// Builds the wall.
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const _MaintenanceBody(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

/// The wall's content; it reads the update bloc so the retry button follows the request.
class _MaintenanceBody extends StatelessWidget {
  /// Builds the content.
  const _MaintenanceBody();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: 32.w.horizontal,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 168.w,
                        height: 168.w,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: theme.primaryTint.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              margin: 22.w.all,
                              decoration: BoxDecoration(
                                color: theme.primaryTint.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 84.w,
                              height: 84.w,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.primary,
                                borderRadius: 26.circular,
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 12),
                                    blurRadius: 28,
                                    color: theme.primary.withValues(alpha: 0.35),
                                  ),
                                ],
                              ),
                              child: AppIcon(AppIcons.tool, size: 40.sp, color: theme.onPrimary),
                            ),
                          ],
                        ),
                      ),
                      26.h.height,
                      Text(
                        TrWords.maintTitle.tr(),
                        textAlign: TextAlign.center,
                        style: theme.textStyle.copyWith(
                          fontSize: 22.sp,
                          height: 28 / 22,
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation.weight(650)],
                          letterSpacing: -0.22,
                        ),
                      ),
                      14.h.height,
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 300.w),
                        child: Text(
                          TrWords.maintBody.tr(),
                          textAlign: TextAlign.center,
                          style: theme.textStyle.copyWith(
                            fontWeight: FontWeight.w400,
                            height: 22 / 15,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 36.h),
              child: BlocBuilder<UpdateBloc, UpdateState>(
                buildWhen: (previous, current) => previous.retrying != current.retrying,
                builder: (context, state) => Column(
                  children: [
                    Btn(
                      text: TrWords.cRetry.tr(),
                      icon: AppIcons.refresh,
                      height: 48.h,
                      isLoading: state.retrying,
                      onPressed: state.retrying ? null : () => context.read<UpdateBloc>().add(const UpdateRequested()),
                    ),
                    8.h.height,
                    Btn.unActive(
                      text: TrWords.supportTitle.tr(),
                      icon: AppIcons.headset,
                      height: 48.h,
                      onPressed: () => showBottomDialog(const SupportSheet(), context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
