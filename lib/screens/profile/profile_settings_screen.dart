import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'faq_screen.dart';
import '../../widgets/coming_soon_dialog.dart';
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
  String? _accountEmail;
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
        AppToast.show(context, 'Synced $addedCount new songs!');
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Disconnect Account',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to disconnect your YouTube Music account?',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2D55),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Disconnect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await YTMusicSyncService.clearAuthCookie();
      await YTMusicSyncService.clearCachedProfile();
      await _checkLoginStatus();
      if (mounted) {
        AppToast.show(context, 'Account disconnected');
      }
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

  Widget _buildTile(String title, dynamic icon, {VoidCallback? onTap, Color? color, Widget? trailing, String? subtitle}) {
    return ListTile(
      onTap: onTap,
      leading: icon is IconData 
          ? Icon(icon, color: color ?? Colors.white, size: 22)
          : HugeIcon(icon: icon, color: color ?? Colors.white, size: 22),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white, fontSize: 16),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 12)) : null,
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
      backgroundColor: Colors.black,
      body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.black87,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _accountName ?? (_isLoggedIn ? 'YouTube Music User' : 'Profile & Settings'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                      if (_accountEmail != null && _accountEmail!.isNotEmpty)
                        Text(
                          _accountEmail!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10, // Will scale up/down with FlexibleSpaceBar
                            fontWeight: FontWeight.normal,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                          ),
                        ),
                    ],
                  ),
                  titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 16),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: _avatarUrl!.replaceAll(RegExp(r'=s\d+-c'), '=s600-c'), // upscale yt avatar
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Center(
                            child: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: Colors.white54, size: 80),
                          ),
                        )
                      else
                        Container(
                          color: Colors.white.withAlpha(12),
                          child: const Center(
                            child: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, color: Colors.white54, size: 100),
                          ),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(76),
                              Colors.transparent,
                              Colors.black.withAlpha(178),
                              Colors.black,
                            ],
                            stops: const [0.0, 0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // YouTube Music Sync Section
                    Material(
                      color: Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _handleSync,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const HugeIcon(icon: HugeIcons.strokeRoundedYoutube, color: Color(0xFFFF2D55), size: 24),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isLoggedIn ? 'YouTube Music' : 'Connect Account',
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _isLoggedIn ? 'Library is synced' : 'Sync playlists and liked songs',
                                          style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _isSyncing 
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
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                            minimumSize: const Size(0, 32),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: _handleSync,
                                          child: Text(_isLoggedIn ? 'Sync Now' : 'Connect', style: const TextStyle(fontSize: 13)),
                                        ),
                                ],
                              ),
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
                    Material(
                      color: Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildTile('Audio Quality', HugeIcons.strokeRoundedMusicNote01, onTap: () => showComingSoonDialog(context)),
                          Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                          _buildTile('Playback Settings', HugeIcons.strokeRoundedSettings01, onTap: () => showComingSoonDialog(context)),
                          Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                          _buildTile('Downloads', HugeIcons.strokeRoundedDownload04, onTap: () => showComingSoonDialog(context)),
                        ],
                      ),
                    ),

                    _buildSectionHeader('DEVELOPER'),
                    Material(
                      color: Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildTile('GitHub Profile', HugeIcons.strokeRoundedGithub, onTap: () async {
                            final uri = Uri.parse('https://github.com/aniirudhhh');
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              AppToast.show(context, 'Could not launch GitHub');
                            }
                          }),
                          Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                          _buildTile('Frequently Asked Questions', HugeIcons.strokeRoundedHelpCircle, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()));
                            }),
                          Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                          _buildTile('Contact Us', HugeIcons.strokeRoundedMail01, onTap: () async {
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'iaminsanexdev@gmail.com',
                                query: 'subject=Scroll Music Support',
                              );
                              try {
                                await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
                              } catch (e) {
                                Clipboard.setData(const ClipboardData(text: 'iaminsanexdev@gmail.com'));
                                AppToast.show(context, 'Email copied to clipboard!');
                              }
                            }),
                        ],
                      ),
                    ),
                    
                    
                    const SizedBox(height: 32),
                    const Center(
                      child: Column(
                        children: [
                          Text('Loopr v1.0.0', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Made with ❤️ by aniirudhhh', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
    );
  }
}


