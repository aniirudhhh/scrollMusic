/// Represents all possible errors the app can surface to higher layers.
/// UI never sees raw exceptions — only [AppError] variants.
sealed class AppError {
  const AppError();
}

/// Network is unavailable or request timed out.
final class NetworkError extends AppError {
  const NetworkError([this.message = 'No internet connection']);
  final String message;
}

/// The YouTube video is unavailable, removed, or region-blocked.
final class VideoUnavailableError extends AppError {
  const VideoUnavailableError(this.videoId);
  final String videoId;
}

/// Stream extraction failed (yt-dlp / NewPipe returned an error).
final class ExtractionError extends AppError {
  const ExtractionError(this.cause);
  final String cause;
}

/// The extracted stream URL has expired and needs re-extraction.
final class StreamExpiredError extends AppError {
  const StreamExpiredError();
}

/// Media3 / ExoPlayer reported a playback error.
final class PlaybackError extends AppError {
  const PlaybackError(this.cause);
  final String cause;
}

/// A generic unexpected error.
final class UnknownError extends AppError {
  const UnknownError(this.cause);
  final Object cause;
}
