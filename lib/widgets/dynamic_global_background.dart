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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A0A), // Very dark grey/black at top
            Color(0xFF050505),
            Color(0xFF000000), // Pure black at bottom
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
