import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  Future<void> setUserProperties({
    required bool isPremium,
    required String planType,
  }) async {
    await _guard(() async {
      await _analytics.setUserProperty(
        name: 'is_premium',
        value: isPremium.toString(),
      );
      await _analytics.setUserProperty(name: 'plan_type', value: planType);
    });
  }

  Future<void> logScreenView(String screenName) async {
    await _guard(() => _analytics.logScreenView(screenName: screenName));
  }

  Future<void> logPromptEnhanced({
    required String category,
    required String tone,
    required bool isVoice,
    required bool isPremium,
    required int strengthScore,
  }) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'prompt_enhanced',
        parameters: {
          'category': category,
          'tone': tone,
          'input_method': isVoice ? 'voice' : 'text',
          'is_premium': isPremium.toString(),
          'strength_score': strengthScore,
        },
      ),
    );
  }

  Future<void> logPromptCopied({
    required String category,
    required bool isPremium,
  }) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'prompt_copied',
        parameters: {
          'category': category,
          'is_premium': isPremium.toString(),
        },
      ),
    );
  }

  Future<void> logPromptShared({required String category}) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'prompt_shared',
        parameters: {'category': category},
      ),
    );
  }

  Future<void> logPromptFavourited() async {
    await _guard(() => _analytics.logEvent(name: 'prompt_favourited'));
  }

  Future<void> logVariationsRequested() async {
    await _guard(() => _analytics.logEvent(name: 'variations_requested'));
  }

  Future<void> logVoiceRecordingStarted() async {
    await _guard(() => _analytics.logEvent(name: 'voice_recording_started'));
  }

  Future<void> logVoiceRecordingCompleted({required int durationSeconds}) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'voice_recording_completed',
        parameters: {'duration_seconds': durationSeconds},
      ),
    );
  }

  Future<void> logCategorySelected({required String category}) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'category_selected',
        parameters: {'category': category},
      ),
    );
  }

  Future<void> logToneSelected({required String tone}) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'tone_selected',
        parameters: {'tone': tone},
      ),
    );
  }

  Future<void> logSignUpCompleted({required String method}) async {
    await _guard(() => _analytics.logSignUp(signUpMethod: method));
  }

  Future<void> logLoginCompleted({required String method}) async {
    await _guard(() => _analytics.logLogin(loginMethod: method));
  }

  Future<void> logGuestToUserConverted() async {
    await _guard(() => _analytics.logEvent(name: 'guest_converted_to_user'));
  }

  Future<void> logPaywallViewed({required String trigger}) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'paywall_viewed',
        parameters: {'trigger': trigger},
      ),
    );
  }

  Future<void> logPlanSelected({required String plan}) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'plan_selected',
        parameters: {'plan': plan},
      ),
    );
  }

  Future<void> logTrialStarted() async {
    await _guard(() => _analytics.logEvent(name: 'trial_started'));
  }

  Future<void> logPurchaseStarted({
    required String plan,
    required double price,
  }) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'purchase_started',
        parameters: {'plan': plan, 'price': price},
      ),
    );
  }

  Future<void> logPurchaseCompleted({
    required String plan,
    required double price,
  }) async {
    await _guard(
      () => _analytics.logPurchase(
        currency: 'USD',
        value: price,
        items: [
          AnalyticsEventItem(
            itemName: 'Prompt Premium - $plan',
            itemId: 'prompt_premium_$plan',
            price: price,
          ),
        ],
      ),
    );
  }

  Future<void> logPaywallDismissed() async {
    await _guard(() => _analytics.logEvent(name: 'paywall_dismissed'));
  }

  Future<void> logTemplateUsed({
    required String templateName,
    required String category,
  }) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'template_used',
        parameters: {
          'template_name': templateName,
          'category': category,
        },
      ),
    );
  }

  Future<void> logDailyLimitReached() async {
    await _guard(() => _analytics.logEvent(name: 'daily_limit_reached'));
  }

  Future<void> logGuestLimitReached() async {
    await _guard(() => _analytics.logEvent(name: 'guest_limit_reached'));
  }

  Future<void> logFeatureLockedTapped({required String featureName}) async {
    await _guard(
      () => _analytics.logEvent(
        name: 'locked_feature_tapped',
        parameters: {'feature_name': featureName},
      ),
    );
  }

  Future<void> logPromptExported() async {
    await _guard(() => _analytics.logEvent(name: 'prompts_exported'));
  }

  Future<void> logPersonaUpdated() async {
    await _guard(() => _analytics.logEvent(name: 'persona_updated'));
  }
}
