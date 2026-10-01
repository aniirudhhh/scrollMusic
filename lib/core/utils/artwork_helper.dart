import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../data/download_manager.dart';

class ArtworkHelper {
  /// Returns a local FileImage if the song is downloaded and has artwork,
  /// otherwise returns a CachedNetworkImageProvider.
  static ImageProvider getProvider(String artworkUrl, String songId, DownloadManager dm) {
    final downloaded = dm.getDownload(songId);
    if (downloaded != null && downloaded.localArtworkPath != null) {
      final file = File(downloaded.localArtworkPath!);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return ResizeImage(CachedNetworkImageProvider(artworkUrl), width: 800);
  }

  /// Returns a Widget suitable for displaying the artwork (local or network)
  static Widget getWidget({
    required String artworkUrl,
    String? fallbackUrl,
    required String songId,
    required DownloadManager dm,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
  }) {
    final downloaded = dm.getDownload(songId);
    if (downloaded != null && downloaded.localArtworkPath != null) {
      final file = File(downloaded.localArtworkPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: fit);
      }
    }
    return CachedNetworkImage(
      imageUrl: artworkUrl,
      fit: fit,
      memCacheWidth: 800, // MUST MATCH _prefetchAround maxWidth to hit memory cache!
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: placeholder,
      errorWidget: (context, url, error) {
        if (fallbackUrl != null && fallbackUrl.isNotEmpty && fallbackUrl != artworkUrl) {
          return CachedNetworkImage(
            imageUrl: fallbackUrl,
            fit: fit,
            memCacheWidth: 800,
            fadeInDuration: const Duration(milliseconds: 300),
            placeholder: placeholder,
            errorWidget: errorWidget,
          );
        }
        if (errorWidget != null) {
          return errorWidget(context, artworkUrl, null);
        }
        return const SizedBox();
      },
    );
  }
}
