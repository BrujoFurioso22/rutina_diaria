import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Control centralizado para la carga y gestión de anuncios AdMob.
class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  int _completionsSinceLastInterstitial = 0;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  Future<BannerAd?> createBannerAd() async {
    if (!_initialized) {
      await init();
    }
    final completer = Completer<BannerAd?>();
    final banner = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(ad as BannerAd);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Fallo al cargar banner: $error');
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );
    await banner.load();
    final loadedBanner = await completer.future;
    if (loadedBanner == null) {
      banner.dispose();
    }
    return loadedBanner;
  }

  void registerRoutineCompletion({required bool isPremium}) {
    if (isPremium) {
      return;
    }
    _completionsSinceLastInterstitial++;
    if (_completionsSinceLastInterstitial >= 3) {
      _completionsSinceLastInterstitial = 0;
      _showInterstitial();
    }
  }

  Future<void> _showInterstitial() async {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      return;
    }
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Fallo al cargar interstitial: $error');
        },
      ),
    );
  }

  void disposeInterstitial() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

const String _bannerAdUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/6300978111'
    : 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';

const String _interstitialAdUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/1033173712'
    : 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
