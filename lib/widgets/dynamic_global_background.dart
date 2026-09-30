import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/artwork_helper.dart';
import '../data/download_manager.dart';
import '../screens/home/home_controller.dart';

class DynamicGlobalBackground extends StatelessWidget {
  const DynamicGlobalBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        final currentSong = controller.currentSong;
        final dm = context.watch<DownloadManager>();
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base dark color
            Container(color: const Color(0xFF050505)),
            
            // Blurred Artwork via hardware upscaling (no ImageFilter.blur)
            if (currentSong != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 1200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Container(
                  key: ValueKey(currentSong.id),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: ResizeImage(
                        ArtworkHelper.getProvider(currentSong.artwork, currentSong.id, dm),
                        width: 12, // Extremely tiny to force natural hardware blur on upscale
                      ),
                      fit: BoxFit.cover,
                      // Hardware bilinear filtering creates the smooth blur for free
                      filterQuality: FilterQuality.low, 
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
