import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/utils/app_toast.dart';
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
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool? _lastOfflineState;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Force status bar icons to light (white) on our dark UI.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Init after first frame so the loading widget can show.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<HomeController>();
      await controller.init();
      
      if (mounted && controller.isOffline) {
        _lastOfflineState = true;
        AppToast.show(
          context,
          'You are offline. Playing downloads...',
          icon: HugeIcons.strokeRoundedWifiDisconnected01,
        );
      } else {
        _lastOfflineState = false;
      }
      
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
        if (!mounted) return;
        final isOffline = results.contains(ConnectivityResult.none);
        if (_lastOfflineState == true && !isOffline) {
          AppToast.show(
            context,
            'Back online!',
            icon: HugeIcons.strokeRoundedWifi01,
          );
        } else if (_lastOfflineState == false && isOffline) {
          AppToast.show(
            context,
            'You are offline. Playing downloads...',
            icon: HugeIcons.strokeRoundedWifiDisconnected01,
          );
        }
        _lastOfflineState = isOffline;
      });
      
      // Keep PageController in sync with controller index (e.g. auto-advance)
      controller.addListener(_syncPage);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    context.read<HomeController>().removeListener(_syncPage);
    _pageController.dispose();
    super.dispose();
  }

  void _syncPage() {
    final controller = context.read<HomeController>();
    
    final target = controller.currentIndex;

    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round();
      if (currentPage != target) {
        // If we are currently offstage in the IndexedStack (e.g. user is on Search screen),
        // or a new route (like Lyrics) is pushed on top, tickers are disabled. 
        // animateToPage will stall and cause state desyncs. We must jump instantly instead.
        final currentTab = mainScreenKey.currentState?.currentTab ?? 0;
        final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
        
        if (currentTab != 0 || !isCurrentRoute || controller.forceJump) {
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Selector<HomeController, _HomeListState>(
            selector: (context, controller) => _HomeListState(
              isInitialized: controller.isInitialized,
              songsLength: controller.songs.length,
              isLoadingMore: controller.isLoadingMore,
            ),
            builder: (context, state, _) {
              final controller = context.read<HomeController>();

              if (!state.isInitialized) {
                return const _SplashLoading();
              }

              if (state.songsLength == 0) {
                return const _EmptyState();
              }

              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const PageScrollPhysics(),
                // Keep prev + current + next alive to completely eliminate scroll stutter
                allowImplicitScrolling: true,
                itemCount: state.songsLength + (state.isLoadingMore ? 1 : 0),
                onPageChanged: controller.onPageChanged,
                itemBuilder: (context, index) {
                  if (index >= state.songsLength) {
                    return const _SplashLoading();
                  }

                  final song = controller.songs[index];

                  return SongPage(
                    key: ValueKey('${song.id}_$index'),
                    song: song,
                    index: index,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Loading splash Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

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

// Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ Empty state Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

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

class _HomeListState {
  final bool isInitialized;
  final int songsLength;
  final bool isLoadingMore;

  const _HomeListState({
    required this.isInitialized,
    required this.songsLength,
    required this.isLoadingMore,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _HomeListState &&
        other.isInitialized == isInitialized &&
        other.songsLength == songsLength &&
        other.isLoadingMore == isLoadingMore;
  }

  @override
  int get hashCode => Object.hash(isInitialized, songsLength, isLoadingMore);
}

