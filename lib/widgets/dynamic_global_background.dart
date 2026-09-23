import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/home/home_controller.dart';

class DynamicGlobalBackground extends StatelessWidget {
  const DynamicGlobalBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        final currentSong = controller.currentSong;
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base dark color
            Container(color: const Color(0xFF050505)),
            
            // Blurred Artwork
            if (currentSong != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 1200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: ImageFiltered(
                  key: ValueKey(currentSong.id),
                  imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Transform.scale(
                    scale: 1.2, // prevent edges from showing without blur
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(currentSong.artwork),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
            // Dark Gradient Overlay (no BackdropFilter)
            if (currentSong != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
