import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — this is a phone-first app.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Immersive edge-to-edge experience from launch.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://251f0bb04ad937c3da81535383af358e@o4512177209016320.ingest.de.sentry.io/4512177379278928';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(LooprApp(prefs: prefs)),
  );
}
