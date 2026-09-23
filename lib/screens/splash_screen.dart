import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/splash-screen.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown and play the video
        setState(() {});
        _controller.play();
        _controller.setVolume(0); // Mute just in case
      });

    // Add a listener to detect when the video finishes
    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (_controller.value.isInitialized && 
        !_controller.value.isPlaying && 
        _controller.value.duration == _controller.value.position) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (_isNavigating) return;
    _isNavigating = true;

    // Use a slow fade transition to the main screen
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            // Show a simple black screen while the video initializes
            : const SizedBox.shrink(),
      ),
    );
  }
}
