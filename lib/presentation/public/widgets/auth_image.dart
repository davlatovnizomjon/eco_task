import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/files_repository.dart';

/// A photo from the API: downloads the bytes of file [id] with the session's token (the files are private) and draws
/// them cover-fitted; while loading, or when the file has no bytes, it shows a tinted placeholder tile.
class AuthImage extends StatefulWidget {
  /// Id of the file.
  final int id;

  /// Corner radius of the picture.
  final double radius;

  /// Builds the picture; it fills the space its parent gives it.
  const AuthImage(this.id, {super.key, this.radius = 0});

  @override
  State<AuthImage> createState() => _AuthImageState();
}

/// Fetches the bytes once per id.
class _AuthImageState extends State<AuthImage> {
  /// The loaded bytes; null until they arrive or when the download failed.
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AuthImage old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) _load();
  }

  /// Downloads the file; a failure keeps the placeholder.
  Future<void> _load() async {
    try {
      final data = await RepositoryProvider.of<FilesRepository>(context).bytes(widget.id);
      if (mounted) setState(() => _bytes = Uint8List.fromList(data));
    } catch (_) {
      if (mounted) setState(() => _bytes = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = theme.photoTones[widget.id % theme.photoTones.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: _bytes == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tone),
              ),
              child: const SizedBox.expand(),
            )
          : Image.memory(
              _bytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
            ),
    );
  }
}
