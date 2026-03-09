import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_logo.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.fallbackLabel,
    this.premium = false,
    this.size = 48,
  });

  final String? photoUrl;
  final String fallbackLabel;
  final bool premium;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: premium
            ? AppColors.premiumGradient
            : AppColors.primaryGradient,
      ),
      alignment: Alignment.center,
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (_, _) => _fallbackLogo(),
                errorWidget: (_, _, _) => _fallbackLogo(),
              ),
            )
          : _fallbackLogo(),
    );
  }

  Widget _fallbackLogo() {
    return Padding(
      padding: EdgeInsets.all(size * 0.18),
      child: ClipOval(
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.all(size * 0.08),
          child: AppLogo(
            width: size * 0.7,
            height: size * 0.7,
          ),
        ),
      ),
    );
  }
}
