import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';
import '../utils/platform_utils.dart';
import 'shimmer_loading.dart';

/// Adaptive AppBar - Material on Android, Cupertino on iOS
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
  });
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCupertino = PlatformUtils.useCupertino(context);

    if (isCupertino) {
      return CupertinoNavigationBar(
        middle: Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.primaryLight,
          ),
        ),
        trailing: actions != null && actions!.isNotEmpty
            ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
            : null,
        leading: leading,
        backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
        border: null,
      );
    }

    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.headingLarge.copyWith(
          color: AppColors.primaryLight,
        ),
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Adaptive Elevated Button
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.isDestructive = false,
    this.filled = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isDestructive;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformUtils.useCupertino(context);

    if (isCupertino) {
      return CupertinoButton(
        onPressed: isLoading ? null : onPressed,
        color: filled
            ? (isDestructive
                  ? CupertinoColors.destructiveRed
                  : backgroundColor ?? AppColors.primaryLight)
            : null,
        borderRadius: BorderRadius.circular(16),
        padding: EdgeInsets.zero,
        child: isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Container(
                decoration: filled
                    ? null
                    : BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: foregroundColor ?? AppColors.primaryLight,
                        ),
                      ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: foregroundColor ?? (filled ? Colors.white : null),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: AppTextStyles.button.copyWith(
                        color: foregroundColor ?? (filled ? Colors.white : null),
                      ),
                    ),
                  ],
                ),
              ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive
            ? Colors.red
            : backgroundColor ?? AppColors.primaryLight,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: isLoading
          ? const ShimmerPulse(
              width: 56,
              height: 14,
              baseColor: Color(0x66FFFFFF),
              highlightColor: Color(0xAAFFFFFF),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    color: foregroundColor ?? Colors.white,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Adaptive Text Field
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCupertino = PlatformUtils.useCupertino(context);

    if (isCupertino) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null) ...[
            Text(
              labelText!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
          ],
          CupertinoTextField(
            controller: controller,
            placeholder: hintText,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            minLines: minLines,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            focusNode: focusNode,
            enabled: enabled,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: AppColors.dividerLight),
              borderRadius: BorderRadius.circular(12),
            ),
            prefix: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: prefixIcon,
                  )
                : null,
            suffix: suffixIcon,
            style: AppTextStyles.body.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      );
    }

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// Adaptive Dialog
class AdaptiveDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    bool isDestructive = false,
  }) {
    final isCupertino = PlatformUtils.useCupertino(context);

    if (isCupertino) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title, style: AppTextStyles.headingMedium),
          content: Text(content, style: AppTextStyles.body),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                confirmText,
                style: TextStyle(
                  color: isDestructive ? CupertinoColors.destructiveRed : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.headingMedium),
        content: Text(content, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: AppTextStyles.button.copyWith(
                color: isDestructive ? Colors.red : AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adaptive Progress Indicator
class AdaptiveProgressIndicator extends StatelessWidget {
  const AdaptiveProgressIndicator({super.key, this.size, this.color});
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformUtils.useCupertino(context);

    if (isCupertino) {
      return CupertinoActivityIndicator(radius: (size ?? 20) / 2, color: color);
    }

    return SizedBox(
      width: size ?? 20,
      height: size ?? 20,
      child: ShimmerPulse(
        width: size ?? 20,
        height: size ?? 20,
        baseColor: (color ?? AppColors.primaryLight).withValues(alpha: 0.28),
        highlightColor: (color ?? AppColors.primaryLight).withValues(
          alpha: 0.6,
        ),
      ),
    );
  }
}

/// Adaptive Segment Control (for filters)
class AdaptiveSegmentControl<T extends Object> extends StatelessWidget {
  const AdaptiveSegmentControl({
    super.key,
    required this.segments,
    required this.selectedValue,
    required this.onValueChanged,
  });
  final Map<T, String> segments;
  final T selectedValue;
  final void Function(T) onValueChanged;

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformUtils.useCupertino(context);

    if (isCupertino) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: selectedValue,
        onValueChanged: (value) {
          if (value != null) onValueChanged(value);
        },
        children: segments.map((key, label) => MapEntry(key, Text(label))),
      );
    }

    return SegmentedButton<T>(
      segments: segments.entries
          .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
          .toList(),
      selected: {selectedValue},
      onSelectionChanged: (Set<T> newSelection) {
        onValueChanged(newSelection.first);
      },
    );
  }
}

/// Adaptive List Tile
class AdaptiveListTile extends StatelessWidget {
  const AdaptiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  });
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCupertino = PlatformUtils.useCupertino(context);

    if (isCupertino) {
      return CupertinoListTile(
        leading: leading,
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              )
            : null,
        trailing:
            trailing ??
            (onTap != null ? const CupertinoListTileChevron() : null),
        onTap: onTap,
        padding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    }

    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(color: theme.colorScheme.onSurface),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding:
          contentPadding ?? const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

class AdaptiveSelectionChip extends StatelessWidget {
  const AdaptiveSelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCupertino = PlatformUtils.useCupertino(context);
    final backgroundColor = selected
        ? AppColors.primaryLight
        : theme.colorScheme.surface;
    final foregroundColor = selected
        ? Colors.white
        : theme.colorScheme.onSurface;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          IconTheme(
            data: IconThemeData(color: foregroundColor, size: 18),
            child: icon!,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          trailing!,
        ],
      ],
    );

    if (isCupertino) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusChip),
            border: Border.all(color: theme.dividerColor),
          ),
          child: child,
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.radiusChip),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusChip),
          border: Border.all(color: theme.dividerColor),
        ),
        child: child,
      ),
    );
  }
}

/// Adaptive Scaffold
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBody = false,
    this.resizeToAvoidBottomInset = true,
  });
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool extendBody;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformUtils.useCupertino(context);

    if (isCupertino) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        navigationBar: appBar is AdaptiveAppBar
            ? null // AdaptiveAppBar handles its own rendering
            : null,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ?appBar,
              Expanded(
                child: Material(type: MaterialType.transparency, child: body),
              ),
              ?bottomNavigationBar,
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
