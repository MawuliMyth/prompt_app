import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

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
    final avatarText = fallbackLabel.trim().isEmpty
        ? 'P'
        : fallbackLabel.trim()[0].toUpperCase();

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
                placeholder: (_, _) => _fallbackText(avatarText),
                errorWidget: (_, _, _) => _fallbackText(avatarText),
              ),
            )
          : _fallbackText(avatarText),
    );
  }

  Widget _fallbackText(String avatarText) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          avatarText,
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}
