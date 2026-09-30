import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update _checkLoginStatus
old_check = '''  Future<void> _checkLoginStatus() async {
    final cookie = await YTMusicSyncService.getCookie();
    final hasCookie = YTMusicSyncService.hasCookie(cookie);
    
    if (hasCookie) {
      final profile = await YTMusicSyncService.fetchUserProfile();
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _accountName = profile?['name'];
          _accountEmail = profile?['email'];
          _avatarUrl = profile?['avatarUrl'];
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _accountName = null;
          _accountEmail = null;
          _avatarUrl = null;
        });
      }
    }
  }'''

new_check = '''  Future<void> _checkLoginStatus() async {
    final cookie = await YTMusicSyncService.getCookie();
    final hasCookie = YTMusicSyncService.hasCookie(cookie);
    
    if (hasCookie) {
      // 1. Fast load from cache
      final cachedProfile = await YTMusicSyncService.getCachedProfile();
      if (mounted && cachedProfile != null) {
        setState(() {
          _isLoggedIn = true;
          _accountName = cachedProfile['name'];
          _accountEmail = cachedProfile['email'];
          _avatarUrl = cachedProfile['avatarUrl'];
        });
      }

      // 2. Background fetch fresh data
      final profile = await YTMusicSyncService.fetchUserProfile();
      if (mounted && profile != null) {
        setState(() {
          _isLoggedIn = true;
          _accountName = profile['name'];
          _accountEmail = profile['email'];
          _avatarUrl = profile['avatarUrl'];
        });
      } else if (mounted && profile == null && cachedProfile == null) {
        // Fallback if completely failed
        setState(() {
          _isLoggedIn = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _accountName = null;
          _accountEmail = null;
          _avatarUrl = null;
        });
      }
    }
  }'''

content = content.replace(old_check, new_check)

# 2. Update _handleDisconnect to clear cache
old_disconnect = '''  Future<void> _handleDisconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('yt_auth_cookie');
    await _checkLoginStatus();
    if (mounted) {
      AppToast.show(context, 'Account disconnected');
    }
  }'''

new_disconnect = '''  Future<void> _handleDisconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('yt_auth_cookie');
    await YTMusicSyncService.clearCachedProfile();
    await _checkLoginStatus();
    if (mounted) {
      AppToast.show(context, 'Account disconnected');
    }
  }'''

content = content.replace(old_disconnect, new_disconnect)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
