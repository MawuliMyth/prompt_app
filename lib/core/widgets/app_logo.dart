import 'package:flutter/material.dart';

/// App Logo Widget
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/w.png',
      width: width,
      height: height,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
    );
  }
}
