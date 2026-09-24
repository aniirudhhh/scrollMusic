import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/library_manager.dart';
import 'yt_auth_screen.dart';
import '../../core/utils/app_toast.dart';
import '../../data/yt_music_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoggedIn = false;
  String? _accountName;
  String? _avatarUrl;

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
        _checkLoginStatus();
        _performSync();
      }
    } else {
      _performSync();
    }
  }

  Future<void> _performSync() async {
    if (!mounted) return;
    AppToast.show(context, 'Syncing YouTube Music...');
    try {
      final addedCount = await context.read<LibraryManager>().syncYTMusic();
      if (mounted) {
        AppToast.show(context, 'Synced $addedCount new songs!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Failed to sync library');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null 
                    ? Icon(
                        _isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
                        size: 50,
                        color: _isLoggedIn ? const Color(0xFFFF2D55) : Colors.white54,
                      ) 
                    : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _accountName ?? (_isLoggedIn ? 'Connected to YouTube Music' : 'Not Connected'),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoggedIn 
                      ? 'Your Liked Music and Playlists are synced.'
                      : 'Connect your account to sync your library.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Sync Section
          _SettingsGroup(
            title: 'LIBRARY',
            children: [
              _SettingsTile(
                icon: Icons.cloud_sync_outlined,
                title: _isLoggedIn ? 'Sync Now' : 'Connect Account',
                onTap: _handleSync,
                iconColor: const Color(0xFFFF2D55),
              ),
              if (_isLoggedIn)
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Disconnect Account',
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                  onTap: () async {
                    // Clear cookie
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('yt_auth_cookie');
                    _checkLoginStatus();
                    if (mounted) {
                      AppToast.show(context, 'Account disconnected');
                    }
                  },
                ),
            ],
          ),

          const SizedBox(height: 24),

          // App Settings Section
          _SettingsGroup(
            title: 'APP SETTINGS',
            children: [
              _SettingsTile(
                icon: Icons.music_note_outlined,
                title: 'Audio Quality',
                trailing: Text('High', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                onTap: () => AppToast.show(context, 'Coming soon'),
              ),
              _SettingsTile(
                icon: Icons.color_lens_outlined,
                title: 'Appearance',
                trailing: Text('Dark', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                onTap: () => AppToast.show(context, 'Coming soon'),
              ),
              _SettingsTile(
                icon: Icons.download_outlined,
                title: 'Downloads',
                onTap: () => AppToast.show(context, 'Coming soon'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor ?? Colors.white70),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: textColor ?? Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null)
              Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
