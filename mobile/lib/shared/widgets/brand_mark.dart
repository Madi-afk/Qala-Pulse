import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppPalette.green,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(Icons.radar_rounded, color: Colors.white, size: size * .65),
    ),
  );
}
