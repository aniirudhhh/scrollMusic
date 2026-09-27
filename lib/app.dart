import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/library_manager.dart';
import 'data/song_repository.dart';
import 'extraction/extraction_service.dart';
import 'extraction/native_extraction_service.dart';
import 'playback/native_playback_manager.dart';
import 'screens/home/home_controller.dart';
import 'screens/main_screen.dart';
import 'recommendation/profile/user_profile_manager.dart';
import 'recommendation/recommendation_engine.dart';
import 'core/utils/sleep_timer.dart';

TextTheme _buildRoundedTextTheme(TextTheme base) {
  const variations = <FontVariation>[FontVariation('ROND', 100)];
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    displayMedium: base.displayMedium?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    displaySmall: base.displaySmall?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    titleLarge: base.titleLarge?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    titleMedium: base.titleMedium?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    titleSmall: base.titleSmall?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    bodySmall: base.bodySmall?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    labelLarge: base.labelLarge?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    labelMedium: base.labelMedium?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
    labelSmall: base.labelSmall?.copyWith(fontFamily: 'GoogleSansFlex', fontVariations: variations),
  );
}

class ScrollMusicApp extends StatelessWidget {
  const ScrollMusicApp({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  Widget build(BuildContext context) {
    // Instantiate extraction service once so it can be shared.
    final extractionService = NativeExtractionService();
    final userProfileManager = UserProfileManager(prefs);
    final recommendationEngine = RecommendationEngine(
      profileManager: userProfileManager,
      extractionService: extractionService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SleepTimer>(
          create: (_) => SleepTimer(),
        ),
        ChangeNotifierProvider<LibraryManager>(
          create: (_) => LibraryManager(prefs),
        ),
        Provider<ExtractionService>.value(value: extractionService),
        Provider<RecommendationEngine>.value(value: recommendationEngine),
        ChangeNotifierProvider<HomeController>(
          create: (context) => HomeController(
            playbackManager: NativePlaybackManager(),
            extractionService: extractionService,
            repository: SongRepository(
              extractionService: extractionService,
              recommendationEngine: recommendationEngine,
              prefs: prefs,
            ),
            libraryManager: context.read<LibraryManager>(),
            recommendationEngine: recommendationEngine,
          )..init(),
        ),
      ],
      child: MaterialApp(
        title: 'ScrollMusic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'GoogleSansFlex',
          textTheme: _buildRoundedTextTheme(Typography.material2021().white),
        ),
        home: MainScreen(),
      ),
    );
  }
}
