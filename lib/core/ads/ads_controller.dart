import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'interstitial_gate.dart';
import 'admob_config.dart';

abstract class AdsController {
  bool get supportsAds;

  bool shouldShowBanner({required bool isFreeTier});

  Future<void> showInterstitialBeforeConnectIfEligible({
    required bool isFreeTier,
  });
}

class GoogleMobileAdsController implements AdsController {
  GoogleMobileAdsController({
    InterstitialGate? gate,
    Duration interstitialLoadTimeout = const Duration(seconds: 2),
  }) : _gate = gate ?? InterstitialGate(),
       _interstitialLoadTimeout = interstitialLoadTimeout;

  final InterstitialGate _gate;
  final Duration _interstitialLoadTimeout;

  @override
  bool get supportsAds => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  bool shouldShowBanner({required bool isFreeTier}) {
    return supportsAds && isFreeTier;
  }

  @override
  Future<void> showInterstitialBeforeConnectIfEligible({
    required bool isFreeTier,
  }) async {
    if (!supportsAds || !isFreeTier || !_gate.canShowNow()) {
      return;
    }

    final completer = Completer<void>();
    InterstitialAd.load(
      adUnitId: AdMobConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _gate.markShownNow();
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );

    await completer.future.timeout(
      _interstitialLoadTimeout,
      onTimeout: () {},
    );
  }
}
