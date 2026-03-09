import 'package:flutter/material.dart';

/// App Logo Widget
class AppLogo extends StatelessWidget {

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.color,
  });
  final double? width;
  final double? height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logopt.png',
      width: width,
      height: height,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
    );
  }
}
