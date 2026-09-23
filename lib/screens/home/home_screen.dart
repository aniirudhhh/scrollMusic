import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/playback_state.dart';
import '../../widgets/song_page.dart';
import '../main_screen.dart';
import 'home_controller.dart';

/// Root screen. Houses the vertical PageView and wires it to [HomeController].
/// Minimal widget — layout and interaction only.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Force status bar icons to light (white) on our dark UI.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Init after first frame so the loading widget can show.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().init();
      // Keep PageController in sync with controller index (e.g. auto-advance)
      context.read<HomeController>().addListener(_syncPage);
    });
  }

  @override
  void dispose() {
    context.read<HomeController>().removeListener(_syncPage);
    _pageController.dispose();
    super.dispose();
  }

  /// Animate the PageController to match the controller's current index.
  /// Called whenever HomeController notifies (e.g., after skipToNext).
  void _syncPage() {
    final controller = context.read<HomeController>();
    final target = controller.currentIndex;
    
    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round();
      if (currentPage != target) {
        // If we are currently offstage in the IndexedStack (e.g. user is on Search screen),
        // tickers are disabled. animateToPage will stall and cause state desyncs.
        // We must jump instantly instead.
        final currentTab = mainScreenKey.currentState?.currentTab ?? 0;
        if (currentTab != 0 || controller.forceJump) {
          _pageController.jumpToPage(target);
          controller.consumeForceJump();
        } else if (controller.programmaticNav) {
          _pageController.animateToPage(
            target,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
          controller.consumeProgrammaticNav();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Consumer<HomeController>(
        builder: (context, controller, _) {
          if (!controller.isInitialized) {
            return const _SplashLoading();
          }

          if (controller.songs.isEmpty) {
            return const _EmptyState();
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
            // Keep only prev + current + next alive.
            itemCount: controller.songs.length + (controller.isLoadingMore ? 1 : 0),
            onPageChanged: controller.onPageChanged,
            itemBuilder: (context, index) {
              if (index >= controller.songs.length) {
                return const _SplashLoading();
              }

              final song = controller.songs[index];
              final isCurrent = index == controller.currentIndex;

              return SongPage(
                song: song,
                // Only the current page shows live playback state.
                // Neighbors show idle so they don't flicker when preloading.
                playbackState: isCurrent
                    ? controller.playbackState
                    : PlaybackState.idle,
                positionNotifier: controller.positionNotifier,
                isCurrent: isCurrent,
                durationNotifier: controller.durationNotifier,
                onPlayPause: controller.togglePlayPause,
                onSeek: controller.seek,
                onSkipNext: controller.skipToNext,
                onSkipPrev: controller.skipToPrev,
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Loading splash ────────────────────────────────────────────────────────

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'No songs found',
          style: TextStyle(color: Color(0xFF555555), fontSize: 16),
        ),
      ),
    );
  }
}
