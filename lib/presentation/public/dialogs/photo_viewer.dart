import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'package:eco_task/infrastructure/dto/models/file_attachment.dart';

import '../widgets/app_icon.dart';
import '../widgets/auth_image.dart';

/// Full-screen photo viewer on black: a close button, the "n / total" counter, a share button, the swipeable photo
/// and a strip of thumbnails. Photos are drawn as placeholder gradients until the API serves real files.
class PhotoViewer extends StatefulWidget {
  /// Number of photos.
  final int count;

  /// Index of the photo shown first.
  final int initial;

  /// Real photos to draw; when empty the viewer shows placeholder gradients.
  final List<FileAttachment> files;

  /// Builds the viewer.
  const PhotoViewer({super.key, required this.count, this.initial = 0, this.files = const []});

  /// Pushes the viewer over the whole screen.
  static Future<void> show(
    BuildContext context, {
    required int count,
    int initial = 0,
    List<FileAttachment> files = const [],
  }) =>
      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: false,
          pageBuilder: (_, _, _) => PhotoViewer(count: count, initial: initial, files: files),
          transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
        ),
      );

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

/// Keeps the page controller and the index of the visible photo.
class _PhotoViewerState extends State<PhotoViewer> {
  /// Drives the swipeable photo area.
  late final PageController _pages = PageController(initialPage: widget.initial);

  /// Index of the visible photo.
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Placeholder gradient of photo [i].
  LinearGradient _tone(int i) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: theme.photoTones[i % theme.photoTones.length],
  );

  @override
  Widget build(BuildContext context) {
    /// White used for everything drawn over the black backdrop.
    const onDark = Color(0xFFFFFFFF);
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52.h,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: AppIcon(AppIcons.x, size: 22.sp, color: onDark),
                  ),
                  Expanded(
                    child: Text(
                      TrWords.mtPages.tr(args: ['${_index + 1}', '${widget.count}']),
                      textAlign: TextAlign.center,
                      style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600, color: onDark),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: AppIcon(AppIcons.share, size: 22.sp, color: onDark),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: widget.count,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => Center(
                  child: SizedBox(
                    height: 420.h,
                    width: double.infinity,
                    child: widget.files.length > i
                        ? AuthImage(widget.files[i].id, radius: 0)
                        : DecoratedBox(decoration: BoxDecoration(gradient: _tone(i))),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.count; i++)
                    GestureDetector(
                      onTap: () => _pages.jumpToPage(i),
                      child: Opacity(
                        opacity: i == _index ? 1 : 0.6,
                        child: Container(
                          width: 48.w,
                          height: 48.w,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            gradient: widget.files.length > i ? null : _tone(i),
                            borderRadius: 8.circular,
                            border: i == _index ? Border.all(color: onDark, width: 2) : null,
                          ),
                          child: widget.files.length > i ? AuthImage(widget.files[i].id, radius: 0) : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
