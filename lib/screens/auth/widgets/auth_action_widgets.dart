import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../core/widgets/shimmer_loading.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformUtils.useCupertino(context);

    if (isCupertino) {
      return SizedBox(
        height: 56,
        width: double.infinity,
        child: CupertinoButton(
          onPressed: isLoading ? null : onPressed,
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          child: isLoading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : Text(
                  label,
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isLoading
                ? ShimmerButtonLoader(text: loadingLabel ?? label)
                : Text(
                    label,
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}

class AuthSurfaceButton extends StatelessWidget {
  const AuthSurfaceButton({
    super.key,
    required this.label,
    this.leading,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final Widget? leading;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCupertino = PlatformUtils.useCupertino(context);
    final resolvedBackground =
        backgroundColor ??
        (theme.brightness == Brightness.light
            ? Colors.white
            : AppColors.surfaceDark);
    final resolvedForeground = foregroundColor ?? theme.colorScheme.onSurface;
    final resolvedBorder = borderColor ?? theme.dividerColor;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(
              color: resolvedForeground,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isCupertino) {
      return SizedBox(
        height: 56,
        width: double.infinity,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: resolvedBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: resolvedBorder),
            ),
            child: Center(child: content),
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: resolvedBackground,
          foregroundColor: resolvedForeground,
          side: BorderSide(color: resolvedBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: content,
      ),
    );
  }
}
