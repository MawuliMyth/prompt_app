import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper class for platform-specific operations
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Check if running on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Check if running on macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Check if running on Apple platform (iOS or macOS)
  static bool get isApple {
    return isIOS || isMacOS;
  }

  /// Check if current platform should use Cupertino styling
  static bool useCupertino(BuildContext context) {
    if (kIsWeb) return false;
    return Theme.of(context).platform == TargetPlatform.iOS ||
           Theme.of(context).platform == TargetPlatform.macOS;
  }

  /// Get adaptive page route
  static PageRoute<T> adaptivePageRoute<T>(Widget page, {RouteSettings? settings}) {
    if (kIsWeb) {
      return MaterialPageRoute<T>(
        builder: (_) => page,
        settings: settings,
      );
    }

    if (Platform.isIOS || Platform.isMacOS) {
      return PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        settings: settings,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      );
    }

    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: settings,
    );
  }

  /// Navigate with adaptive transition
  static void navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(adaptivePageRoute(page));
  }

  /// Navigate with replacement using adaptive transition
  static void navigateReplace(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(adaptivePageRoute(page));
  }
}
