import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'platform_utils.dart';

class SnackbarUtils {
  static OverlayEntry? _activeOverlay;
  static Timer? _dismissTimer;

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
      icon: CupertinoIcons.check_mark_circled_solid,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 3),
      icon: CupertinoIcons.exclamationmark_circle_fill,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: Colors.black87,
      duration: const Duration(seconds: 2),
      icon: CupertinoIcons.info_circle_fill,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required Duration duration,
    required IconData icon,
  }) {
    if (!PlatformUtils.useCupertino(context)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: duration,
          ),
        );
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    _dismissTimer?.cancel();
    _activeOverlay?.remove();

    _activeOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: SafeArea(
            child: CupertinoPopupSurface(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: backgroundColor.withValues(alpha: 0.95)),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(message)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_activeOverlay!);
    _dismissTimer = Timer(duration, () {
      _activeOverlay?.remove();
      _activeOverlay = null;
    });
  }
}
