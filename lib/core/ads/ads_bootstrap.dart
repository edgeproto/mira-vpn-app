import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> initializeAdsSdk() async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
    return;
  }
  await MobileAds.instance.initialize();
}
