import os

new_code = '''import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/library_manager.dart';
import '../../data/yt_music_sync_service.dart';
import '../../core/utils/app_toast.dart';
import 'yt_auth_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isLoggedIn = false;
  String? _accountName;
  String? _avatarUrl;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final cookie = await YTMusicSyncService.getCookie();
    final hasCookie = YTMusicSyncService.hasCookie(cookie);
    
    if (hasCookie) {
      final profile = await YTMusicSyncService.fetchUserProfile();
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _accountName = profile?['name'];
          _avatarUrl = profile?['avatarUrl'];
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _accountName = null;
          _avatarUrl = null;
        });
      }
    }
  }

  Future<void> _handleSync() async {
    if (!_isLoggedIn) {
      final success = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const YTAuthScreen()),
      );
      if (success == true) {
        await _checkLoginStatus();
        _performSync();
      }
    } else {
      _performSync();
    }
  }

  Future<void> _performSync() async {
    if (!mounted || _isSyncing) return;
    
    setState(() => _isSyncing = true);
    AppToast.show(context, 'Syncing YouTube Music...');
    
    try {
      final addedCount = await context.read<LibraryManager>().syncYTMusic();
      if (mounted) {
        AppToast.show(context, 'Synced \ new songs!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to sync library');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _handleDisconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('yt_auth_cookie');
    await _checkLoginStatus();
    if (mounted) {
      AppToast.show(context, 'Account disconnected');
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 32, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withAlpha(128),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTile(String title, dynamic icon, {VoidCallback? onTap, Color? color, Widget? trailing}) {
    return ListTile(
      onTap: onTap,
      leading: icon is IconData 
          ? Icon(icon, color: color ?? Colors.white, size: 22)
          : HugeIcon(icon: icon, color: color ?? Colors.white, size: 22),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white, fontSize: 16),
      ),
      trailing: trailing ?? HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        color: Colors.white.withAlpha(76),
        size: 18,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Profile & Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          // Profile section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withAlpha(25),
                  backgroundImage: _avatarUrl != null ? CachedNetworkImageProvider(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? const HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: Colors.white, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _accountName ?? (_isLoggedIn ? 'YouTube Music User' : 'Guest'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // YouTube Music Sync Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const HugeIcon(icon: HugeIcons.strokeRoundedYoutube, color: Color(0xFFFF2D55), size: 24),
                  title: Text(
                    _isLoggedIn ? 'YouTube Music' : 'Connect Account',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    _isLoggedIn ? 'Library is synced' : 'Sync playlists and liked songs',
                    style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13),
                  ),
                  trailing: _isSyncing 
                      ? const SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(color: Color(0xFFFF2D55), strokeWidth: 2)
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoggedIn ? Colors.white.withAlpha(25) : const Color(0xFFFF2D55),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            minimumSize: const Size(0, 32),
                          ),
                          onPressed: _handleSync,
                          child: Text(_isLoggedIn ? 'Sync Now' : 'Connect'),
                        ),
                ),
                if (_isLoggedIn) ...[
                  Divider(height: 1, color: Colors.white.withAlpha(25), indent: 56),
                  _buildTile(
                    'Disconnect Account', 
                    HugeIcons.strokeRoundedLogout01, 
                    color: Colors.redAccent, 
                    onTap: _handleDisconnect,
                    trailing: const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          
          _buildSectionHeader('PERSONALIZE'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildTile('Audio Quality', HugeIcons.strokeRoundedMusicNote01, onTap: () {}),
                Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                _buildTile('Playback Settings', HugeIcons.strokeRoundedSettings01, onTap: () {}),
                Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                _buildTile('Downloads', HugeIcons.strokeRoundedDownload04, onTap: () {}),
              ],
            ),
          ),

          _buildSectionHeader('NEED HELP?'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildTile('Tips and Tricks', HugeIcons.strokeRoundedIdea01, onTap: () {}),
                Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                _buildTile('Frequently Asked Questions', HugeIcons.strokeRoundedHelpCircle, onTap: () {}),
                Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                _buildTile('Contact Us', HugeIcons.strokeRoundedMail01, onTap: () {}),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
'''

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_code)
    
os.remove('D:/scrollMusic/lib/screens/profile/account_screen.dart')
