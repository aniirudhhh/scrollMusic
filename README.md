# ScrollMusic 🎵

ScrollMusic is a revolutionary music discovery app built with Flutter and Native Android (Kotlin). It completely reimagines how you find and listen to music by combining the addictive vertical-scrolling feed of TikTok with the premium aesthetics and functionality of Apple Music.

## 🚀 Features

- **TikTok-Style Discovery Feed**: Swipe vertically to discover new music instantly. The feed dynamically preloads and crossfades audio for a seamless, zero-latency scrolling experience.
- **Apple Music-Style UI**: A gorgeous, dark-themed interface utilizing dynamic `LiquidGlassSurface` (glassmorphism), smooth animations, and premium typography.
- **Native ExoPlayer Integration**: Audio playback, buffering, and media session management is entirely handled via a custom Native Android bridge (`NativePlaybackManager.kt`), ensuring rock-solid performance, lock-screen controls, and system-level audio routing.
- **Direct YouTube Streaming**: Bypasses traditional APIs to directly extract and stream high-quality audio from YouTube videos using a robust backend architecture (`DiscoveryManager.kt`, `TrackMatcher.kt`).
- **Smart Queue Management**: Features an interactive "Up Next" queue accessible from the player. Support for drag-and-drop reordering, swipe-to-delete, and true "Add to Queue" / "Play Next" functionality.
- **Library & Playlists**: Seamlessly "Like" songs to add them to your library, or organize them into custom playlists with interactive, frosted-glass nested modals.
- **Interactive Search**: Search across millions of songs with instant results. Long-press any track to pull up contextual options (Play Next, Add to Queue, Add to Playlist).

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend/Audio**: Native Android (Kotlin, ExoPlayer, Media3)
- **State Management**: Provider
- **Local Storage**: SharedPreferences
- **Icons**: HugeIcons

## 🏗 Architecture Highlights

- **`HomeController`**: The central state manager that keeps the vertical `PageView`, background native player, and queue system in perfect sync.
- **`NativePlaybackManager`**: Uses Platform Channels to communicate with the Android ExoPlayer service, handling everything from audio focus to notification controls.
- **`ExtractionService`**: A layered architecture that fetches trending/recommendation feeds and extracts direct stream URLs, with automatic caching and retry logic for expired streams.

## 🏃‍♂️ Getting Started

1. Ensure you have Flutter and the Android SDK installed.
2. Clone the repository:
   ```bash
   git clone https://github.com/aniirudhhh/scrollMusic.git
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 📦 Building for Release

To generate a production-ready APK:
```bash
flutter build apk --release
```
The output will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## 🎨 UI Showcase
The UI heavily utilizes custom widgets like `FloatingNavbar`, `DynamicGlobalBackground`, and `SongOptionsBottomSheet` to maintain a distinct, highly polished, Apple Music-inspired visual identity.
