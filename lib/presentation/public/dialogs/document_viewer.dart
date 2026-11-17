import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import '../widgets/app_icon.dart';

/// Full-screen preview of a document: a close button, the file name with a size line, a share button, a white page
/// sketch (text lines until the API serves real files) and a "page / total" pill.
class DocumentViewer extends StatelessWidget {
  /// File name written in the bar.
  final String name;

  /// Builds the viewer.
  const DocumentViewer({super.key, required this.name});

  /// Pushes the viewer over the whole screen.
  static Future<void> show(BuildContext context, String name) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => DocumentViewer(name: name)));

  /// One gray text line of the page sketch, [widthFactor] of the page wide.
  Widget _line(double widthFactor) => Padding(
    padding: EdgeInsets.only(top: 9.h),
    child: FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 6.h,
        decoration: BoxDecoration(color: const Color(0xFFD9DDDA), borderRadius: 3.circular),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    /// Ink color of a white sheet of paper, the same in both themes.
    const ink = Color(0xFF111111);
    return Scaffold(
      backgroundColor: theme.cardColorLight,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52.h,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: AppIcon(AppIcons.x, size: 22.sp, color: theme.text),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
                        ),
                        Text('240 KB · 3', style: theme.cardSubtitle.copyWith(fontSize: 12.sp)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: AppIcon(AppIcons.share, size: 22.sp, color: theme.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 300.w,
                  padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 30.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: 4.circular,
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 6),
                        blurRadius: 24,
                        color: const Color(0xFF000000).withValues(alpha: 0.18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          name,
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: ink),
                        ),
                      ),
                      for (final w in [1.0, 0.96, 1.0, 0.88, 0.94, 0.6]) _line(w),
                      16.h.height,
                      Text(
                        '1',
                        style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: ink),
                      ),
                      for (final w in [1.0, 0.92, 0.98, 0.7]) _line(w),
                      16.h.height,
                      Text(
                        '2',
                        style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, color: ink),
                      ),
                      for (final w in [1.0, 0.95, 0.84, 1.0, 0.52]) _line(w),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: 14.circular),
                child: Text(
                  TrWords.mtPages.tr(args: ['1', '3']),
                  style: theme.textStyle.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
