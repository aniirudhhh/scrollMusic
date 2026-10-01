import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AsyncLooprApp());
}

class AsyncLooprApp extends StatefulWidget {
  const AsyncLooprApp({super.key});

  @override
  State<AsyncLooprApp> createState() => _AsyncLooprAppState();
}

class _AsyncLooprAppState extends State<AsyncLooprApp> {
  Future<void>? _initFuture;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initFuture = _initApp();
  }

  Future<void> _initApp() async {
    // These run asynchronously
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences init failed: $e');
      rethrow;
    }

    try {
      SentryFlutter.init(
        (options) {
          options.dsn = 'https://251f0bb04ad937c3da81535383af358e@o4512177209016320.ingest.de.sentry.io/4512177379278928';
          options.tracesSampleRate = 0.1; 
          options.profilesSampleRate = 0.0; 
        },
      ).catchError((e) {
        debugPrint('Sentry init failed: $e');
      });
    } catch (e) {
      debugPrint('Sentry synchronous init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && _prefs != null) {
          return LooprApp(prefs: _prefs!);
        }
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: Text('Startup Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
            ),
          );
        }
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(backgroundColor: Colors.black), // Instant first frame
        );
      },
    );
  }
}
