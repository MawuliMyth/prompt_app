import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static const String _androidTestBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _configuredAndroidBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
  );
  static const String _configuredIosBannerId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await MobileAds.instance.initialize();
    } catch (error) {
      debugPrint('AdMob initialization failed: $error');
    }
  }

  static String? get bannerAdUnitId {
    if (kIsWeb) return null;
    if (Platform.isAndroid) {
      if (_configuredAndroidBannerId.isNotEmpty) {
        return _configuredAndroidBannerId;
      }
      return kReleaseMode ? null : _androidTestBannerId;
    }
    if (Platform.isIOS) {
      if (_configuredIosBannerId.isNotEmpty) {
        return _configuredIosBannerId;
      }
      return kReleaseMode ? null : _iosTestBannerId;
    }
    return null;
  }
}
