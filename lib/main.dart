import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/ads/ads_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAdsSdk();
  runApp(
    const ProviderScope(
      child: MiraVpnApp(),
    ),
  );
}
