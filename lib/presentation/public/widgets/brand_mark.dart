import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:eco_task/constants/constants.dart';

/// The Eco Task app mark (a green rounded square with three task rows), drawn from the bundled SVG image.
class BrandMark extends StatelessWidget {
  /// Edge length of the mark.
  final double size;

  /// Builds the mark.
  const BrandMark({super.key, required this.size});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(AppImages.logoMark, width: size, height: size);
}
