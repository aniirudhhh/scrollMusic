import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/library_manager.dart';
import 'data/song_repository.dart';
import 'extraction/extraction_service.dart';
import 'extraction/native_extraction_service.dart';
import 'playback/native_playback_manager.dart';
import 'screens/home/home_controller.dart';
import 'screens/main_screen.dart';

class ScrollMusicApp extends StatelessWidget {
  const ScrollMusicApp({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  Widget build(BuildContext context) {
    // Instantiate extraction service once so it can be shared.
    final extractionService = NativeExtractionService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryManager>(
          create: (_) => LibraryManager(prefs),
        ),
        Provider<ExtractionService>.value(value: extractionService),
        ChangeNotifierProvider<HomeController>(
          create: (context) => HomeController(
            playbackManager: NativePlaybackManager(),
            extractionService: extractionService,
            repository: SongRepository(extractionService: extractionService),
            libraryManager: context.read<LibraryManager>(),
          ),
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
        ),
        home: MainScreen(),
      ),
    );
  }
}
