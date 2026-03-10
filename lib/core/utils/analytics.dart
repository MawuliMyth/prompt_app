import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';

import '../../data/services/analytics_service.dart';

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
