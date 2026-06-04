import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../data/services/ad_service.dart';
import '../../providers/premium_provider.dart';

class PremiumAwareBannerAd extends StatelessWidget {
  const PremiumAwareBannerAd({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, _) {
        if (premiumProvider.hasPremiumAccess) {
          return const SizedBox.shrink();
        }

        return _BannerAdView(margin: margin);
      },
    );
  }
}

class _BannerAdView extends StatefulWidget {
  const _BannerAdView({required this.margin});

  final EdgeInsetsGeometry margin;

  @override
  State<_BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<_BannerAdView> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId == null) return;

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    );

    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    if (!_isLoaded || bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: widget.margin,
      alignment: Alignment.center,
      child: SizedBox(
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        child: AdWidget(ad: bannerAd),
      ),
    );
  }
}
