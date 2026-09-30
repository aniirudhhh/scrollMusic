import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/yt_music_sync_service.dart';

class YTAuthScreen extends StatefulWidget {
  const YTAuthScreen({super.key});

  @override
  State<YTAuthScreen> createState() => _YTAuthScreenState();
}

class _YTAuthScreenState extends State<YTAuthScreen> {
  late final WebViewController _controller;
  static const _cookieChannel = MethodChannel('com.scrollmusic/cookies');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _checkCookies(url);
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              _checkCookies(change.url!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://accounts.google.com/ServiceLogin?continue=https://music.youtube.com/'));
  }

  bool _isPopping = false;

  Future<void> _checkCookies(String url) async {
    if (!url.contains('music.youtube.com') || _isPopping) return;

    try {
      final String? cookieString = await _cookieChannel.invokeMethod('getCookies', {
        'url': 'https://youtube.com',
      });

      if (cookieString != null && 
         (cookieString.contains('SAPISID') || cookieString.contains('__Secure-3PSID'))) {
        
        await YTMusicSyncService.setAuthCookie(cookieString);
        
        if (mounted && !_isPopping) {
          _isPopping = true;
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('Error getting cookies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect YouTube Music', style: TextStyle(fontSize: 18, color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
