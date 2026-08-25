import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_service.dart';

// Moved out of lib/core/utils/ - per architecture.md, lib/core/ is for
// design tokens, themes, platform helpers, and reusable shared widgets
// only, not business/network logic. This bootstraps the analytics service
// (a lib/data/services/ concern) and exposes the small tracking helper used
// throughout the screens/providers layers.

final analyticsService = AnalyticsService();
final analyticsObserver = FirebaseAnalyticsObserver(
  analytics: analyticsService.analytics,
);

void trackAnalytics(Future<void> Function() action) {
  unawaited(() async {
    try {
      await action();
    } catch (_) {}
  }());
}
