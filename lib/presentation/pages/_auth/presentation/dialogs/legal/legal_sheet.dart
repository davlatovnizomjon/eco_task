import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/legal_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/infrastructure/dto/models/legal_document.dart';
import 'package:eco_task/infrastructure/repository/legal_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/app_loader.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import 'bloc/bloc.dart';

/// Opens the tall legal-text sheet for [kind] (terms of use or privacy policy). The text comes from the backend: a spinner
/// while it loads, an empty panel when none is published and a retry panel when the request fails. The sheet rises to
/// 96 px below the top of the screen.
Future<void> showLegalSheet(BuildContext context, LegalKind kind) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: theme.dialogBackground,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: 24.circularRadius)),
  builder: (sheetContext) => BlocProvider(
    create: (_) =>
        LegalBloc(repository: RepositoryProvider.of<LegalRepository>(sheetContext), kind: kind)
          ..add(const LegalStarted()),
    child: _LegalSheet(kind: kind),
  ),
);

/// Body of the legal-text sheet.
class _LegalSheet extends StatelessWidget {
  /// Which text is shown; its default title stands in until the real one arrives.
  final LegalKind kind;

  /// Builds the sheet body.
  const _LegalSheet({required this.kind});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LegalBloc, LegalState>(
      builder: (context, state) {
        final document = state.document;
        final title = document?.title.isNotEmpty == true
            ? document!.title
            : (kind == LegalKind.terms ? TrWords.loginTerms : TrWords.loginPrivacy).tr();
        return SizedBox(
          height: MediaQuery.of(context).size.height - 96.h,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 10.h, bottom: 4.h),
                width: 40.w,
                height: 5.h,
                decoration: BoxDecoration(color: theme.line, borderRadius: 3.circular),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 12.w, 12.h),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textStyle.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 44.w,
                        height: 44.w,
                        child: Center(
                          child: AppIcon(AppIcons.x, size: 20.sp, color: theme.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _Body(state: state)),
            ],
          ),
        );
      },
    );
  }
}

/// Switches between the loading, error, empty and text views under the header.
class _Body extends StatelessWidget {
  /// Current state of the sheet.
  final LegalState state;

  /// Builds the body.
  const _Body({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status.isError) {
      return EmptyView(
        title: TrWords.cLoadFailed.tr(),
        message: TrWords.cLoadFailedDesc.tr(),
        icon: AppIcons.alert,
        onRetry: () => context.read<LegalBloc>().add(const LegalStarted()),
      );
    }
    if (!state.status.isSuccess) return const Center(child: AppLoader());
    final document = state.document;
    if (document == null || document.sections.isEmpty) {
      return EmptyView(title: TrWords.legalEmpty.tr(), message: TrWords.legalEmptyDesc.tr(), icon: AppIcons.board);
    }
    return _Sections(sections: document.sections, updatedAt: document.updatedAt);
  }
}

/// The numbered parts of the text, scrolling.
class _Sections extends StatelessWidget {
  /// Parts in order.
  final List<LegalSection> sections;

  /// When the text was last changed; written under the last part.
  final DateTime updatedAt;

  /// Builds the list.
  const _Sections({required this.sections, required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h + ScreenSize.bottomInset(context)),
      children: [
        for (final (i, section) in sections.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.heading.isNotEmpty) ...[
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${i + 1}.   ',
                          style: TextStyle(color: theme.primary, fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                        TextSpan(text: section.heading),
                      ],
                    ),
                    style: theme.textStyle.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      fontVariations: const [FontVariation.weight(650)],
                    ),
                  ),
                  4.h.height,
                ],
                Text(
                  section.body,
                  style: theme.textStyle.copyWith(
                    fontSize: 14.sp,
                    height: 21 / 14,
                    fontWeight: FontWeight.w400,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        Text(
          TrWords.legalUpdated.tr(args: ['${DateFormatter.day(updatedAt)} ${updatedAt.year}']),
          style: theme.cardSubtitle,
        ),
      ],
    );
  }
}
