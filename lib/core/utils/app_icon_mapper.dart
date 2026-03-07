import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

IconData resolveIcon(String iconKey, {bool cupertino = false}) {
  switch (iconKey) {
    case 'sparkles':
      return cupertino ? CupertinoIcons.sparkles : Icons.auto_awesome_rounded;
    case 'code':
      return cupertino
          ? CupertinoIcons.chevron_left_slash_chevron_right
          : Icons.code_rounded;
    case 'edit':
      return cupertino ? CupertinoIcons.pencil : Icons.edit_outlined;
    case 'image':
      return cupertino ? CupertinoIcons.photo : Icons.image_outlined;
    case 'briefcase':
      return cupertino ? CupertinoIcons.briefcase : Icons.work_outline_rounded;
    case 'palette':
      return cupertino ? CupertinoIcons.paintbrush : Icons.palette_outlined;
    case 'chat':
      return cupertino
          ? CupertinoIcons.chat_bubble_2
          : Icons.chat_bubble_outline_rounded;
    case 'megaphone':
      return cupertino ? CupertinoIcons.speaker_2 : Icons.campaign_outlined;
    case 'settings':
      return cupertino ? CupertinoIcons.settings : Icons.settings_outlined;
    case 'grid':
      return cupertino
          ? CupertinoIcons.square_grid_2x2
          : Icons.grid_view_rounded;
    case 'mic':
      return cupertino ? CupertinoIcons.mic : Icons.mic_none_rounded;
    case 'chart':
      return cupertino ? CupertinoIcons.chart_bar : Icons.show_chart_rounded;
    default:
      return cupertino
          ? CupertinoIcons.circle_grid_hex
          : Icons.auto_awesome_outlined;
  }
}

Color resolveVisualStyle(String visualStyle) {
  switch (visualStyle) {
    case 'lime':
      return AppColors.featureLime;
    case 'mint':
      return AppColors.featureMint;
    case 'blush':
      return AppColors.featureBlush;
    case 'sky':
      return AppColors.categoryBusiness.withValues(alpha: 0.22);
    case 'lavender':
    default:
      return AppColors.featureLavender;
  }
}
