import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/home/home_controller.dart';
import '../data/download_manager.dart';
import '../models/song.dart';
import '../core/utils/artwork_helper.dart';

class DynamicSingleColorBackground extends StatefulWidget {
  const DynamicSingleColorBackground({super.key});

  static final ValueNotifier<Color?> dominantColorNotifier = ValueNotifier(
    null,
  );

  @override
  State<DynamicSingleColorBackground> createState() =>
      _DynamicSingleColorBackgroundState();
}

class _DynamicSingleColorBackgroundState
    extends State<DynamicSingleColorBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Cache resolved colors by artwork URL.
  static final Map<String, Color> _colorCache = {};

  // Tag requests to prevent race conditions during rapid skipping.
  int _requestToken = 0;

  Color? _currentTargetColor;
  Color? _startColor;

  late final ValueNotifier<Color?> _animatedColor;
  String? _lastProcessedArtwork;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animatedColor = ValueNotifier(null);

    _controller.addListener(() {
      if (_startColor != null && _currentTargetColor != null) {
        _animatedColor.value = _lerpHct(
          _startColor!,
          _currentTargetColor!,
          _controller.value,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animatedColor.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Logic moved to build()
  }

  void _handleArtworkChange(Song song, DownloadManager dm, Color fallbackColor) async {
    final token = ++_requestToken;
    final artworkUrl = song.artwork;

    if (_colorCache.containsKey(artworkUrl)) {
      _applyNewColor(_colorCache[artworkUrl]!);
      return;
    }

    try {
      final provider = ArtworkHelper.getProvider(artworkUrl, song.id, dm);

      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        size: const Size(100, 100),
        maximumColorCount: 5,
      );

      if (!mounted || _requestToken != token) return;

      final rawColor =
          palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.mutedColor?.color ??
          fallbackColor;

      final hct = Hct.fromInt(rawColor.value);
      // Clamp tone to a fixed dark-readable range (e.g. 20-28)
      final clampedTone = hct.tone.clamp(20.0, 28.0);
      final clampedHct = Hct.from(hct.hue, hct.chroma, clampedTone);

      final resolvedColor = Color(clampedHct.toInt());
      _colorCache[artworkUrl] = resolvedColor;
      DynamicSingleColorBackground.dominantColorNotifier.value = resolvedColor;

      if (mounted && _requestToken == token) {
        _applyNewColor(resolvedColor);
      }
    } catch (e) {
      debugPrint('DynamicSingleColorBackground extraction failed: $e');
    }
  }

  void _applyNewColor(Color newColor) {
    if (_currentTargetColor == null) {
      _currentTargetColor = newColor;
      _startColor = newColor;
      _animatedColor.value = newColor;
      return;
    }

    // Only animate if it actually differs (tolerance of identical values)
    if (_currentTargetColor!.value == newColor.value) return;

    _startColor = _animatedColor.value;
    _currentTargetColor = newColor;
    _controller.forward(from: 0.0);
  }

  Color _lerpHct(Color a, Color b, double t) {
    final hctA = Hct.fromInt(a.value);
    final hctB = Hct.fromInt(b.value);

    // Shortest path interpolation for hue
    double hueA = hctA.hue;
    double hueB = hctB.hue;

    double dHue = hueB - hueA;
    if (dHue > 180.0) {
      hueA += 360.0;
    } else if (dHue < -180.0) {
      hueB += 360.0;
    }

    final hue = (hueA + (hueB - hueA) * t) % 360.0;
    final chroma = hctA.chroma + (hctB.chroma - hctA.chroma) * t;
    final tone = hctA.tone + (hctB.tone - hctA.tone) * t;

    return Color(Hct.from(hue, chroma, tone).toInt());
  }

  @override
  Widget build(BuildContext context) {
    final song = context.select<HomeController, Song?>((c) => c.currentSong);
    if (song != null && song.artwork != _lastProcessedArtwork) {
      _lastProcessedArtwork = song.artwork;
      final dm = context.read<DownloadManager>();
      final fallbackColor = Theme.of(context).colorScheme.surface;
      Future.microtask(() {
        if (mounted) _handleArtworkChange(song, dm, fallbackColor);
      });
    }

    return RepaintBoundary(
      child: ValueListenableBuilder<Color?>(
        valueListenable: _animatedColor,
        builder: (context, color, _) {
          if (color == null) {
            return const SizedBox.shrink();
          }
          return Container(color: color);
        },
      ),
    );
  }
}
